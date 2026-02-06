# Slide Viewer — PowerPoint Content Add-in

Embeds any live webpage directly on a PowerPoint slide. Paste a URL, and the page renders inside the slide — great for Airtable interfaces, dashboards, Google Sheets, Notion pages, or any site that allows iframe embedding.

The URL is saved in the PowerPoint file, so it persists when the file is reopened.

Works on **Mac and Windows**. No dev server or coding experience needed to install.

---

## Install (Non-Technical)

See **[INSTALL.md](INSTALL.md)** for step-by-step instructions with screenshots.

**Quick version:**

1. Download `manifest.xml` from this repo
2. Copy it to a special folder on your computer
3. Restart PowerPoint
4. Insert the add-in from **Home > Add-ins**

Or on Mac, double-click the included `install-mac.command` script to do it automatically.

---

## Usage

1. In PowerPoint, go to **Home > Add-ins** and insert **Slide Viewer**
2. It appears as a box on the slide with a URL input field
3. Paste any HTTPS URL and click **Load**
4. The webpage renders live inside the box
5. Drag the handles to resize/reposition it on the slide
6. **Save the presentation** — the URL is stored in the file
7. Click the pencil icon (bottom-right corner) to change the URL

---

## Sharing with Other Facilitators

The add-in is hosted online — other people just need the `manifest.xml` file. No coding tools required.

**What to send them:**
- The `manifest.xml` file (email it, share via Dropbox, etc.)
- A link to the [INSTALL.md](INSTALL.md) instructions

**What they need:**
- PowerPoint for Mac (16.x+) or PowerPoint for Windows (2016+)
- An internet connection (the add-in loads from GitHub Pages)

**What they DON'T need:**
- Node.js, npm, or any developer tools
- Admin permissions (for personal/non-corporate installs)
- A GitHub account

---

## Platform Support

| Platform | Status | Sideload Path |
|----------|--------|---------------|
| **Mac** | Supported | `~/Library/Containers/com.microsoft.Powerpoint/Data/Documents/wef/` |
| **Windows** | Supported | `%LOCALAPPDATA%\Microsoft\Office\16.0\Wef\` |
| **PowerPoint Online** | Supported | Insert > Get Add-ins > Upload My Add-in |

The same `manifest.xml` works on all platforms. Mac uses WebKit (Safari), Windows uses Edge WebView2 (Chromium) — both work identically for iframe embedding.

---

## Development

For developers who want to modify the add-in:

```bash
# Install dependencies
npm install

# Production build
npm run build

# Deploy to GitHub Pages
npm run deploy

# Start local dev server (https://localhost:3000)
npm run setup   # generates HTTPS certs + sideloads manifest
npm run dev
```

### npm Scripts

| Script | Description |
|--------|-------------|
| `npm run build` | Production build to `dist/` |
| `npm run deploy` | Build + push to gh-pages branch |
| `npm run dev` | Start webpack-dev-server (HTTPS, port 3000) |
| `npm run setup` | Generate certs + sideload manifest |
| `npm run sideload` | Copy manifest.xml to PowerPoint wef folder |

---

## How It Works

- **Manifest type**: `ContentApp` — embeds on the slide surface, not a side panel
- **Settings persistence**: Uses `Office.context.document.settings` to store the URL in the .pptx file
- **Hosting**: Static files served from GitHub Pages (no server needed)
- **Security**: Only HTTPS URLs accepted

## Notes

- Some websites block iframe embedding via their security headers — those won't load
- Content add-ins may not be interactive during slideshow/presentation mode
- The hosted files live at: https://rhinoboy82.github.io/powerpoint-airtable-viewer/
