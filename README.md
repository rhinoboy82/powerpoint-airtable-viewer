# Slide Viewer — PowerPoint Content Add-in

A PowerPoint Content Add-in for macOS that embeds any webpage directly on a slide via iframe. The URL is saved in the PowerPoint file so it persists when reopened.

Works with Airtable interfaces, dashboards, Google Sheets, Notion pages, or any site that allows iframe embedding.

## Prerequisites

- **PowerPoint for Mac** version 16.x or later

For development only:
- **Node.js** 18+ and npm
- **mkcert** for local HTTPS certificates (`brew install mkcert && mkcert -install`)

## Quick Start (hosted on GitHub Pages — no dev server needed)

1. Copy `manifest.xml` to the PowerPoint sideload folder:
   ```bash
   npm run sideload
   ```
   Or manually copy it to:
   ```
   ~/Library/Containers/com.microsoft.Powerpoint/Data/Documents/wef
   ```
2. Restart PowerPoint
3. Open a presentation, go to **Home > Add-ins**, and insert **Slide Viewer**

## Usage

1. Insert the add-in on a slide — it appears as a content box
2. Paste any HTTPS URL (e.g. `https://airtable.com/embed/shr...` or any webpage)
3. Click **Load** — the page renders live in the add-in
4. **Save the presentation** to persist the URL across sessions
5. Click the gear icon (top-right) to change the URL
6. Resize the add-in on the slide to fit your layout

## Manual Sideloading

1. Open Finder and press **Cmd + Shift + G**
2. Navigate to:
   ```
   ~/Library/Containers/com.microsoft.Powerpoint/Data/Documents/wef
   ```
3. If the `wef` folder doesn't exist, create it
4. Copy `manifest.xml` into that folder
5. Restart PowerPoint
6. Open a presentation and go to **Home > Add-ins** — look for "Slide Viewer"

## Development

```bash
# Install dependencies
npm install

# Generate HTTPS certs + sideload manifest
npm run setup

# Start dev server (https://localhost:3000)
npm run dev

# Production build
npm run build

# Deploy to GitHub Pages
npm run deploy
```

## npm Scripts

| Script | Description |
|--------|-------------|
| `npm run dev` | Start webpack-dev-server (HTTPS, port 3000) |
| `npm run build` | Production build to `dist/` |
| `npm run deploy` | Build + push to gh-pages branch |
| `npm run setup` | Generate certs + sideload manifest |
| `npm run sideload` | Copy manifest.xml to PowerPoint wef folder |
| `npm run validate` | Validate manifest.xml with Office tooling |

## How It Works

- **Manifest type**: `ContentApp` — embeds on the slide surface, not a side panel
- **Settings persistence**: Uses `Office.context.document.settings` to store the URL in the .pptx file
- **Hosting**: Static files served from GitHub Pages (no dev server needed for production use)
- **Rendering engine**: WebKit (Safari) on macOS
- **Security**: iframe uses `sandbox` attribute; only HTTPS URLs accepted

## Notes

- Some websites block iframe embedding via `X-Frame-Options` or CSP headers — these won't load
- Content add-ins may not be interactive during slideshow/presentation mode
- If the same add-in is inserted on multiple slides, they share the saved URL
- The hosted files live at: https://rhinoboy82.github.io/powerpoint-airtable-viewer/
