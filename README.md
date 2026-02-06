# Airtable Viewer — PowerPoint Content Add-in

A PowerPoint Content Add-in for macOS that embeds a live Airtable Interface or View directly on a slide. The Airtable URL is saved in the PowerPoint file so it persists when reopened.

## Prerequisites

- **Node.js** 18+ and npm
- **mkcert** for local HTTPS certificates:
  ```bash
  brew install mkcert
  mkcert -install
  ```
- **PowerPoint for Mac** version 16.x or later

## Quick Start

```bash
# 1. Install dependencies
npm install

# 2. Generate HTTPS certs + copy manifest to PowerPoint
npm run setup

# 3. Start the dev server
npm run dev
```

Then open PowerPoint, go to **Home > Add-ins**, and insert **Airtable Viewer**.

## Manual Sideloading (if `npm run setup` doesn't work)

1. Open Finder and press **Cmd + Shift + G**
2. Navigate to:
   ```
   ~/Library/Containers/com.microsoft.Powerpoint/Data/Documents/wef
   ```
3. If the `wef` folder doesn't exist, create it
4. Copy `manifest.xml` into that folder
5. Restart PowerPoint
6. Open a presentation and go to **Home > Add-ins** — look for "Airtable Viewer"

## Usage

1. Insert the add-in on a slide — it appears as a content box
2. Paste an Airtable embed URL (e.g. `https://airtable.com/embed/shr...`)
3. Click **Load View** — the Airtable view renders live in the add-in
4. **Save the presentation** to persist the URL across sessions
5. Click the gear icon (top-right) to change the URL

## Getting an Airtable Embed URL

1. In Airtable, open the view or interface you want to embed
2. Click **Share and sync** (or **Share** on Interfaces)
3. Click **Embed this view** or enable **Share to web**
4. Copy the URL — it starts with `https://airtable.com/embed/...`

## npm Scripts

| Script | Description |
|--------|-------------|
| `npm run dev` | Start webpack-dev-server (HTTPS, port 3000) |
| `npm run build` | Production build to `dist/` |
| `npm run setup` | Generate certs + sideload manifest |
| `npm run generate-certs` | Create localhost HTTPS certs via mkcert |
| `npm run sideload` | Copy manifest.xml to PowerPoint wef folder |
| `npm run validate` | Validate manifest.xml with Office tooling |

## How It Works

- **Manifest type**: `ContentApp` (embeds on the slide, not a side panel)
- **Settings persistence**: Uses `Office.context.document.settings` to store the URL in the .pptx file
- **Dev server**: webpack-dev-server with HTTPS on `https://localhost:3000`
- **Rendering engine**: WebKit (Safari) on macOS

## Known Limitations

- Content add-ins may not be interactive during slideshow/presentation mode
- Designed for one Airtable view per presentation (multi-instance shares settings)
- The dev server must be running for the add-in to load during development
