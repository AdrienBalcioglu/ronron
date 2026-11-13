import AppKit
import ServiceManagement

// MARK: - Drawing

enum Pose { case sleeping, sitting, excited, walking, onBreak }

let fur = NSColor(red: 0.94, green: 0.60, blue: 0.29, alpha: 1)
let furDark = NSColor(red: 0.80, green: 0.45, blue: 0.18, alpha: 1)
let cream = NSColor(red: 1.00, green: 0.91, blue: 0.78, alpha: 1)
let inkColor = NSColor(red: 0.20, green: 0.17, blue: 0.15, alpha: 1)
let pink = NSColor(red: 0.96, green: 0.56, blue: 0.60, alpha: 1)

let canvas = NSSize(width: 170, height: 170) // the cat stands on y = 0, facing right

private func oval(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ color: NSColor) {
    color.setFill(); NSBezierPath(ovalIn: NSRect(x: x, y: y, width: w, height: h)).fill()
}
private func stroke(_ points: [CGPoint], width: CGFloat, _ color: NSColor) {
    let path = NSBezierPath(); path.move(to: points[0])
    if points.count == 4 { path.curve(to: points[3], controlPoint1: points[1], controlPoint2: points[2]) } else { points.dropFirst().forEach { path.line(to: $0) } }
    path.lineWidth = width; path.lineCapStyle = .round; color.setStroke(); path.stroke()
}
private func triangle(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint, _ color: NSColor) {
    let path = NSBezierPath(); path.move(to: a); path.line(to: b); path.line(to: c); path.close(); color.setFill(); path.fill()
}

/// A head centred on (cx, cy). `open` goes from 0 (eyes closed) to 1; `wide` enlarges the eyes.
private func drawHead(cx: CGFloat, cy: CGFloat, open: CGFloat, wide: Bool) {
    triangle(CGPoint(x: cx - 23, y: cy + 8), CGPoint(x: cx - 19, y: cy + 33), CGPoint(x: cx - 3, y: cy + 20), fur)
    triangle(CGPoint(x: cx + 23, y: cy + 8), CGPoint(x: cx + 19, y: cy + 33), CGPoint(x: cx + 3, y: cy + 20), fur)
    triangle(CGPoint(x: cx - 19, y: cy + 13), CGPoint(x: cx - 17, y: cy + 27), CGPoint(x: cx - 8, y: cy + 19), pink)
    triangle(CGPoint(x: cx + 19, y: cy + 13), CGPoint(x: cx + 17, y: cy + 27), CGPoint(x: cx + 8, y: cy + 19), pink)
    oval(cx - 25, cy - 22, 50, 45, fur)
    for dx in [-7.0, 0.0, 7.0] as [CGFloat] { stroke([CGPoint(x: cx + dx, y: cy + 21), CGPoint(x: cx + dx, y: cy + 13)], width: 2.4, furDark) }
    oval(cx - 13, cy - 21, 26, 19, cream)
    if open < 0.15 {
        for sx in [-1.0, 1.0] as [CGFloat] {
            stroke([CGPoint(x: cx + sx * 15, y: cy + 1), CGPoint(x: cx + sx * 12, y: cy - 3), CGPoint(x: cx + sx * 8, y: cy - 3), CGPoint(x: cx + sx * 5, y: cy + 1)], width: 1.8, inkColor)
        }
    } else {
        let w: CGFloat = wide ? 10 : 8, h: CGFloat = (wide ? 12 : 10) * open
        for sx in [-1.0, 1.0] as [CGFloat] {
            oval(cx + sx * 10 - w / 2, cy - h / 2, w, h, inkColor)
            if open > 0.6 { oval(cx + sx * 10 - w / 2 + 1.6, cy + h / 2 - 4.6, 3, 3, .white) }
        }
    }
    triangle(CGPoint(x: cx - 3, y: cy - 8), CGPoint(x: cx + 3, y: cy - 8), CGPoint(x: cx, y: cy - 12), pink)
    stroke([CGPoint(x: cx, y: cy - 12), CGPoint(x: cx - 1, y: cy - 16), CGPoint(x: cx - 4, y: cy - 16), CGPoint(x: cx - 5, y: cy - 13)], width: 1.3, inkColor)
    stroke([CGPoint(x: cx, y: cy - 12), CGPoint(x: cx + 1, y: cy - 16), CGPoint(x: cx + 4, y: cy - 16), CGPoint(x: cx + 5, y: cy - 13)], width: 1.3, inkColor)
    for sx in [-1.0, 1.0] as [CGFloat] { for dy in [-2.0, 3.0] as [CGFloat] {
        stroke([CGPoint(x: cx + sx * 16, y: cy - 10), CGPoint(x: cx + sx * 31, y: cy - 10 + dy * 1.6)], width: 0.9, inkColor.withAlphaComponent(0.55))
    } }
}

func drawCat(pose: Pose, time t: Double, facingLeft: Bool, hearts: Double, bubble: String?) {
    guard let ctx = NSGraphicsContext.current?.cgContext else { return }
    ctx.saveGState()
    if facingLeft { ctx.translateBy(x: canvas.width, y: 0); ctx.scaleBy(x: -1, y: 1) }
    let blink: CGFloat = (t.truncatingRemainder(dividingBy: 4.2) < 0.14) ? 0.1 : 1

    switch pose {
    case .sleeping:
        let breath = CGFloat(sin(t * 1.6)) * 1.6
        oval(34, 0, 110, 50 + breath, fur)
        for dx in [0.0, 14.0, 28.0] as [CGFloat] { stroke([CGPoint(x: 92 + dx, y: 47 + breath), CGPoint(x: 96 + dx, y: 34 + breath)], width: 2.6, furDark) }
        stroke([CGPoint(x: 138, y: 16), CGPoint(x: 152, y: 9), CGPoint(x: 96, y: 5), CGPoint(x: 72, y: 10)], width: 9, furDark)
        drawHead(cx: 62, cy: 25 + breath * 0.4, open: 0, wide: false)
        let phase = t.truncatingRemainder(dividingBy: 3) / 3
        for (i, size) in [9.0, 12.0, 15.0].enumerated() {
            let p = (phase + Double(i) / 3).truncatingRemainder(dividingBy: 1)
            ("z" as NSString).draw(at: CGPoint(x: 92 + CGFloat(p) * 22, y: 58 + CGFloat(p) * 40),
                withAttributes: [.font: NSFont.systemFont(ofSize: CGFloat(size), weight: .bold), .foregroundColor: inkColor.withAlphaComponent(CGFloat(sin(p * .pi)) * 0.55)])
        }
    case .sitting, .excited, .onBreak:
        let excited = pose == .excited
        let bounce = excited ? abs(CGFloat(sin(t * 9))) * 6 : 0
        ctx.translateBy(x: 0, y: bounce)
        let swish = CGFloat(sin(t * (excited ? 9 : 2.6))) * (excited ? 16 : 9)
        stroke([CGPoint(x: 104, y: 8), CGPoint(x: 134, y: 4), CGPoint(x: 142 + swish * 0.4, y: 26), CGPoint(x: 132 + swish, y: 46)], width: 9, furDark)
        oval(56, 0, 58, 66, fur)
        oval(70, 6, 30, 40, cream)
        oval(66, -2, 15, 10, cream); oval(89, -2, 15, 10, cream)
        drawHead(cx: 85, cy: 80, open: blink, wide: excited)
    case .walking:
        let step = CGFloat(sin(t * 11))
        stroke([CGPoint(x: 44, y: 44), CGPoint(x: 30, y: 52), CGPoint(x: 22, y: 70), CGPoint(x: 28 + step * 3, y: 86)], width: 8, furDark)
        for (i, x) in ([50.0, 64.0, 96.0, 110.0] as [CGFloat]).enumerated() {
            let lift = (i % 2 == 0 ? step : -step) * 5
            NSColor(cgColor: (i % 2 == 0 ? furDark : fur).cgColor)!.setFill()
            NSBezierPath(roundedRect: NSRect(x: x + lift * 0.8, y: max(0, lift), width: 10, height: 26), xRadius: 5, yRadius: 5).fill()
        }
        oval(40, 20, 84, 40, fur)
        for dx in [0.0, 13.0, 26.0] as [CGFloat] { stroke([CGPoint(x: 62 + dx, y: 58), CGPoint(x: 64 + dx, y: 47)], width: 2.6, furDark) }
        drawHead(cx: 128, cy: 64 + step * 1.2, open: blink, wide: false)
    }
    ctx.restoreGState()

    // Hearts after a pet, and the speech bubble, are never mirrored.
    if hearts > 0 {
        for i in 0..<3 {
            let p = CGFloat(1 - hearts) + CGFloat(i) * 0.12
            ("♥" as NSString).draw(at: CGPoint(x: 62 + CGFloat(i) * 22 + sin(p * 9) * 4, y: 104 + p * 44),
                withAttributes: [.font: NSFont.systemFont(ofSize: 15), .foregroundColor: pink.withAlphaComponent(max(0, CGFloat(hearts)))])
        }
    }
    if let bubble = bubble {
        let attrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 12, weight: .semibold), .foregroundColor: inkColor]
        let size = (bubble as NSString).size(withAttributes: attrs)
        let box = NSRect(x: (canvas.width - size.width - 20) / 2, y: 132, width: size.width + 20, height: 26)
        NSColor.black.withAlphaComponent(0.12).setFill(); NSBezierPath(roundedRect: box.offsetBy(dx: 0, dy: -1.5), xRadius: 13, yRadius: 13).fill()
        NSColor.white.setFill(); NSBezierPath(roundedRect: box, xRadius: 13, yRadius: 13).fill()
        triangle(CGPoint(x: box.midX - 6, y: box.minY + 1), CGPoint(x: box.midX + 6, y: box.minY + 1), CGPoint(x: box.midX, y: box.minY - 7), .white)
        (bubble as NSString).draw(at: CGPoint(x: box.minX + 10, y: box.minY + 5.5), withAttributes: attrs)
    }
}

// MARK: - The cat's window

final class CatView: NSView {
    var pose = Pose.sleeping
    var facingLeft = false
    var bubble: String?
    var heartsUntil = Date.distantPast
    var onPet: (() -> Void)?
    var onDragEnd: (() -> Void)?
    private let born = Date()
    private var dragStart: NSPoint?
    private var dragged = false

    override func draw(_ dirtyRect: NSRect) {
        let hearts = max(0, heartsUntil.timeIntervalSinceNow / 1.4)
        drawCat(pose: pose, time: Date().timeIntervalSince(born), facingLeft: facingLeft, hearts: hearts, bubble: bubble)
    }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func mouseDown(with event: NSEvent) { dragStart = NSEvent.mouseLocation; dragged = false }
    override func mouseDragged(with event: NSEvent) {
        guard let start = dragStart, let window = window else { return }
        let now = NSEvent.mouseLocation
        if !dragged && hypot(now.x - start.x, now.y - start.y) < 4 { return }
        dragged = true
        window.setFrameOrigin(NSPoint(x: window.frame.origin.x + now.x - start.x, y: window.frame.origin.y + now.y - start.y))
        dragStart = now
    }
    override func mouseUp(with event: NSEvent) { if dragged { onDragEnd?() } else { onPet?() }; dragStart = nil }
}

// MARK: - Behaviour

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private enum Mode { case resting, walking(to: NSPoint, then: Pose), onBreak }

    private var panel: NSPanel!
    private let view = CatView(frame: NSRect(origin: .zero, size: canvas))
    private var statusItem: NSStatusItem!
    private var mode = Mode.resting
    private var home = NSPoint.zero
    private var lastKeyCount = CGEventSource.counterForEventType(.combinedSessionState, eventType: .keyDown)
    private var recentKeys: [Double] = []      // keys per half second, last 2 seconds
    private var lastTyping = Date.distantPast
    private var workSeconds = 0.0
    private var lastLogic = Date()
    private var intervalItems: [NSMenuItem] = []
    private var loginItem: NSMenuItem!
    private var statusLine: NSMenuItem!
    private let anyInput = CGEventType(rawValue: UInt32.max)!

    private var breakMinutes: Int {
        get { let m = UserDefaults.standard.integer(forKey: "breakMinutes"); return m > 0 ? m : 45 }
        set { UserDefaults.standard.set(newValue, forKey: "breakMinutes") }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let screen = (NSScreen.main ?? NSScreen.screens[0]).visibleFrame
        if let saved = UserDefaults.standard.string(forKey: "home") { home = NSPointFromString(saved) }
        let visible = NSScreen.screens.contains { $0.frame.insetBy(dx: -20, dy: -20).contains(NSPoint(x: home.x + canvas.width / 2, y: home.y + 20)) }
        if UserDefaults.standard.string(forKey: "home") == nil || !visible { home = NSPoint(x: screen.maxX - canvas.width - 120, y: screen.minY) }

        panel = NSPanel(contentRect: NSRect(origin: home, size: canvas), styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.isOpaque = false; panel.backgroundColor = .clear; panel.hasShadow = false
        panel.level = .floating; panel.hidesOnDeactivate = false; panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        panel.contentView = view
        panel.orderFrontRegardless()
        view.onPet = { [weak self] in self?.pet() }
        view.onDragEnd = { [weak self] in self?.dropped() }
        buildMenu()

        let frames = Timer(timeInterval: 1.0 / 30, repeats: true) { [weak self] _ in self?.frame() }
        RunLoop.main.add(frames, forMode: .common)
        let logic = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in self?.think() }
        RunLoop.main.add(logic, forMode: .common)
    }

    // 30 times a second: move if walking, then redraw.
    private func frame() {
        if case let .walking(target, then) = mode {
            let origin = panel.frame.origin
            let dx = target.x - origin.x, dy = target.y - origin.y, distance = hypot(dx, dy)
            let step: CGFloat = 9
            if distance <= step {
                panel.setFrameOrigin(target)
                view.pose = then; view.facingLeft = false
                if then == .onBreak { mode = .onBreak; view.bubble = "Break time?"; NSSound(named: "Purr")?.play() } else { mode = .resting }
            } else {
                view.facingLeft = dx < 0
                panel.setFrameOrigin(NSPoint(x: origin.x + dx / distance * step, y: origin.y + dy / distance * step))
            }
        }
        view.needsDisplay = true
    }

    // Twice a second: read how fast keys are pressed (a count only, never which keys) and decide what to do.
    private func think() {
        let now = Date(), elapsed = now.timeIntervalSince(lastLogic); lastLogic = now
        let count = CGEventSource.counterForEventType(.combinedSessionState, eventType: .keyDown)
        let delta = Double(count &- lastKeyCount); lastKeyCount = count
        recentKeys.append(delta); if recentKeys.count > 4 { recentKeys.removeFirst() }
        let rate = recentKeys.reduce(0, +) / 2 // keys per second over the last 2 seconds
        if delta > 0 { lastTyping = now }
        let idle = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: anyInput)

        if idle < 60 { workSeconds += elapsed }
        if idle >= 120 { // away from the keyboard for two minutes: that was a break
            workSeconds = 0
            if case .onBreak = mode { goHome() }
        }

        switch mode {
        case .resting:
            if workSeconds >= Double(breakMinutes) * 60 { startBreak(); return }
            if rate >= 7 { view.pose = .excited }
            else if rate >= 2.5 { view.pose = .sitting }
            else if view.pose != .sleeping && now.timeIntervalSince(lastTyping) > 8 { view.pose = .sleeping }
            else if view.pose == .excited { view.pose = .sitting }
        case .onBreak:
            if let spot = perch(), hypot(spot.x - panel.frame.origin.x, spot.y - panel.frame.origin.y) > 2 { panel.setFrameOrigin(spot) }
        case .walking: break
        }
    }

    /// Where to sit: on the top edge of the frontmost window of another app.
    private func perch() -> NSPoint? {
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let list = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else { return nil }
        let mine = Int(ProcessInfo.processInfo.processIdentifier)
        let primaryHeight = NSScreen.screens[0].frame.height
        for info in list {
            guard (info[kCGWindowLayer as String] as? Int) == 0, (info[kCGWindowOwnerPID as String] as? Int) != mine,
                  let b = info[kCGWindowBounds as String] as? [String: CGFloat],
                  let x = b["X"], let y = b["Y"], let w = b["Width"], let h = b["Height"], w > 300, h > 200 else { continue }
            // CoreGraphics measures from the top of the primary screen; AppKit from its bottom.
            let top = primaryHeight - y
            let centre = NSPoint(x: x + w / 2, y: top - h / 2)
            let screen = NSScreen.screens.first { $0.frame.contains(centre) } ?? NSScreen.screens[0]
            let spotX = min(max(x + w - canvas.width - 30, screen.frame.minX), screen.frame.maxX - canvas.width)
            // Sit on the edge; on a window that touches the top of the screen, sit just inside it.
            let spotY = min(top - 4, screen.visibleFrame.maxY - canvas.height)
            return NSPoint(x: spotX, y: spotY)
        }
        return nil
    }

    private func startBreak() {
        let screen = (NSScreen.main ?? NSScreen.screens[0]).visibleFrame
        let target = perch() ?? NSPoint(x: screen.midX - canvas.width / 2, y: screen.minY)
        panel.level = .statusBar
        view.pose = .walking; view.bubble = nil
        mode = .walking(to: target, then: .onBreak)
    }
    private func goHome() {
        workSeconds = 0
        panel.level = .floating
        view.bubble = nil; view.pose = .walking
        mode = .walking(to: home, then: .sleeping)
    }
    private func pet() {
        view.heartsUntil = Date().addingTimeInterval(1.4)
        NSSound(named: "Purr")?.play()
        if case .onBreak = mode { goHome() } else if case .resting = mode, view.pose == .sleeping { view.pose = .sitting; lastTyping = Date() }
    }
    private func dropped() {
        guard case .resting = mode else { return }
        home = panel.frame.origin
        UserDefaults.standard.set(NSStringFromPoint(home), forKey: "home")
    }

    // MARK: Menu

    @objc private func breakNow() { if case .resting = mode { startBreak() } }
    @objc private func pickInterval(_ item: NSMenuItem) {
        breakMinutes = item.tag
        intervalItems.forEach { $0.state = $0.tag == breakMinutes ? .on : .off }
    }
    @objc private func resetPlace() {
        let screen = (NSScreen.main ?? NSScreen.screens[0]).visibleFrame
        home = NSPoint(x: screen.maxX - canvas.width - 120, y: screen.minY)
        UserDefaults.standard.set(NSStringFromPoint(home), forKey: "home")
        if case .resting = mode { panel.setFrameOrigin(home) }
    }
    @objc private func toggleLogin() {
        do {
            if SMAppService.mainApp.status == .enabled { try SMAppService.mainApp.unregister() } else { try SMAppService.mainApp.register() }
        } catch {
            let alert = NSAlert(); alert.messageText = "Could not change the login setting"
            alert.informativeText = "Move Ronron to the Applications folder, then try again."
            NSApp.activate(ignoringOtherApps: true); alert.runModal()
        }
    }
    func menuWillOpen(_ menu: NSMenu) {
        loginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
        let left = max(0, Int((Double(breakMinutes) * 60 - workSeconds) / 60))
        if case .onBreak = mode { statusLine.title = "Waiting for you to take a break" }
        else { statusLine.title = left == 0 ? "Break coming up" : "Next break in about \(left) min of work" }
    }
    private func item(_ title: String, _ action: Selector?) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: ""); item.target = self; return item
    }
    private func buildMenu() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "cat.fill", accessibilityDescription: "Ronron")
            ?? NSImage(systemSymbolName: "pawprint.fill", accessibilityDescription: "Ronron")
        let menu = NSMenu(); menu.delegate = self
        statusLine = NSMenuItem(title: "", action: nil, keyEquivalent: ""); statusLine.isEnabled = false; menu.addItem(statusLine)
        menu.addItem(.separator())
        menu.addItem(item("Call the Cat for a Break Now", #selector(breakNow)))
        let every = NSMenuItem(title: "Break After", action: nil, keyEquivalent: ""); let sub = NSMenu()
        for m in [25, 45, 60, 90] {
            let i = item("\(m) minutes of work", #selector(pickInterval(_:))); i.tag = m; i.state = m == breakMinutes ? .on : .off
            sub.addItem(i); intervalItems.append(i)
        }
        every.submenu = sub; menu.addItem(every)
        menu.addItem(item("Put the Cat Back in Its Corner", #selector(resetPlace)))
        loginItem = item("Open at Login", #selector(toggleLogin)); menu.addItem(loginItem)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Ronron", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
    }
}

// MARK: - Entry point

// `Ronron --render file.png` draws every pose to an image, to check the artwork.
if CommandLine.arguments.count == 3, CommandLine.arguments[1] == "--render" {
    let poses: [(Pose, Double, Bool, Double, String?)] = [(.sleeping, 1.0, false, 0, nil), (.sitting, 1.0, false, 0, nil), (.excited, 0.17, false, 0.7, nil),
                                                          (.walking, 0.14, false, 0, nil), (.walking, 0.43, true, 0, nil), (.onBreak, 1.0, false, 0, "Break time?")]
    let image = NSImage(size: NSSize(width: canvas.width * CGFloat(poses.count), height: canvas.height + 20))
    image.lockFocus()
    NSColor(white: 0.90, alpha: 1).setFill(); NSRect(origin: .zero, size: image.size).fill()
    for (i, p) in poses.enumerated() {
        NSGraphicsContext.current?.cgContext.saveGState()
        NSGraphicsContext.current?.cgContext.translateBy(x: CGFloat(i) * canvas.width, y: 10)
        drawCat(pose: p.0, time: p.1, facingLeft: p.2, hearts: p.3, bubble: p.4)
        NSGraphicsContext.current?.cgContext.restoreGState()
    }
    image.unlockFocus()
    if let tiff = image.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff), let png = rep.representation(using: .png, properties: [:]) {
        try? png.write(to: URL(fileURLWithPath: CommandLine.arguments[2]))
    }
    exit(0)
}

// `--icon file.png` draws the 1024-pixel app icon.
if CommandLine.arguments.count == 3, CommandLine.arguments[1] == "--icon" {
    let image = NSImage(size: NSSize(width: 1024, height: 1024))
    image.lockFocus()
    let tile = NSBezierPath(roundedRect: NSRect(x: 100, y: 100, width: 824, height: 824), xRadius: 185, yRadius: 185)
    NSGradient(starting: NSColor(red: 0.62, green: 0.80, blue: 0.86, alpha: 1), ending: NSColor(red: 0.86, green: 0.94, blue: 0.95, alpha: 1))?.draw(in: tile, angle: 90)
    if let ctx = NSGraphicsContext.current?.cgContext {
        ctx.translateBy(x: 512 - canvas.width * 2.5, y: 200); ctx.scaleBy(x: 5, y: 5)
        drawCat(pose: .sitting, time: 1.0, facingLeft: false, hearts: 0, bubble: nil)
    }
    image.unlockFocus()
    if let tiff = image.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff), let png = rep.representation(using: .png, properties: [:]) {
        try? png.write(to: URL(fileURLWithPath: CommandLine.arguments[2]))
    }
    exit(0)
}

let application = NSApplication.shared
let delegate = AppDelegate()
application.delegate = delegate
application.setActivationPolicy(.accessory)
application.run()
