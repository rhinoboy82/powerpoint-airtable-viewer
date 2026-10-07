# Live Web Slide Viewer: readiness for Microsoft AppSource

Status on 2026-09-16. Items are ordered so each unblocks the next; the
account step gates everything after it.

## 1. Partner Center account (blocking)

Office add-ins are submitted through Partner Center's Microsoft 365 and
Copilot program (the former Office Store program). It rides on the same
Partner Center account as the AI Cloud Partner Program enrollment that
Microsoft's automated trust filter blocked on 2026-09-15 (reference
715-123160). Until that block is lifted there is no place to submit. The
escalation routes are in the RoomSum day log; the Partner Center
enrollment must succeed before any of the following can be uploaded.

## 2. The manifest (done)

- Type: content add-in for PowerPoint (`ContentApp`, host `Presentation`).
- Id `94f1f1ac-8278-4a33-8989-5739d7e5452a` stays: it is the add-in's identity
  for every existing install.
- Version `1.1.1.0`, provider `10/10ths Development`, display name
  `Live Web Slide Viewer`.
- Validated with `office-addin-manifest` (`npm run validate`).

## 3. Hosting (decide)

Today the add-in's code and icons load from GitHub Pages
(`rhinoboy82.github.io/powerpoint-airtable-viewer`), and the support page
is on 1010thsdev.com. AppSource accepts any HTTPS host, but the listing's
SourceLocation is permanent for every install that follows, so choose the
long-term home before submitting. Moving to `https://1010thsdev.com/liveweb/`
(or a dedicated domain) means updating `SourceLocation`, `IconUrl`,
`HighResolutionIconUrl`, and the `deploy` script, then a new manifest
version.

## 4. Certification requirements to meet

Microsoft validates against the commercial marketplace policies (the 1100
series for Office add-ins). The ones that bite a content add-in like this:

- Works on every platform the manifest claims: PowerPoint for Windows, Mac,
  and the web. A page that refuses to be framed (X-Frame-Options,
  Content-Security-Policy frame-ancestors) shows nothing inside the viewer;
  the add-in must handle that with a visible message rather than a blank
  frame, and the listing must say which pages can be shown.
- No blank or error state on first insert: a clear prompt to enter a URL.
- Privacy policy and terms URLs (public, HTTPS) in the listing. The viewer
  collects nothing itself; the policy should say so and note that the
  framed page's own policy applies.
- Support URL that reaches a human: `https://1010thsdev.com/1010dev/slide-viewer/`
  and info@1010development.com.
- Accessibility basics: keyboard reachable controls, labelled inputs,
  sufficient contrast in the settings panel.
- Icons: 32x32 and 64x64 PNG on HTTPS (present). Listing needs a 300x300
  logo and at least one 1366x768 screenshot; keep sources in `assets/`.
- The `Permissions` value must be the least needed. `ReadWriteDocument` is
  right if the viewer writes the chosen URL into slide settings; if it only
  reads, `ReadDocument`.

## 5. Listing copy to prepare

- Summary (100 chars), description (up to 3000), category (Productivity),
  supported languages (en-US), pricing (free, or the paid model decided
  later; paid Office add-ins use Microsoft's SaaS or a license check in the
  add-in, not AppSource billing).
- Test notes for the validator: a public URL that frames cleanly to try,
  and one that does not, with the expected message.

## 6. Installers outside the store (done)

- Mac: `install-live-web-slide-viewer-mac.zip`, the signed and notarized
  `Install Live Web Slide Viewer.app` with `manifest.xml` inside. It copies the
  manifest into PowerPoint's add-in folder as `live-web-slide-viewer.xml` and
  removes earlier copies of the same add-in first. Rebuild with
  `sign-live-web-app.sh`.
- Windows: `install-live-web-slide-viewer-win.zip`, holding
  `install-windows.bat`, `manifest.xml` and a README. The script registers
  the manifest with PowerPoint (registry Developer key) and removes earlier
  copies. No administrator rights. Rebuild with `build-win-zip.sh`.
- Both are hosted on 1010thsdev.com, not roomsum.com.
