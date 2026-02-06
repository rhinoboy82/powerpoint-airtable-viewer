# How to Install Slide Viewer

Slide Viewer is a PowerPoint add-in that lets you embed live webpages directly on a slide. This guide walks you through installing it — no coding required.

---

## What You Need

- **PowerPoint** for Mac (version 16 or later) or Windows (2016 or later)
- **The `manifest.xml` file** (you should have received this, or download it from the GitHub repo)
- **An internet connection** (the add-in loads its interface from the web)

---

## Option A: One-Click Install (Mac Only)

If you received the `install-mac.command` file:

1. Double-click **`install-mac.command`**
2. If macOS asks for permission, click **Open**
3. A Terminal window will briefly appear and then close
4. **Quit PowerPoint completely** (Cmd + Q) and reopen it
5. Done! Go to the **"Using the Add-in"** section below

---

## Option B: Manual Install — Mac

### Step 1: Open the hidden folder

1. Open **Finder**
2. From the menu bar, click **Go** > **Go to Folder...** (or press **Cmd + Shift + G**)
3. Paste this path and press Enter:
   ```
   ~/Library/Containers/com.microsoft.Powerpoint/Data/Documents/wef
   ```

> **If you see an error** saying the folder can't be found, you need to create it:
> 1. Go to this path instead: `~/Library/Containers/com.microsoft.Powerpoint/Data/Documents/`
> 2. Right-click in the folder and choose **New Folder**
> 3. Name it exactly: **wef**
> 4. Open the new `wef` folder

### Step 2: Copy the manifest file

1. Drag and drop the **`manifest.xml`** file into the `wef` folder
2. If asked to replace an existing file, click **Replace**

### Step 3: Restart PowerPoint

1. **Quit PowerPoint completely** (Cmd + Q — don't just close the window)
2. Reopen PowerPoint

### Step 4: Verify it works

1. Open any presentation
2. Go to **Home** in the ribbon
3. Click **Add-ins**
4. You should see **Slide Viewer** — click it to insert

---

## Option C: Manual Install — Windows

### Step 1: Open the add-ins folder

1. Press **Windows + R** to open the Run dialog
2. Paste this path and press Enter:
   ```
   %LOCALAPPDATA%\Microsoft\Office\16.0\Wef
   ```

> **If the folder doesn't exist:**
> 1. Navigate to `%LOCALAPPDATA%\Microsoft\Office\16.0\`
> 2. Right-click > **New** > **Folder**
> 3. Name it exactly: **Wef**
> 4. Open the new `Wef` folder

### Step 2: Copy the manifest file

1. Copy the **`manifest.xml`** file into the `Wef` folder
2. If asked to replace, click **Yes**

### Step 3: Restart PowerPoint

1. Close PowerPoint completely
2. Reopen PowerPoint

### Step 4: Verify it works

1. Open any presentation
2. Go to **Home** (or **Insert**) in the ribbon
3. Click **Add-ins** (or **Get Add-ins** > **My Add-ins**)
4. You should see **Slide Viewer** — click it to insert

---

## Option D: PowerPoint Online (Web Browser)

1. Open PowerPoint at [office.com](https://www.office.com)
2. Open a presentation
3. Click **Insert** > **Get Add-ins** (or **Office Add-ins**)
4. Click **Upload My Add-in** (in the top-right corner)
5. Browse to your `manifest.xml` file and click **Upload**
6. The add-in will appear on the slide

---

## Using the Add-in

Once installed, here's how to use it:

1. **Insert it**: Go to Home > Add-ins > Slide Viewer. A box appears on the slide.
2. **Paste a URL**: Type or paste any HTTPS web address into the input field.
3. **Click Load**: The webpage appears live inside the box.
4. **Resize it**: Click the box and drag the corner handles to make it bigger or smaller. Drag the box itself to reposition it.
5. **Save**: Save the PowerPoint file as usual. The URL is stored in the file and will reload automatically next time.
6. **Change the URL**: Click the small pencil icon in the bottom-right corner of the box.

### Tips

- The URL must start with `https://` — plain `http://` URLs won't work
- Some websites (like Google, Facebook) block being embedded — if a page shows blank, that site doesn't allow it
- Airtable, Notion (published pages), Google Sheets (published), and most dashboard tools work well
- The embedded page is live and interactive while editing the slide
- During slideshow/presentation mode, the content may appear as a static image

---

## Uninstalling

**Mac**: Open Finder, press Cmd + Shift + G, go to `~/Library/Containers/com.microsoft.Powerpoint/Data/Documents/wef/`, and delete `manifest.xml`. Restart PowerPoint.

**Windows**: Navigate to `%LOCALAPPDATA%\Microsoft\Office\16.0\Wef\`, delete `manifest.xml`, and restart PowerPoint.

---

## Troubleshooting

**"I don't see the add-in in the Add-ins menu"**
- Make sure you quit PowerPoint completely (not just closed the window) and reopened it
- Double-check the `manifest.xml` file is in the correct folder
- On Mac, make sure the folder is named exactly `wef` (lowercase)

**"The add-in shows but the webpage is blank"**
- The website may block iframe embedding — try a different URL to confirm the add-in works
- Make sure you have an internet connection
- Try `https://en.wikipedia.org` as a test URL

**"I see an error when pasting the URL"**
- Make sure the URL starts with `https://` (not `http://`)
- Make sure there are no extra spaces before or after the URL

**"The add-in is too big/small on the slide"**
- Click the add-in box, then drag the corner handles to resize it
- The default size is designed for 16:9 slides
