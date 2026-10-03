// Install RoomSum Add-ins and Install Live Web Slide Viewer, the Mac
// installers (2026-10-02, the Live Viewer build 2026-10-03). One app, built
// twice by build-mac-app.sh; the Info.plist key InstallerProduct picks which
// (see Product below).
//
// Gets add-in manifests into the folder PowerPoint for Mac reads at launch,
// Microsoft's sideload location inside PowerPoint's own container:
// ~/Library/Containers/com.microsoft.Powerpoint/Data/Documents/wef
//
// Why the person drags them in. macOS 27 protects every app's container, and
// nothing automatic may create files in PowerPoint's. Tested on Terry's Mac,
// 2026-10-02, each refused with "kTCCServiceSystemPolicyAppDataDetailed does
// not allow prompting; recording denied", so there is no permission to grant:
//   - Apple's Installer running the old package's script (the package could
//     still replace files it had written before, so it seemed to work until
//     the folder was empty);
//   - this app writing directly, signed with our Developer ID;
//   - an Open window, sandboxed or not, which macOS would not start there;
//   - Finder asked by Apple Event: it checks on behalf of the app that asked
//     ("TCCAccessRequestIndirect"), is refused, then wants an administrator
//     password and skips files;
//   - the shared Office group container, protected by the same rule.
// What macOS does allow is the person's own drag in Finder, with no password.
// So this app downloads the manifests, opens PowerPoint's folder in Finder,
// and offers one tile to drag into it. Checking that a known file exists is
// allowed, listing the folder is not, so it can confirm the drop afterwards.
//
import AppKit

/// What this copy installs.
///   roomsum     RoomSum's add-ins. The list comes from roomsum.com, as it did
///               for the package, so adding an add-in never needs a new build.
///   liveviewer  The Live Web Slide Viewer. Its one manifest travels inside the
///               app (Resources/manifests), as it did in the Automator
///               installer this replaces, and is installed under the same file
///               name, so installing again replaces it.
struct Product {
  let name: String          // the app's and the window's title
  let things: String        // "the RoomSum add-ins", as a sentence goes on
  let label: String         // the tile's caption
  let single: Bool          // one add-in or several, for the wording
  let supportFolder: String // under ~/Library/Application Support
  let listURL: URL?         // nil: the manifests inside the app
  let baseURL: URL?
  let filePrefix: String    // installed name = prefix + listed name
}

let product: Product = {
  switch Bundle.main.object(forInfoDictionaryKey: "InstallerProduct") as? String {
  case "liveviewer":
    return Product(
      name: "Install Live Web Slide Viewer", things: "the Live Web Slide Viewer",
      label: "Live Web Slide Viewer", single: true, supportFolder: "Live Web Slide Viewer",
      listURL: nil, baseURL: nil, filePrefix: "")
  default:
    return Product(
      name: "Install RoomSum Add-ins", things: "the RoomSum add-ins",
      label: "RoomSum add-ins", single: false, supportFolder: "RoomSum",
      listURL: URL(string: "https://roomsum.com/ppt/manifests.txt")!,
      baseURL: URL(string: "https://roomsum.com/ppt/")!, filePrefix: "roomsum-")
  }
}()

func sentence(_ s: String) -> String { s.prefix(1).uppercased() + s.dropFirst() }

let powerPointID = "com.microsoft.Powerpoint"
let fm = FileManager.default

let powerPointDocuments = fm.homeDirectoryForCurrentUser
  .appendingPathComponent("Library/Containers/\(powerPointID)/Data/Documents", isDirectory: true)
let wefFolder = powerPointDocuments.appendingPathComponent("wef", isDirectory: true)
/// The downloads wait here, in a folder named wef, so that when PowerPoint has
/// no wef yet the whole folder can be dropped into its Documents.
let staging = fm.homeDirectoryForCurrentUser
  .appendingPathComponent("Library/Application Support/\(product.supportFolder)/Installer/wef", isDirectory: true)

/// One GET, waited for: downloads run off the main thread.
func fetch(_ url: URL) throws -> Data {
  var result: Result<Data, Error> = .failure(URLError(.unknown))
  let done = DispatchSemaphore(value: 0)
  var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30)
  request.setValue("RoomSum-Mac-Installer", forHTTPHeaderField: "User-Agent")
  URLSession.shared.dataTask(with: request) { data, response, error in
    if let error = error {
      result = .failure(error)
    } else if let http = response as? HTTPURLResponse, http.statusCode != 200 {
      result = .failure(URLError(.badServerResponse))
    } else {
      result = .success(data ?? Data())
    }
    done.signal()
  }.resume()
  done.wait()
  return try result.get()
}

/// Every manifest, freshly written into the staging folder. Returns the file
/// names, or nil when roomsum.com could not be reached (or, for a product
/// whose manifests are inside the app, when they are missing).
func prepare() -> [String]? {
  do {
    var files: [(String, Data)] = []
    if let listURL = product.listURL, let baseURL = product.baseURL {
      let list = String(decoding: try fetch(listURL), as: UTF8.self)
      let names = list
        .split(whereSeparator: \.isNewline)
        .map { $0.trimmingCharacters(in: .whitespaces) }
        // Plain file names only, as the list has always held.
        .filter { $0.hasSuffix(".xml") && !$0.contains("/") && !$0.contains("..") && !$0.hasPrefix("-") }
      if names.isEmpty { return nil }
      for name in names { files.append((product.filePrefix + name, try fetch(baseURL.appendingPathComponent(name)))) }
    } else {
      // Read and written, not copied: a copy keeps the build's file date, and
      // the drop is confirmed by a date no older than this run.
      guard let folder = Bundle.main.resourceURL?.appendingPathComponent("manifests", isDirectory: true)
      else { return nil }
      let names = try fm.contentsOfDirectory(atPath: folder.path).filter { $0.hasSuffix(".xml") }.sorted()
      if names.isEmpty { return nil }
      for name in names { files.append((product.filePrefix + name, try Data(contentsOf: folder.appendingPathComponent(name)))) }
    }
    try? fm.removeItem(at: staging)
    try fm.createDirectory(at: staging, withIntermediateDirectories: true)
    for (file, data) in files { try data.write(to: staging.appendingPathComponent(file)) }
    return files.map { $0.0 }
  } catch {
    return nil
  }
}

/// The one thing to drag: the downloaded files, or the folder holding them.
final class Tile: NSView, NSDraggingSource {
  var urls: [URL] = []
  var caption = ""
  var onDrop: (() -> Void)?

  override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
  override func resetCursorRects() { addCursorRect(bounds, cursor: .openHand) }

  override func draw(_ dirtyRect: NSRect) {
    let box = bounds.insetBy(dx: 1, dy: 1)
    NSColor.controlAccentColor.withAlphaComponent(0.12).setFill()
    let path = NSBezierPath(roundedRect: box, xRadius: 14, yRadius: 14)
    path.fill()
    NSColor.controlAccentColor.withAlphaComponent(0.6).setStroke()
    path.setLineDash([6, 4], count: 2, phase: 0)
    path.lineWidth = 1.5
    path.stroke()
    let icon = NSApp.applicationIconImage ?? NSImage()
    let side: CGFloat = 72
    icon.draw(in: NSRect(x: bounds.midX - side / 2, y: bounds.midY - side / 2 + 10, width: side, height: side))
    let text = NSAttributedString(string: caption, attributes: [
      .font: NSFont.systemFont(ofSize: 13, weight: .semibold), .foregroundColor: NSColor.labelColor,
    ])
    let w = text.size().width
    text.draw(at: NSPoint(x: bounds.midX - w / 2, y: bounds.midY - side / 2 - 12))
  }

  override func mouseDown(with event: NSEvent) {
    guard !urls.isEmpty else { return }
    let icon = NSApp.applicationIconImage ?? NSImage()
    let side: CGFloat = 64
    let start = convert(event.locationInWindow, from: nil)
    let items = urls.enumerated().map { index, url -> NSDraggingItem in
      let item = NSDraggingItem(pasteboardWriter: url as NSURL)
      let offset = CGFloat(index) * 3
      item.setDraggingFrame(
        NSRect(x: start.x - side / 2 + offset, y: start.y - side / 2 - offset, width: side, height: side),
        contents: icon)
      return item
    }
    beginDraggingSession(with: items, event: event, source: self)
  }

  func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
    context == .outsideApplication ? .copy : []
  }

  func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
    if operation != [] { onDrop?() }
  }
}

final class Installer: NSObject, NSApplicationDelegate, NSWindowDelegate {
  var window: NSPanel!
  let heading = NSTextField(labelWithString: "Getting \(product.things)…")
  let detail = NSTextField(wrappingLabelWithString: product.listURL == nil ? "" : "From roomsum.com, a few seconds.")
  let note = NSTextField(wrappingLabelWithString: "")
  let tile = Tile()
  let spinner = NSProgressIndicator()
  let primary = NSButton(title: "Cancel", target: nil, action: nil)
  let secondary = NSButton(title: "Open the Folder Again", target: nil, action: nil)
  var names: [String] = []
  var stagedAt = Date()
  var hadWef = false

  func applicationDidFinishLaunching(_ notification: Notification) {
    NSApp.activate(ignoringOtherApps: true)
    if NSWorkspace.shared.urlForApplication(withBundleIdentifier: powerPointID) == nil {
      stop("PowerPoint isn't on this Mac", "Install Microsoft PowerPoint, open it once, then open this installer again.")
      return
    }
    // PowerPoint makes its own container the first time it opens.
    if !fm.fileExists(atPath: powerPointDocuments.path) {
      stop("Open PowerPoint once first", "PowerPoint makes its own folder the first time it opens. Open PowerPoint, quit it, then open this installer again.")
      return
    }
    buildWindow()
    DispatchQueue.global(qos: .userInitiated).async {
      let names = prepare()
      DispatchQueue.main.async {
        guard let names = names else {
          if product.listURL == nil {
            self.stop("This installer is incomplete", "Download it again, then open the new copy.")
          } else {
            self.stop("roomsum.com could not be reached", "Check this Mac's internet connection and open the installer again.")
          }
          return
        }
        self.ready(names)
      }
    }
  }

  func buildWindow() {
    window = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 380, height: 430),
                     styleMask: [.titled, .closable], backing: .buffered, defer: false)
    window.title = product.name
    window.level = .floating
    window.hidesOnDeactivate = false
    window.isReleasedWhenClosed = false
    window.delegate = self

    heading.font = .systemFont(ofSize: 15, weight: .semibold)
    detail.font = .systemFont(ofSize: 13)
    note.font = .systemFont(ofSize: 11)
    note.textColor = .secondaryLabelColor
    spinner.style = .spinning
    spinner.startAnimation(nil)
    tile.isHidden = true
    secondary.isHidden = true
    primary.bezelStyle = .rounded
    secondary.bezelStyle = .rounded
    primary.target = self
    primary.action = #selector(primaryPressed)
    secondary.target = self
    secondary.action = #selector(openTarget)
    tile.onDrop = { [weak self] in self?.confirm(attempt: 0) }

    let buttons = NSStackView(views: [secondary, primary])
    buttons.orientation = .horizontal
    buttons.spacing = 10
    let stack = NSStackView(views: [heading, detail, spinner, tile, note, buttons])
    stack.orientation = .vertical
    stack.alignment = .leading
    stack.spacing = 12
    stack.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
    stack.translatesAutoresizingMaskIntoConstraints = false
    let content = NSView()
    window.contentView = content
    content.addSubview(stack)
    NSLayoutConstraint.activate([
      stack.leadingAnchor.constraint(equalTo: content.leadingAnchor),
      stack.trailingAnchor.constraint(equalTo: content.trailingAnchor),
      stack.topAnchor.constraint(equalTo: content.topAnchor),
      stack.bottomAnchor.constraint(lessThanOrEqualTo: content.bottomAnchor),
      tile.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -40),
      tile.heightAnchor.constraint(equalToConstant: 150),
      detail.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -40),
      note.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -40),
      heading.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -40),
    ])
    // Top right, clear of the Finder window that opens in the middle.
    if let screen = NSScreen.main?.visibleFrame {
      window.setFrameTopLeftPoint(NSPoint(x: screen.maxX - 400, y: screen.maxY - 20))
    }
    window.makeKeyAndOrderFront(nil)
  }

  func ready(_ names: [String]) {
    self.names = names
    stagedAt = Date()
    hadWef = fm.fileExists(atPath: wefFolder.path)
    spinner.stopAnimation(nil)
    spinner.isHidden = true
    tile.isHidden = false
    secondary.isHidden = false
    heading.stringValue = product.single
      ? "Drag the add-in into PowerPoint's folder"
      : "Drag the add-ins into PowerPoint's folder"
    if hadWef {
      tile.urls = names.map { staging.appendingPathComponent($0) }
      tile.caption = product.single ? product.label : "\(names.count) \(product.label)"
      detail.stringValue = "A Finder window named “wef” has opened: it is PowerPoint's add-in folder. Drag the tile below into that window. If Finder asks about items that already exist, choose Replace."
    } else {
      tile.urls = [staging]
      tile.caption = product.single ? "wef folder with the add-in" : "wef folder with \(names.count) add-ins"
      detail.stringValue = "A Finder window named “Documents” has opened: it is PowerPoint's own folder. Drag the tile below into that window. It is a folder named wef, where PowerPoint looks for add-ins."
    }
    note.stringValue = "macOS lets only you put files in PowerPoint's folder, so this takes one drag rather than happening on its own."
    tile.needsDisplay = true
    window.invalidateCursorRects(for: tile)
    openTarget()
  }

  @objc func openTarget() {
    NSWorkspace.shared.open(hadWef ? wefFolder : powerPointDocuments)
    // Finder comes forward; this window stays on top so the tile is in reach.
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { self.window.orderFrontRegardless() }
  }

  /// Did the drop land in PowerPoint's folder? Finder copies in the background,
  /// so look a few times. Known paths may be checked; the folder may not be listed.
  func confirm(attempt: Int) {
    let arrived = names.filter { name in
      let path = wefFolder.appendingPathComponent(name).path
      guard let attrs = try? fm.attributesOfItem(atPath: path),
            let modified = attrs[.modificationDate] as? Date else { return false }
      // Finder keeps the download's own date, so a file from an earlier
      // install that was not replaced still reads as old.
      return modified >= stagedAt.addingTimeInterval(-60)
    }
    if arrived.count == names.count {
      done()
      return
    }
    if attempt < 10 {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self.confirm(attempt: attempt + 1) }
      return
    }
    heading.stringValue = arrived.isEmpty
      ? (product.single ? "The add-in isn't in PowerPoint's folder yet" : "The add-ins aren't in PowerPoint's folder yet")
      : "Only \(arrived.count) of \(names.count) add-ins arrived"
    detail.stringValue = hadWef
      ? "Drag the tile into the Finder window named “wef”, and choose Replace if Finder asks. Lost the window? Click Open the Folder Again."
      : "Drag the tile into the Finder window named “Documents”. Lost the window? Click Open the Folder Again."
  }

  func done() {
    try? fm.removeItem(at: staging)
    let open = !NSRunningApplication.runningApplications(withBundleIdentifier: powerPointID).isEmpty
    tile.isHidden = true
    secondary.isHidden = true
    heading.stringValue = "\(sentence(product.things)) \(product.single ? "is" : "are") installed"
    detail.stringValue = (open
      ? "PowerPoint is open: quit it completely (PowerPoint › Quit PowerPoint) and open it again."
      : "Open PowerPoint.")
      + (product.single
        ? " It is under Insert › My Add-ins."
        : " The \(names.count) add-ins are under Insert › My Add-ins. Open this installer again any time to update them.")
    note.stringValue = ""
    primary.title = "Done"
    window.orderFrontRegardless()
  }

  func stop(_ title: String, _ text: String) {
    let alert = NSAlert()
    alert.alertStyle = .warning
    alert.messageText = title
    alert.informativeText = text
    alert.addButton(withTitle: "OK")
    alert.runModal()
    NSApp.terminate(nil)
  }

  @objc func primaryPressed() { NSApp.terminate(nil) }
  func windowWillClose(_ notification: Notification) { NSApp.terminate(nil) }
}

let app = NSApplication.shared
let installer = Installer()
app.delegate = installer
app.setActivationPolicy(.regular)
app.run()
