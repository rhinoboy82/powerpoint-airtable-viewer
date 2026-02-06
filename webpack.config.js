const path = require("path");
const HtmlWebpackPlugin = require("html-webpack-plugin");
const CopyWebpackPlugin = require("copy-webpack-plugin");
const fs = require("fs");

module.exports = (env, options) => {
  const dev = options.mode === "development";

  const certsDir = path.resolve(__dirname, "certs");
  const keyPath = path.join(certsDir, "localhost-key.pem");
  const certPath = path.join(certsDir, "localhost.pem");

  const httpsOptions =
    dev && fs.existsSync(keyPath) && fs.existsSync(certPath)
      ? { key: fs.readFileSync(keyPath), cert: fs.readFileSync(certPath) }
      : undefined;

  return {
    entry: { content: "./src/content.ts" },
    output: {
      path: path.resolve(__dirname, "dist"),
      filename: "[name].js",
      clean: true,
    },
    resolve: { extensions: [".ts", ".js"] },
    module: {
      rules: [
        { test: /\.ts$/, use: "ts-loader", exclude: /node_modules/ },
        { test: /\.css$/, use: ["style-loader", "css-loader"] },
      ],
    },
    plugins: [
      new HtmlWebpackPlugin({
        template: "./src/content.html",
        filename: "content.html",
        chunks: ["content"],
      }),
      new CopyWebpackPlugin({
        patterns: [
          { from: "assets", to: "assets" },
          { from: "manifest.xml", to: "manifest.xml" },
        ],
      }),
    ],
    devServer: {
      port: 3000,
      server: httpsOptions
        ? { type: "https", options: httpsOptions }
        : { type: "https" },
      headers: { "Access-Control-Allow-Origin": "*" },
      hot: true,
      static: { directory: path.join(__dirname, "dist") },
    },
    devtool: dev ? "source-map" : undefined,
  };
};
