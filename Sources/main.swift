import AppKit
import CryptoKit
import ServiceManagement

// MARK: - Launch options

// `--profile name` runs a second, independent cat on the same Mac (used to test the friend link).
// `--simulate resting|working|intense` forces the activity level instead of reading the keyboard.
func option(_ name: String) -> String? {
    let args = CommandLine.arguments
    guard let i = args.firstIndex(of: name), i + 1 < args.count else { return nil }
    return args[i + 1]
}
let store: UserDefaults = option("--profile").flatMap { UserDefaults(suiteName: "com.adrienbalcioglu.ronron." + $0) } ?? .standard

// MARK: - Coats

struct Coat {
    let name: String
    let fur, dark, belly, ear, eye, whisker: NSColor
    var stripes = false
    var mask: NSColor? = nil
    var patches = false
}
private func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> NSColor { NSColor(red: r, green: g, blue: b, alpha: 1) }
let inkColor = rgb(0.20, 0.17, 0.15)
let pink = rgb(0.96, 0.56, 0.60)
let ginger = rgb(0.94, 0.60, 0.29), gingerDark = rgb(0.80, 0.45, 0.18), soot = rgb(0.25, 0.22, 0.22)
let softInk = inkColor.withAlphaComponent(0.55)

let coats: [Coat] = [
    Coat(name: "Ginger", fur: ginger, dark: gingerDark, belly: rgb(1.00, 0.91, 0.78), ear: ginger, eye: inkColor, whisker: softInk, stripes: true),
    Coat(name: "Black", fur: rgb(0.23, 0.22, 0.25), dark: rgb(0.14, 0.13, 0.16), belly: rgb(0.34, 0.33, 0.37), ear: rgb(0.23, 0.22, 0.25), eye: rgb(0.98, 0.83, 0.26), whisker: NSColor.white.withAlphaComponent(0.7)),
    Coat(name: "White", fur: rgb(0.96, 0.95, 0.93), dark: rgb(0.82, 0.80, 0.78), belly: .white, ear: rgb(0.96, 0.95, 0.93), eye: inkColor, whisker: softInk),
    Coat(name: "Grey", fur: rgb(0.63, 0.66, 0.71), dark: rgb(0.46, 0.49, 0.55), belly: rgb(0.90, 0.91, 0.93), ear: rgb(0.63, 0.66, 0.71), eye: inkColor, whisker: softInk, stripes: true),
    Coat(name: "Calico", fur: rgb(0.98, 0.95, 0.90), dark: soot, belly: .white, ear: rgb(0.98, 0.95, 0.90), eye: inkColor, whisker: softInk, patches: true),
    Coat(name: "Siamese", fur: rgb(0.94, 0.88, 0.77), dark: rgb(0.36, 0.26, 0.21), belly: rgb(0.98, 0.94, 0.86), ear: rgb(0.36, 0.26, 0.21), eye: rgb(0.30, 0.58, 0.88), whisker: softInk, mask: rgb(0.36, 0.26, 0.21)),
]

// MARK: - Drawing

enum Pose { case sleeping, sitting, excited, walking, onBreak }
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
private func drawHead(_ coat: Coat, cx: CGFloat, cy: CGFloat, open: CGFloat, wide: Bool) {
    let leftEar = coat.patches ? ginger : coat.ear, rightEar = coat.patches ? soot : coat.ear
    triangle(CGPoint(x: cx - 23, y: cy + 8), CGPoint(x: cx - 19, y: cy + 33), CGPoint(x: cx - 3, y: cy + 20), leftEar)
    triangle(CGPoint(x: cx + 23, y: cy + 8), CGPoint(x: cx + 19, y: cy + 33), CGPoint(x: cx + 3, y: cy + 20), rightEar)
    triangle(CGPoint(x: cx - 19, y: cy + 13), CGPoint(x: cx - 17, y: cy + 27), CGPoint(x: cx - 8, y: cy + 19), pink)
    triangle(CGPoint(x: cx + 19, y: cy + 13), CGPoint(x: cx + 17, y: cy + 27), CGPoint(x: cx + 8, y: cy + 19), pink)
    oval(cx - 25, cy - 22, 50, 45, coat.fur)
    if coat.patches { oval(cx - 23, cy + 2, 19, 17, ginger); oval(cx + 7, cy + 4, 15, 14, soot) }
    if coat.stripes { for dx in [-7.0, 0.0, 7.0] as [CGFloat] { stroke([CGPoint(x: cx + dx, y: cy + 21), CGPoint(x: cx + dx, y: cy + 13)], width: 2.4, coat.dark) } }
    if let mask = coat.mask { oval(cx - 16, cy - 21, 32, 30, mask) } else { oval(cx - 13, cy - 21, 26, 19, coat.belly) }
    let line = coat.mask != nil ? coat.belly : inkColor
    if open < 0.15 {
        for sx in [-1.0, 1.0] as [CGFloat] {
            stroke([CGPoint(x: cx + sx * 15, y: cy + 1), CGPoint(x: cx + sx * 12, y: cy - 3), CGPoint(x: cx + sx * 8, y: cy - 3), CGPoint(x: cx + sx * 5, y: cy + 1)], width: 1.8, coat.eye == inkColor ? line : coat.eye)
        }
    } else {
        let w: CGFloat = wide ? 10 : 8, h: CGFloat = (wide ? 12 : 10) * open
        for sx in [-1.0, 1.0] as [CGFloat] {
            if coat.eye == inkColor {
                oval(cx + sx * 10 - w / 2, cy - h / 2, w, h, inkColor)
            } else { // coloured iris with a dark pupil
                oval(cx + sx * 10 - w / 2 - 0.5, cy - h / 2 - 0.5, w + 1, h + 1, coat.eye)
                oval(cx + sx * 10 - w * 0.22, cy - h * 0.4, w * 0.44, h * 0.8, inkColor)
            }
            if open > 0.6 { oval(cx + sx * 10 - w / 2 + 1.6, cy + h / 2 - 4.6, 3, 3, .white) }
        }
    }
    triangle(CGPoint(x: cx - 3, y: cy - 8), CGPoint(x: cx + 3, y: cy - 8), CGPoint(x: cx, y: cy - 12), pink)
    stroke([CGPoint(x: cx, y: cy - 12), CGPoint(x: cx - 1, y: cy - 16), CGPoint(x: cx - 4, y: cy - 16), CGPoint(x: cx - 5, y: cy - 13)], width: 1.3, line)
    stroke([CGPoint(x: cx, y: cy - 12), CGPoint(x: cx + 1, y: cy - 16), CGPoint(x: cx + 4, y: cy - 16), CGPoint(x: cx + 5, y: cy - 13)], width: 1.3, line)
    for sx in [-1.0, 1.0] as [CGFloat] { for dy in [-2.0, 3.0] as [CGFloat] {
        stroke([CGPoint(x: cx + sx * 16, y: cy - 10), CGPoint(x: cx + sx * 31, y: cy - 10 + dy * 1.6)], width: 0.9, coat.whisker)
    } }
}

struct Scene {
    var coat = coats[0]
    var pose = Pose.sleeping
    var time = 0.0
    var facingLeft = false
    var hearts = 0.0        // 1 just after a pet, fading to 0
    var bubble: String?     // speech bubble above the cat
    var tag: String?        // small name tag above the cat
    var running = false     // faster legs, while playing
    var yarn = false        // a ball of yarn in front of the cat
}

func drawCat(_ s: Scene) {
    guard let ctx = NSGraphicsContext.current?.cgContext else { return }
    let coat = s.coat, t = s.time
    let paw = coat.mask ?? coat.belly
    ctx.saveGState()
    if s.facingLeft { ctx.translateBy(x: canvas.width, y: 0); ctx.scaleBy(x: -1, y: 1) }
    let blink: CGFloat = (t.truncatingRemainder(dividingBy: 4.2) < 0.14) ? 0.1 : 1

    switch s.pose {
    case .sleeping:
        let breath = CGFloat(sin(t * 1.6)) * 1.6
        oval(34, 0, 110, 50 + breath, coat.fur)
        if coat.patches { oval(90, 20, 30, 24, ginger); oval(118, 8, 20, 22, soot) }
        if coat.stripes { for dx in [0.0, 14.0, 28.0] as [CGFloat] { stroke([CGPoint(x: 92 + dx, y: 47 + breath), CGPoint(x: 96 + dx, y: 34 + breath)], width: 2.6, coat.dark) } }
        stroke([CGPoint(x: 138, y: 16), CGPoint(x: 152, y: 9), CGPoint(x: 96, y: 5), CGPoint(x: 72, y: 10)], width: 9, coat.dark)
        drawHead(coat, cx: 62, cy: 25 + breath * 0.4, open: 0, wide: false)
    case .sitting, .excited, .onBreak:
        let excited = s.pose == .excited
        ctx.translateBy(x: 0, y: excited ? abs(CGFloat(sin(t * 9))) * 6 : 0)
        let swish = CGFloat(sin(t * (excited ? 9 : 2.6))) * (excited ? 16 : 9)
        stroke([CGPoint(x: 104, y: 8), CGPoint(x: 134, y: 4), CGPoint(x: 142 + swish * 0.4, y: 26), CGPoint(x: 132 + swish, y: 46)], width: 9, coat.dark)
        oval(56, 0, 58, 66, coat.fur)
        if coat.patches { oval(57, 30, 20, 24, ginger); oval(97, 20, 16, 26, soot) }
        oval(70, 6, 30, 40, coat.belly)
        oval(66, -2, 15, 10, paw); oval(89, -2, 15, 10, paw)
        drawHead(coat, cx: 85, cy: 80, open: blink, wide: excited)
    case .walking:
        let step = CGFloat(sin(t * (s.running ? 20 : 11)))
        stroke([CGPoint(x: 44, y: 44), CGPoint(x: 30, y: 52), CGPoint(x: 22, y: 70), CGPoint(x: 28 + step * 3, y: 86)], width: 8, coat.dark)
        for (i, x) in ([50.0, 64.0, 96.0, 110.0] as [CGFloat]).enumerated() {
            let lift = (i % 2 == 0 ? step : -step) * 5
            (i % 2 == 0 ? coat.dark : (coat.mask ?? coat.fur)).setFill()
            NSBezierPath(roundedRect: NSRect(x: x + lift * 0.8, y: max(0, lift), width: 10, height: 26), xRadius: 5, yRadius: 5).fill()
        }
        oval(40, 20, 84, 40, coat.fur)
        if coat.patches { oval(52, 34, 26, 20, ginger); oval(88, 27, 22, 22, soot) }
        if coat.stripes { for dx in [0.0, 13.0, 26.0] as [CGFloat] { stroke([CGPoint(x: 62 + dx, y: 58), CGPoint(x: 64 + dx, y: 47)], width: 2.6, coat.dark) } }
        drawHead(coat, cx: 128, cy: 64 + step * 1.2, open: blink, wide: s.running)
        if s.yarn {
            let roll = CGFloat(t * 9)
            oval(150, 2, 18, 18, rgb(0.86, 0.36, 0.42))
            for k in 0..<3 {
                let a = roll + CGFloat(k) * 1.05
                stroke([CGPoint(x: 159 + cos(a) * 8, y: 11 + sin(a) * 8), CGPoint(x: 159 - cos(a) * 8, y: 11 - sin(a) * 8)], width: 1.1, rgb(0.70, 0.22, 0.30))
            }
        }
    }
    ctx.restoreGState()

    // Everything below is never mirrored.
    if s.pose == .sleeping {
        let phase = t.truncatingRemainder(dividingBy: 3) / 3
        let x0: CGFloat = s.facingLeft ? 66 : 92
        for (i, size) in [9.0, 12.0, 15.0].enumerated() {
            let p = (phase + Double(i) / 3).truncatingRemainder(dividingBy: 1)
            ("z" as NSString).draw(at: CGPoint(x: x0 + CGFloat(p) * 22 * (s.facingLeft ? -1 : 1), y: 58 + CGFloat(p) * 40),
                withAttributes: [.font: NSFont.systemFont(ofSize: CGFloat(size), weight: .bold), .foregroundColor: NSColor.gray.withAlphaComponent(CGFloat(sin(p * .pi)) * 0.8)])
        }
    }
    if s.hearts > 0 {
        for i in 0..<3 {
            let p = CGFloat(1 - s.hearts) + CGFloat(i) * 0.12
            ("♥" as NSString).draw(at: CGPoint(x: 62 + CGFloat(i) * 22 + sin(p * 9) * 4, y: 104 + p * 44),
                withAttributes: [.font: NSFont.systemFont(ofSize: 15), .foregroundColor: pink.withAlphaComponent(max(0, CGFloat(s.hearts)))])
        }
    }
    func pill(_ text: String, y: CGFloat, size: CGFloat, weight: NSFont.Weight, pointer: Bool, alpha: CGFloat) {
        let attrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: size, weight: weight), .foregroundColor: inkColor.withAlphaComponent(alpha)]
        let textSize = (text as NSString).size(withAttributes: attrs)
        let height = textSize.height + 9
        let box = NSRect(x: (canvas.width - textSize.width - 18) / 2, y: y, width: textSize.width + 18, height: height)
        NSColor.black.withAlphaComponent(0.12 * alpha).setFill(); NSBezierPath(roundedRect: box.offsetBy(dx: 0, dy: -1.5), xRadius: height / 2, yRadius: height / 2).fill()
        NSColor.white.withAlphaComponent(alpha).setFill(); NSBezierPath(roundedRect: box, xRadius: height / 2, yRadius: height / 2).fill()
        if pointer { triangle(CGPoint(x: box.midX - 6, y: box.minY + 1), CGPoint(x: box.midX + 6, y: box.minY + 1), CGPoint(x: box.midX, y: box.minY - 7), .white) }
        (text as NSString).draw(at: CGPoint(x: box.minX + 9, y: box.minY + 4.5), withAttributes: attrs)
    }
    if let bubble = s.bubble { pill(bubble, y: 132, size: 12, weight: .semibold, pointer: true, alpha: 1) }
    else if let tag = s.tag, s.hearts <= 0 { pill(tag, y: s.pose == .sleeping ? 66 : s.pose == .walking ? 102 : 118, size: 10, weight: .medium, pointer: false, alpha: 0.85) }
}

// MARK: - A cat's window

final class CatView: NSView {
    var scene = Scene()
    var heartsUntil = Date.distantPast
    var onClick: (() -> Void)?
    var onDragEnd: (() -> Void)?
    var draggable = true
    private(set) var isDragging = false
    private let born = Date()
    private var dragStart: NSPoint?

    override func draw(_ dirtyRect: NSRect) {
        scene.time = Date().timeIntervalSince(born)
        scene.hearts = max(0, heartsUntil.timeIntervalSinceNow / 1.4)
        drawCat(scene)
    }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func mouseDown(with event: NSEvent) { dragStart = NSEvent.mouseLocation; isDragging = false }
    override func mouseDragged(with event: NSEvent) {
        guard draggable, let start = dragStart, let window = window else { return }
        let now = NSEvent.mouseLocation
        if !isDragging && hypot(now.x - start.x, now.y - start.y) < 4 { return }
        isDragging = true
        window.setFrameOrigin(NSPoint(x: window.frame.origin.x + now.x - start.x, y: window.frame.origin.y + now.y - start.y))
        dragStart = now
    }
    override func mouseUp(with event: NSEvent) { if isDragging { onDragEnd?() } else { onClick?() }; dragStart = nil; isDragging = false }
}

func makeCatPanel(_ view: CatView, at origin: NSPoint) -> NSPanel {
    let panel = NSPanel(contentRect: NSRect(origin: origin, size: canvas), styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
    panel.isOpaque = false; panel.backgroundColor = .clear; panel.hasShadow = false
    panel.level = .floating; panel.hidesOnDeactivate = false; panel.isReleasedWhenClosed = false
    panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
    panel.contentView = view
    return panel
}

// MARK: - The link between two Macs

/// What one cat tells the other. Nothing else ever leaves the Mac.
enum Activity: String { case away, resting, working, intense }

/// Carries small encrypted messages through a public relay (ntfy.sh).
/// The pairing code never leaves the two Macs: the channel name and the encryption key are both derived from it,
/// so the relay sees only unreadable data on an unguessable channel.
final class Relay: NSObject, URLSessionDataDelegate {
    static let host = "https://ntfy.sh"
    var onMessage: (([String: Any]) -> Void)?
    private(set) var remaining = 250 // messages left today, as reported by the relay
    private var topic: String?
    private var key: SymmetricKey?
    private var session: URLSession!
    private var stream: URLSessionDataTask?
    private var buffer = Data()
    private var retry = 2.0

    override init() {
        super.init()
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 150 // the relay sends a keep-alive every 45 seconds
        config.timeoutIntervalForResource = 60 * 60 * 24
        session = URLSession(configuration: config, delegate: self, delegateQueue: .main)
    }
    var isConnected: Bool { topic != nil }

    func connect(code: String) {
        disconnect()
        let channel = SHA256.hash(data: Data(("ronron-v1|channel|" + code).utf8))
        topic = "ronron-" + channel.prefix(16).map { String(format: "%02x", $0) }.joined()
        key = SymmetricKey(data: Data(SHA256.hash(data: Data(("ronron-v1|key|" + code).utf8))))
        listen()
    }
    func disconnect() { topic = nil; key = nil; stream?.cancel(); stream = nil; buffer.removeAll() }

    private func listen() {
        guard let topic = topic, let url = URL(string: "\(Relay.host)/\(topic)/json?since=30m") else { return }
        buffer.removeAll()
        stream = session.dataTask(with: url); stream?.resume()
    }
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard dataTask === stream else { return }
        retry = 2
        buffer.append(data)
        while let newline = buffer.firstIndex(of: 0x0A) {
            let line = buffer.subdata(in: buffer.startIndex..<newline)
            buffer.removeSubrange(buffer.startIndex...newline)
            guard let event = try? JSONSerialization.jsonObject(with: line) as? [String: Any], event["event"] as? String == "message",
                  let body = event["message"] as? String, let message = open(body) else { continue }
            onMessage?(message)
        }
    }
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard task === stream, topic != nil else { return }
        let wait = retry; retry = min(retry * 2, 120)
        DispatchQueue.main.asyncAfter(deadline: .now() + wait) { [weak self] in if self?.topic != nil { self?.listen() } }
    }

    private func seal(_ message: [String: Any]) -> String? {
        guard let key = key, let json = try? JSONSerialization.data(withJSONObject: message), let box = try? ChaChaPoly.seal(json, using: key) else { return nil }
        return box.combined.base64EncodedString()
    }
    private func open(_ body: String) -> [String: Any]? {
        guard let key = key, let data = Data(base64Encoded: body), let box = try? ChaChaPoly.SealedBox(combined: data),
              let json = try? ChaChaPoly.open(box, using: key) else { return nil }
        return try? JSONSerialization.jsonObject(with: json) as? [String: Any]
    }

    /// Sends one message. `wait` blocks briefly, for the goodbye sent when the app quits.
    func send(_ message: [String: Any], wait: Bool = false) {
        guard let topic = topic, let url = URL(string: "\(Relay.host)/\(topic)"), let body = seal(message) else { return }
        var request = URLRequest(url: url); request.httpMethod = "POST"; request.httpBody = Data(body.utf8); request.timeoutInterval = 10
        let done = DispatchSemaphore(value: 0)
        let task = URLSession.shared.dataTask(with: request) { [weak self] _, response, _ in
            if let header = (response as? HTTPURLResponse)?.value(forHTTPHeaderField: "ratelimit"),
               let range = header.range(of: #""messages";r=(\d+)"#, options: .regularExpression),
               let left = Int(header[range].dropFirst(11).filter { $0.isNumber }) {
                DispatchQueue.main.async { self?.remaining = left }
            }
            done.signal()
        }
        task.resume()
        if wait { _ = done.wait(timeout: .now() + 1.5) }
    }
}

// MARK: - Behaviour

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private enum Mode { case resting, walking(to: NSPoint, then: Pose), onBreak }
    private enum Visit { case hidden, entering, present, leaving }

    // My cat
    private var panel: NSPanel!
    private let view = CatView(frame: NSRect(origin: .zero, size: canvas))
    private var mode = Mode.resting
    private var home = NSPoint.zero
    private var lastKeyCount = CGEventSource.counterForEventType(.combinedSessionState, eventType: .keyDown)
    private var recentKeys: [Double] = []      // keys per half second, last 2 seconds
    private var lastTyping = Date.distantPast
    private var fastUntil = Date.distantPast
    private var workSeconds = 0.0
    private var lastLogic = Date()
    private let anyInput = CGEventType(rawValue: UInt32.max)!
    private let simulated = option("--simulate").flatMap { Activity(rawValue: $0) }
    // The cats animate all day in the background: keep macOS from slowing the app's timers down (App Nap).
    private let awake = ProcessInfo.processInfo.beginActivity(options: .userInitiatedAllowingIdleSystemSleep, reason: "Animating the cats")

    // The friend's cat
    private var friendPanel: NSPanel!
    private let friendView = CatView(frame: NSRect(origin: .zero, size: canvas))
    private var visit = Visit.hidden
    private var friendActivity = Activity.away
    private var friendStamp = 0.0              // sender's clock, seconds since 1970
    private var playing = false
    private var playStart = Date()
    private var returningHome = false
    private var lastPetSent = Date.distantPast

    // The link
    private let relay = Relay()
    private var myActivity = Activity.away
    private var hasThought = false
    private var lastSent: Activity?
    private var lastSendTime = Date.distantPast

    // Menu
    private var statusItem: NSStatusItem!
    private var statusLine: NSMenuItem!
    private var intervalItems: [NSMenuItem] = []
    private var coatItems: [NSMenuItem] = []
    private var friendMenu = NSMenu()
    private var loginItem: NSMenuItem!

    // Saved settings
    private var breakMinutes: Int { get { let m = store.integer(forKey: "breakMinutes"); return m > 0 ? m : 45 } set { store.set(newValue, forKey: "breakMinutes") } }
    private var coatIndex: Int { get { min(max(store.integer(forKey: "coat"), 0), coats.count - 1) } set { store.set(newValue, forKey: "coat") } }
    private var catName: String { get { store.string(forKey: "name") ?? "Ronron" } set { store.set(newValue, forKey: "name") } }
    private var pairingCode: String? { get { store.string(forKey: "pairingCode") } set { store.set(newValue, forKey: "pairingCode") } }
    private var friendID: String? { get { store.string(forKey: "friendID") } set { store.set(newValue, forKey: "friendID") } }
    private var friendName: String { get { store.string(forKey: "friendName") ?? "Friend" } set { store.set(newValue, forKey: "friendName") } }
    private var invisible: Bool { get { store.bool(forKey: "invisible") } set { store.set(newValue, forKey: "invisible") } }
    private lazy var deviceID: String = {
        if let id = store.string(forKey: "deviceID") { return id }
        let id = UUID().uuidString; store.set(id, forKey: "deviceID"); return id
    }()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let screen = (NSScreen.main ?? NSScreen.screens[0]).visibleFrame
        if let saved = store.string(forKey: "home") { home = NSPointFromString(saved) }
        let visible = NSScreen.screens.contains { $0.frame.insetBy(dx: -20, dy: -20).contains(NSPoint(x: home.x + canvas.width / 2, y: home.y + 20)) }
        if store.string(forKey: "home") == nil || !visible { home = NSPoint(x: screen.maxX - canvas.width - 260, y: screen.minY) }

        view.scene.coat = coats[coatIndex]
        panel = makeCatPanel(view, at: home)
        panel.orderFrontRegardless()
        view.onClick = { [weak self] in self?.pet() }
        view.onDragEnd = { [weak self] in self?.dropped() }

        friendView.draggable = false
        friendView.scene.coat = coats[min(max(store.integer(forKey: "friendCoat"), 0), coats.count - 1)]
        friendPanel = makeCatPanel(friendView, at: home)
        friendView.onClick = { [weak self] in self?.petFriend() }

        buildMenu()
        relay.onMessage = { [weak self] in self?.received($0) }
        if let code = pairingCode { relay.connect(code: code) }
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(goingAway), name: NSWorkspace.willSleepNotification, object: nil)

        let frames = Timer(timeInterval: 1.0 / 30, repeats: true) { [weak self] _ in self?.frame() }
        RunLoop.main.add(frames, forMode: .common)
        let logic = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in self?.think() }
        RunLoop.main.add(logic, forMode: .common)
    }
    func applicationWillTerminate(_ notification: Notification) { goingAway() }
    @objc private func goingAway() {
        guard relay.isConnected, lastSent != .away, lastSent != nil else { return }
        lastSent = .away; relay.send(stateMessage(.away), wait: true)
    }

    // MARK: Animation, 30 times a second

    private func walk(_ window: NSPanel, _ cat: CatView, to target: NSPoint, step: CGFloat) -> Bool {
        let origin = window.frame.origin
        let dx = target.x - origin.x, dy = target.y - origin.y, distance = hypot(dx, dy)
        if distance <= step { window.setFrameOrigin(target); return true }
        cat.scene.facingLeft = dx < 0
        window.setFrameOrigin(NSPoint(x: origin.x + dx / distance * step, y: origin.y + dy / distance * step))
        return false
    }

    private func frame() {
        if case let .walking(target, then) = mode, walk(panel, view, to: target, step: 9) {
            view.scene.pose = then; view.scene.facingLeft = false
            if then == .onBreak { mode = .onBreak; view.scene.bubble = "Break time?"; NSSound(named: "Purr")?.play() } else { mode = .resting }
        }
        animateFriend()
        view.needsDisplay = true
        if visit != .hidden { friendView.needsDisplay = true }
    }

    private var friendPresent: Bool {
        guard pairingCode != nil, !invisible, friendStamp > 0 else { return false }
        // A heartbeat comes every 10 minutes: after two missed ones, the friend is considered gone.
        return friendActivity != .away && Date().timeIntervalSince1970 - friendStamp < 21 * 60
    }
    private var atHome: Bool { if case .resting = mode { return true }; return false }

    /// Where the friend's cat sits: next to mine, closer when they sleep together.
    private func friendSpot(close: Bool) -> NSPoint {
        let screen = NSScreen.screens.first { $0.frame.contains(NSPoint(x: home.x + canvas.width / 2, y: home.y + 20)) } ?? NSScreen.screens[0]
        let gap: CGFloat = close ? 96 : 124
        let right = home.x + gap + canvas.width <= screen.frame.maxX
        return NSPoint(x: home.x + (right ? gap : -gap), y: home.y)
    }
    private func screenEdge(near spot: NSPoint) -> NSPoint {
        let screen = NSScreen.screens.first { $0.frame.contains(NSPoint(x: home.x + canvas.width / 2, y: home.y + 20)) } ?? NSScreen.screens[0]
        return NSPoint(x: spot.x >= home.x ? screen.frame.maxX + 4 : screen.frame.minX - canvas.width - 4, y: home.y)
    }

    private func animateFriend() {
        let together = view.scene.pose == .sleeping && friendActivity == .resting && atHome
        let spot = friendSpot(close: together)
        friendView.scene.tag = friendName
        switch visit {
        case .hidden:
            guard friendPresent else { break }
            friendPanel.setFrameOrigin(screenEdge(near: spot)); friendPanel.orderFrontRegardless()
            friendView.scene.pose = .walking; friendView.scene.running = false; friendView.scene.yarn = false
            visit = .entering
        case .entering:
            if !friendPresent { visit = .leaving }
            else if walk(friendPanel, friendView, to: spot, step: 7) { visit = .present }
        case .leaving:
            stopPlaying()
            friendView.scene.pose = .walking; friendView.scene.running = false
            if walk(friendPanel, friendView, to: screenEdge(near: spot), step: 7) { friendPanel.orderOut(nil); visit = .hidden }
        case .present:
            if !friendPresent { visit = .leaving; break }
            let shouldPlay = atHome && myActivity == .intense && friendActivity == .intense && !view.isDragging
            if shouldPlay && !playing { playing = true; playStart = Date() } else if !shouldPlay && playing { stopPlaying() }
            if playing { // they chase each other and a ball of yarn, back and forth
                let t = Date().timeIntervalSince(playStart), speed = 2.3, reach: CGFloat = 105
                panel.setFrameOrigin(NSPoint(x: home.x + reach * CGFloat(sin(speed * t)), y: home.y))
                friendPanel.setFrameOrigin(NSPoint(x: spot.x + reach * CGFloat(sin(speed * t - 0.75)), y: spot.y))
                view.scene.pose = .walking; view.scene.running = true; view.scene.yarn = true; view.scene.facingLeft = cos(speed * t) < 0
                friendView.scene.pose = .walking; friendView.scene.running = true; friendView.scene.yarn = false; friendView.scene.facingLeft = cos(speed * t - 0.75) < 0
            } else {
                let origin = friendPanel.frame.origin
                friendPanel.setFrameOrigin(NSPoint(x: origin.x + (spot.x - origin.x) * 0.2, y: origin.y + (spot.y - origin.y) * 0.2))
                friendView.scene.running = false; friendView.scene.yarn = false
                friendView.scene.pose = friendActivity == .intense ? .excited : friendActivity == .working ? .sitting : .sleeping
                friendView.scene.facingLeft = together // asleep, they curl up facing each other
            }
        }
        if returningHome, atHome, !playing, !view.isDragging {
            let origin = panel.frame.origin
            if hypot(home.x - origin.x, home.y - origin.y) < 1 { panel.setFrameOrigin(home); returningHome = false }
            else { panel.setFrameOrigin(NSPoint(x: origin.x + (home.x - origin.x) * 0.25, y: origin.y + (home.y - origin.y) * 0.25)) }
        }
    }
    private func stopPlaying() {
        guard playing else { return }
        playing = false; returningHome = true
        view.scene.running = false; view.scene.yarn = false; view.scene.facingLeft = false
        if view.scene.pose == .walking { view.scene.pose = .sitting }
    }

    // MARK: Decisions, twice a second

    // Reads how fast keys are pressed (a count only, never which keys) and decides what the cat does.
    private func think() {
        let now = Date(), elapsed = now.timeIntervalSince(lastLogic); lastLogic = now
        let count = CGEventSource.counterForEventType(.combinedSessionState, eventType: .keyDown)
        let delta = Double(count &- lastKeyCount); lastKeyCount = count
        recentKeys.append(delta); if recentKeys.count > 4 { recentKeys.removeFirst() }
        var rate = recentKeys.reduce(0, +) / 2 // keys per second over the last 2 seconds
        var idle = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: anyInput)
        if let forced = simulated { // testing aid: pretend the keyboard is this busy
            rate = forced == .intense ? 9 : forced == .working ? 3 : 0
            idle = 0
            lastTyping = forced == .resting ? .distantPast : now
            if forced != .intense { fastUntil = .distantPast }
        } else if delta > 0 { lastTyping = now }
        if rate >= 5 { fastUntil = now.addingTimeInterval(40) }

        if idle < 60 { workSeconds += elapsed }
        if idle >= 120 { // away from the keyboard for two minutes: that was a break
            workSeconds = 0
            if case .onBreak = mode { goHome() }
        }

        // What the friend gets to know: one of four words, with enough inertia to stay quiet on the network.
        if idle >= 120 { myActivity = .away }
        else if now < fastUntil && now.timeIntervalSince(lastTyping) < 60 { myActivity = .intense }
        else if now.timeIntervalSince(lastTyping) < 60 { myActivity = .working }
        else { myActivity = .resting }
        hasThought = true
        share()

        guard !playing else { return }
        switch mode {
        case .resting:
            if workSeconds >= Double(breakMinutes) * 60 { startBreak(); return }
            if rate >= 7 { view.scene.pose = .excited }
            else if rate >= 2.5 { view.scene.pose = .sitting }
            else if view.scene.pose != .sleeping && now.timeIntervalSince(lastTyping) > 8 { view.scene.pose = .sleeping }
            else if view.scene.pose == .excited { view.scene.pose = .sitting }
        case .onBreak:
            if let spot = perch(), hypot(spot.x - panel.frame.origin.x, spot.y - panel.frame.origin.y) > 2 { panel.setFrameOrigin(spot) }
        case .walking: break
        }
    }

    // MARK: Talking to the friend

    private func stateMessage(_ activity: Activity) -> [String: Any] {
        ["v": 1, "kind": "state", "id": deviceID, "state": activity.rawValue, "name": catName, "coat": coatIndex, "t": Date().timeIntervalSince1970]
    }
    /// Sends my activity when it changes, at most every 45 seconds, plus a heartbeat every 10 minutes.
    /// The relay allows 250 messages a day: when few are left, the cat talks much less.
    private func share(force: Bool = false) {
        guard relay.isConnected, hasThought else { return } // never speak before the keyboard has been read once
        let activity: Activity = invisible ? .away : myActivity
        let since = Date().timeIntervalSince(lastSendTime)
        let scarce = relay.remaining < 30
        let changed = activity != lastSent
        // Arriving and leaving are told quickly; changes of pace while present can wait.
        let gap: Double = (activity == .away || lastSent == .away) ? 5 : (scarce ? 300 : 45)
        let due = changed ? (lastSent == nil || since >= gap) : (activity != .away && since >= (scarce ? 1200 : 600))
        guard force || due else { return }
        lastSent = activity; lastSendTime = Date()
        relay.send(stateMessage(activity))
    }
    private func received(_ message: [String: Any]) {
        guard let id = message["id"] as? String, id != deviceID, let t = message["t"] as? Double else { return }
        if friendID == nil { friendID = id } // the first other cat on the channel becomes the friend
        guard id == friendID else { return }
        if message["kind"] as? String == "pet" {
            guard Date().timeIntervalSince1970 - t < 20 else { return }
            view.heartsUntil = Date().addingTimeInterval(1.4); friendView.heartsUntil = Date().addingTimeInterval(1.4)
            NSSound(named: "Purr")?.play()
            return
        }
        guard t >= friendStamp else { return }
        let firstContact = friendStamp == 0
        friendStamp = t
        friendActivity = (message["state"] as? String).flatMap { Activity(rawValue: $0) } ?? .away
        if let name = message["name"] as? String, !name.isEmpty { friendName = String(name.prefix(24)) }
        if let coat = message["coat"] as? Int, coats.indices.contains(coat) { friendView.scene.coat = coats[coat]; store.set(coat, forKey: "friendCoat") }
        // A friend who just arrived may have missed my last message: tell them where I am.
        if firstContact && Date().timeIntervalSince1970 - t < 60 && Date().timeIntervalSince(lastSendTime) > 5 { share(force: true) }
    }

    // MARK: Breaks, pets, dragging

    /// Where to sit: on the top edge of the frontmost window of another app.
    private func perch() -> NSPoint? {
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let list = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else { return nil }
        let primaryHeight = NSScreen.screens[0].frame.height
        for info in list {
            guard (info[kCGWindowLayer as String] as? Int) == 0, (info[kCGWindowOwnerName as String] as? String) != "Ronron",
                  let b = info[kCGWindowBounds as String] as? [String: CGFloat],
                  let x = b["X"], let y = b["Y"], let w = b["Width"], let h = b["Height"], w > 300, h > 200 else { continue }
            // CoreGraphics measures from the top of the primary screen; AppKit from its bottom.
            let top = primaryHeight - y
            let centre = NSPoint(x: x + w / 2, y: top - h / 2)
            let screen = NSScreen.screens.first { $0.frame.contains(centre) } ?? NSScreen.screens[0]
            let spotX = min(max(x + w - canvas.width - 30, screen.frame.minX), screen.frame.maxX - canvas.width)
            // Sit on the edge; on a window that touches the top of the screen, sit just inside it.
            return NSPoint(x: spotX, y: min(top - 4, screen.visibleFrame.maxY - canvas.height))
        }
        return nil
    }
    private func startBreak() {
        stopPlaying(); returningHome = false
        let screen = (NSScreen.main ?? NSScreen.screens[0]).visibleFrame
        panel.level = .statusBar
        view.scene.pose = .walking; view.scene.bubble = nil
        mode = .walking(to: perch() ?? NSPoint(x: screen.midX - canvas.width / 2, y: screen.minY), then: .onBreak)
    }
    private func goHome() {
        workSeconds = 0
        panel.level = .floating
        view.scene.bubble = nil; view.scene.pose = .walking
        mode = .walking(to: home, then: .sleeping)
    }
    private func pet() {
        view.heartsUntil = Date().addingTimeInterval(1.4)
        NSSound(named: "Purr")?.play()
        if case .onBreak = mode { goHome() } else if atHome, view.scene.pose == .sleeping { view.scene.pose = .sitting; lastTyping = Date() }
    }
    /// A click on the friend's cat sends hearts to the friend's screen.
    private func petFriend() {
        friendView.heartsUntil = Date().addingTimeInterval(1.4)
        guard relay.isConnected, Date().timeIntervalSince(lastPetSent) > 10 else { return }
        lastPetSent = Date()
        relay.send(["v": 1, "kind": "pet", "id": deviceID, "t": Date().timeIntervalSince1970])
    }
    private func dropped() {
        guard atHome else { return }
        home = panel.frame.origin; returningHome = false
        store.set(NSStringFromPoint(home), forKey: "home")
    }

    // MARK: Menu actions

    @objc private func breakNow() { if atHome { startBreak() } }
    @objc private func pickInterval(_ item: NSMenuItem) { breakMinutes = item.tag; intervalItems.forEach { $0.state = $0.tag == breakMinutes ? .on : .off } }
    @objc private func pickCoat(_ item: NSMenuItem) {
        coatIndex = item.tag; view.scene.coat = coats[coatIndex]
        coatItems.forEach { $0.state = $0.tag == coatIndex ? .on : .off }
        share(force: true)
    }
    private func ask(_ title: String, _ text: String, value: String, button: String) -> String? {
        let alert = NSAlert(); alert.messageText = title; alert.informativeText = text
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 220, height: 24)); field.stringValue = value
        alert.accessoryView = field; alert.addButton(withTitle: button); alert.addButton(withTitle: "Cancel")
        alert.window.initialFirstResponder = field
        NSApp.activate(ignoringOtherApps: true)
        return alert.runModal() == .alertFirstButtonReturn ? field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines) : nil
    }
    @objc private func rename() {
        guard let name = ask("Name your cat", "Your friend sees this name above your cat.", value: catName, button: "Save"), !name.isEmpty else { return }
        catName = String(name.prefix(24)); share(force: true)
    }
    private func pair(with code: String) {
        pairingCode = code; friendID = nil; friendStamp = 0; friendActivity = .away; lastSent = nil
        relay.connect(code: code)
    }
    private func pretty(_ code: String) -> String { code.count == 8 ? code.prefix(4) + "-" + code.suffix(4) : code }
    @objc private func invite() {
        let alphabet = Array("ABCDEFGHJKMNPQRSTUVWXYZ23456789")
        let code = pairingCode ?? String((0..<8).map { _ in alphabet[Int.random(in: 0..<alphabet.count)] })
        if pairingCode == nil { pair(with: code) }
        let alert = NSAlert(); alert.messageText = "Your code: \(pretty(code))"
        alert.informativeText = "Give this code to your friend. They choose “Enter a Friend's Code” in Ronron's menu. Share it with one person only: anyone who has it can become your cat's friend."
        alert.addButton(withTitle: "Copy the Code"); alert.addButton(withTitle: "Close")
        NSApp.activate(ignoringOtherApps: true)
        if alert.runModal() == .alertFirstButtonReturn { NSPasteboard.general.clearContents(); NSPasteboard.general.setString(pretty(code), forType: .string) }
    }
    @objc private func enterCode() {
        guard let typed = ask("Enter your friend's code", "Eight letters and digits, as shown on your friend's Mac.", value: "", button: "Become Friends") else { return }
        let code = String(typed.uppercased().filter { $0.isLetter || $0.isNumber })
        guard code.count == 8 else {
            let alert = NSAlert(); alert.messageText = "That code is not complete"; alert.informativeText = "A code has eight letters and digits, for example ABCD-2345."; alert.runModal(); return
        }
        pair(with: code)
    }
    @objc private func removeFriend() {
        goingAway()
        pairingCode = nil; friendID = nil; friendStamp = 0; friendActivity = .away; lastSent = nil
        store.removeObject(forKey: "friendName")
        relay.disconnect()
    }
    @objc private func toggleInvisible() { invisible.toggle(); share(force: true) }
    @objc private func resetPlace() {
        let screen = (NSScreen.main ?? NSScreen.screens[0]).visibleFrame
        home = NSPoint(x: screen.maxX - canvas.width - 260, y: screen.minY)
        store.set(NSStringFromPoint(home), forKey: "home")
        if atHome { panel.setFrameOrigin(home) }
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

    // MARK: Menu

    private func item(_ title: String, _ action: Selector?) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: ""); item.target = self; return item
    }
    private func info(_ title: String) -> NSMenuItem { let item = NSMenuItem(title: title, action: nil, keyEquivalent: ""); item.isEnabled = false; return item }

    func menuWillOpen(_ menu: NSMenu) {
        loginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
        let left = max(0, Int((Double(breakMinutes) * 60 - workSeconds) / 60))
        if case .onBreak = mode { statusLine.title = "Waiting for you to take a break" }
        else { statusLine.title = left == 0 ? "Break coming up" : "Next break in about \(left) min of work" }

        friendMenu.removeAllItems()
        if let code = pairingCode {
            let words: [Activity: String] = [.away: "is away", .resting: "is taking it easy", .working: "is working", .intense: "is typing flat out"]
            if friendStamp == 0 { friendMenu.addItem(info("Waiting for your friend to enter \(pretty(code))")) }
            else { friendMenu.addItem(info("\(friendName) \(friendPresent ? words[friendActivity]! : "is away")")) }
            friendMenu.addItem(.separator())
            friendMenu.addItem(item("Show My Code…", #selector(invite)))
            let hide = item("Invisible: Keep My Cat at Home", #selector(toggleInvisible)); hide.state = invisible ? .on : .off; friendMenu.addItem(hide)
            friendMenu.addItem(item("Remove This Friend", #selector(removeFriend)))
        } else {
            friendMenu.addItem(item("Invite a Friend…", #selector(invite)))
            friendMenu.addItem(item("Enter a Friend's Code…", #selector(enterCode)))
        }
    }
    private func buildMenu() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "cat.fill", accessibilityDescription: "Ronron")
            ?? NSImage(systemSymbolName: "pawprint.fill", accessibilityDescription: "Ronron")
        let menu = NSMenu(); menu.delegate = self
        statusLine = info(""); menu.addItem(statusLine)
        menu.addItem(.separator())
        menu.addItem(item("Call the Cat for a Break Now", #selector(breakNow)))
        let every = NSMenuItem(title: "Break After", action: nil, keyEquivalent: ""); let sub = NSMenu()
        for m in [25, 45, 60, 90] {
            let i = item("\(m) minutes of work", #selector(pickInterval(_:))); i.tag = m; i.state = m == breakMinutes ? .on : .off
            sub.addItem(i); intervalItems.append(i)
        }
        every.submenu = sub; menu.addItem(every)
        menu.addItem(.separator())
        let mine = NSMenuItem(title: "My Cat", action: nil, keyEquivalent: ""); let looks = NSMenu()
        for (index, coat) in coats.enumerated() {
            let i = item(coat.name, #selector(pickCoat(_:))); i.tag = index; i.state = index == coatIndex ? .on : .off
            looks.addItem(i); coatItems.append(i)
        }
        looks.addItem(.separator()); looks.addItem(item("Rename…", #selector(rename)))
        mine.submenu = looks; menu.addItem(mine)
        let friend = NSMenuItem(title: "Friend", action: nil, keyEquivalent: ""); friend.submenu = friendMenu; menu.addItem(friend)
        menu.addItem(.separator())
        menu.addItem(item("Put the Cat Back in Its Corner", #selector(resetPlace)))
        loginItem = item("Open at Login", #selector(toggleLogin)); menu.addItem(loginItem)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Ronron", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
    }
}

// MARK: - Entry point

private func writePNG(_ image: NSImage, to path: String) {
    if let tiff = image.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff), let png = rep.representation(using: .png, properties: [:]) {
        try? png.write(to: URL(fileURLWithPath: path))
    }
}
private func draw(_ scene: Scene, atX x: CGFloat, y: CGFloat) {
    guard let ctx = NSGraphicsContext.current?.cgContext else { return }
    ctx.saveGState(); ctx.translateBy(x: x, y: y); drawCat(scene); ctx.restoreGState()
}

// `Ronron --render file.png` draws every coat and scene to an image, to check the artwork.
if let path = option("--render") {
    let image = NSImage(size: NSSize(width: canvas.width * 6, height: (canvas.height + 10) * 3))
    image.lockFocus()
    rgb(0.90, 0.90, 0.90).setFill(); NSRect(origin: .zero, size: image.size).fill()
    let row = canvas.height + 10
    for (i, coat) in coats.enumerated() { draw(Scene(coat: coat, pose: .sitting, time: 1, tag: coat.name), atX: CGFloat(i) * canvas.width, y: row * 2 + 5) }
    let poses: [Scene] = [Scene(coat: coats[1], pose: .sleeping, time: 1), Scene(coat: coats[5], pose: .excited, time: 0.17, hearts: 0.7),
                          Scene(coat: coats[4], pose: .walking, time: 0.14), Scene(coat: coats[3], pose: .walking, time: 0.43, facingLeft: true),
                          Scene(coat: coats[2], pose: .onBreak, time: 1, bubble: "Break time?"), Scene(coat: coats[4], pose: .sleeping, time: 1)]
    for (i, scene) in poses.enumerated() { draw(scene, atX: CGFloat(i) * canvas.width, y: row + 5) }
    // Together: sitting side by side, playing, asleep.
    draw(Scene(coat: coats[0], pose: .sitting, time: 1), atX: 0, y: 5); draw(Scene(coat: coats[1], pose: .sitting, time: 2, tag: "Mina"), atX: 124, y: 5)
    draw(Scene(coat: coats[1], pose: .walking, time: 0.3, tag: "Mina", running: true), atX: 330, y: 5); draw(Scene(coat: coats[0], pose: .walking, time: 0.1, running: true, yarn: true), atX: 440, y: 5)
    draw(Scene(coat: coats[0], pose: .sleeping, time: 1), atX: 680, y: 5); draw(Scene(coat: coats[1], pose: .sleeping, time: 2, facingLeft: true, tag: "Mina"), atX: 776, y: 5)
    image.unlockFocus()
    writePNG(image, to: path)
    exit(0)
}

// `--icon file.png` draws the 1024-pixel app icon.
if let path = option("--icon") {
    let image = NSImage(size: NSSize(width: 1024, height: 1024))
    image.lockFocus()
    let tile = NSBezierPath(roundedRect: NSRect(x: 100, y: 100, width: 824, height: 824), xRadius: 185, yRadius: 185)
    NSGradient(starting: rgb(0.62, 0.80, 0.86), ending: rgb(0.86, 0.94, 0.95))?.draw(in: tile, angle: 90)
    if let ctx = NSGraphicsContext.current?.cgContext {
        ctx.translateBy(x: 512 - canvas.width * 2.5, y: 200); ctx.scaleBy(x: 5, y: 5)
        drawCat(Scene(pose: .sitting, time: 1))
    }
    image.unlockFocus()
    writePNG(image, to: path)
    exit(0)
}

let application = NSApplication.shared
let delegate = AppDelegate()
application.delegate = delegate
application.setActivationPolicy(.accessory)
application.run()
