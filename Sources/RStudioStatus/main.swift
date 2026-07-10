import AppKit
import Foundation
import Network
import ServiceManagement
import UserNotifications

private enum RunState: String, Codable {
    case idle
    case running
    case complete
    case fail

    var menuTitle: String {
        switch self {
        case .idle: return ""
        case .running: return "Running ⏳"
        case .complete: return "Complete ✅"
        case .fail: return "Fail ⚠️"
        }
    }
}

private struct StatusUpdate: Decodable {
    let status: RunState
    let name: String?
    let message: String?
}

private final class LocalHTTPServer {
    private var listener: NWListener?
    private let queue = DispatchQueue(label: "RStudioStatus.HTTPServer")
    var onStatus: ((StatusUpdate) -> Void)?

    func start(port: UInt16 = 47821) throws {
        guard let port = NWEndpoint.Port(rawValue: port) else {
            throw NSError(domain: "RStudioStatus", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "잘못된 포트입니다."])
        }
        let parameters = NWParameters.tcp
        parameters.requiredLocalEndpoint = .hostPort(host: "127.0.0.1", port: port)
        let listener = try NWListener(using: parameters)
        listener.newConnectionHandler = { [weak self] connection in
            self?.handle(connection)
        }
        listener.stateUpdateHandler = { state in
            if case .failed(let error) = state {
                NSLog("RStudio Status server failed: \(error)")
            }
        }
        listener.start(queue: queue)
        self.listener = listener
    }

    func stop() {
        listener?.cancel()
        listener = nil
    }

    private func handle(_ connection: NWConnection) {
        connection.start(queue: queue)
        receive(on: connection, buffer: Data())
    }

    private func receive(on connection: NWConnection, buffer: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65_536) { [weak self] data, _, complete, error in
            var buffer = buffer
            if let data { buffer.append(data) }

            if let request = self?.completeRequest(in: buffer) {
                self?.process(request, on: connection)
            } else if complete || error != nil || buffer.count >= 65_536 {
                self?.respond(status: "400 Bad Request", body: #"{"ok":false}"#, on: connection)
            } else {
                self?.receive(on: connection, buffer: buffer)
            }
        }
    }

    private func completeRequest(in data: Data) -> Data? {
        let marker = Data("\r\n\r\n".utf8)
        guard let headerEnd = data.range(of: marker) else { return nil }
        let headerData = data[..<headerEnd.lowerBound]
        guard let headers = String(data: headerData, encoding: .utf8) else { return nil }
        let contentLength = headers
            .split(separator: "\r\n")
            .first { $0.lowercased().hasPrefix("content-length:") }
            .flatMap { Int($0.split(separator: ":", maxSplits: 1)[1].trimmingCharacters(in: .whitespaces)) } ?? 0
        let totalLength = headerEnd.upperBound + contentLength
        guard data.count >= totalLength else { return nil }
        return data.prefix(totalLength)
    }

    private func process(_ request: Data, on connection: NWConnection) {
        guard let text = String(data: request, encoding: .utf8),
              let firstLine = text.components(separatedBy: "\r\n").first else {
            respond(status: "400 Bad Request", body: #"{"ok":false}"#, on: connection)
            return
        }

        if firstLine.hasPrefix("GET /health ") {
            respond(status: "200 OK", body: #"{"ok":true,"app":"RStudio Status"}"#, on: connection)
            return
        }

        guard firstLine.hasPrefix("POST /status "),
              let bodyRange = request.range(of: Data("\r\n\r\n".utf8)) else {
            respond(status: "404 Not Found", body: #"{"ok":false}"#, on: connection)
            return
        }

        let body = request[bodyRange.upperBound...]
        do {
            let update = try JSONDecoder().decode(StatusUpdate.self, from: body)
            DispatchQueue.main.async { [weak self] in self?.onStatus?(update) }
            respond(status: "200 OK", body: #"{"ok":true}"#, on: connection)
        } catch {
            respond(status: "400 Bad Request", body: #"{"ok":false,"error":"invalid status"}"#, on: connection)
        }
    }

    private func respond(status: String, body: String, on connection: NWConnection) {
        let response = "HTTP/1.1 \(status)\r\nContent-Type: application/json\r\nContent-Length: \(body.utf8.count)\r\nConnection: close\r\n\r\n\(body)"
        connection.send(content: Data(response.utf8), completion: .contentProcessed { _ in
            connection.cancel()
        })
    }
}

@MainActor
private final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    private let server = LocalHTTPServer()
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let menu = NSMenu()
    private let summaryItem = NSMenuItem(title: "RStudio 연결 대기 중", action: nil, keyEquivalent: "")
    private let detailItem = NSMenuItem(title: "포트 47821", action: nil, keyEquivalent: "")
    private let elapsedItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private var state: RunState = .idle
    private var taskName = ""
    private var detailMessage = ""
    private var startedAt: Date?
    private var timer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        if let url = Bundle.main.url(forResource: "RStudio", withExtension: "icns"),
           let icon = NSImage(contentsOf: url) {
            NSApp.applicationIconImage = icon
        }
        configureMenu()
        updateDisplay()

        server.onStatus = { [weak self] update in self?.apply(update) }
        do {
            try server.start()
            summaryItem.title = "RStudio 연결 준비됨"
        } catch {
            state = .fail
            detailMessage = "포트 47821을 열 수 없습니다: \(error.localizedDescription)"
        }
        updateDisplay()

        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func applicationWillTerminate(_ notification: Notification) {
        timer?.invalidate()
        server.stop()
    }

    private func configureMenu() {
        statusItem.button?.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        statusItem.button?.toolTip = "RStudio 작업 상태"
        statusItem.button?.imageScaling = .scaleNone
        statusItem.menu = menu

        summaryItem.isEnabled = false
        detailItem.isEnabled = false
        elapsedItem.isEnabled = false
        menu.addItem(summaryItem)
        menu.addItem(detailItem)
        menu.addItem(elapsedItem)
        menu.addItem(.separator())

        let resetItem = NSMenuItem(title: "상태 초기화", action: #selector(resetStatus), keyEquivalent: "r")
        resetItem.target = self
        menu.addItem(resetItem)

        let notificationItem = NSMenuItem(title: "알림 테스트", action: #selector(testNotification), keyEquivalent: "n")
        notificationItem.target = self
        menu.addItem(notificationItem)

        let openItem = NSMenuItem(title: "RStudio 열기", action: #selector(openRStudio), keyEquivalent: "o")
        openItem.target = self
        menu.addItem(openItem)

        if #available(macOS 13.0, *) {
            let launchItem = NSMenuItem(title: "로그인 시 실행", action: #selector(toggleLaunchAtLogin(_:)), keyEquivalent: "")
            launchItem.target = self
            launchItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
            menu.addItem(launchItem)
        }

        menu.addItem(.separator())
        let quitItem = NSMenuItem(title: "RStudio Status 종료", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }

    private func loadMenuBarIcon() -> NSImage? {
        guard let url = Bundle.main.url(forResource: "RStudio", withExtension: "icns"),
              let sourceImage = NSImage(contentsOf: url) else { return nil }

        var proposedRect = NSRect(x: 0, y: 0, width: 1024, height: 1024)
        guard let source = sourceImage.cgImage(forProposedRect: &proposedRect, context: nil, hints: nil) else {
            return nil
        }

        // App icons contain transparent safety padding. Remove it so the logo is
        // visibly larger instead of being normalized back to the menu-bar default.
        let side = CGFloat(min(source.width, source.height))
        let inset = side * 0.075
        let cropRect = CGRect(x: inset, y: inset, width: side - inset * 2, height: side - inset * 2)
        guard let cropped = source.cropping(to: cropRect) else { return nil }
        let menuImage = NSImage(cgImage: cropped, size: NSSize(width: 24, height: 24))
        menuImage.isTemplate = false
        return menuImage
    }

    private func apply(_ update: StatusUpdate) {
        state = update.status
        if let name = update.name, !name.isEmpty { taskName = name }
        detailMessage = update.message ?? ""

        if state == .running {
            startedAt = Date()
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                Task { @MainActor in self?.updateDisplay() }
            }
        } else {
            timer?.invalidate()
            timer = nil
            if state == .complete || state == .fail { sendNotification() }
        }
        updateDisplay()
    }

    private func updateDisplay() {
        var title = state.menuTitle
        if state == .running, let startedAt {
            title += " \(formatElapsed(Date().timeIntervalSince(startedAt)))"
        }
        if state == .idle {
            statusItem.length = 28
            statusItem.button?.image = loadMenuBarIcon()
            statusItem.button?.imagePosition = .imageOnly
            statusItem.button?.title = ""
        } else {
            statusItem.length = NSStatusItem.variableLength
            statusItem.button?.image = nil
            statusItem.button?.imagePosition = .noImage
            statusItem.button?.title = title
        }
        let summary = state == .idle ? "RStudio Ready" : state.menuTitle
        summaryItem.title = taskName.isEmpty ? summary : "\(summary) · \(taskName)"

        if !detailMessage.isEmpty {
            detailItem.title = detailMessage
            detailItem.isHidden = false
        } else {
            detailItem.title = "localhost:47821"
            detailItem.isHidden = false
        }

        if let startedAt {
            elapsedItem.title = "실행 시간: \(formatElapsed(Date().timeIntervalSince(startedAt)))"
            elapsedItem.isHidden = false
        } else {
            elapsedItem.isHidden = true
        }
    }

    private func formatElapsed(_ interval: TimeInterval) -> String {
        let seconds = max(0, Int(interval))
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remainder = seconds % 60
        return hours > 0
            ? String(format: "%d:%02d:%02d", hours, minutes, remainder)
            : String(format: "%02d:%02d", minutes, remainder)
    }

    private func sendNotification() {
        let title = taskName.isEmpty ? state.menuTitle : taskName
        let body = state == .complete ? "R 작업이 완료되었습니다." : (detailMessage.isEmpty ? "R 작업이 실패했습니다." : detailMessage)
        postNotification(title: title, body: body)
    }

    private func postNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
    }

    @objc private func testNotification() {
        postNotification(title: "RStudio Status", body: "RStudio 로고 알림 테스트입니다.")
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            willPresent notification: UNNotification,
                                            withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    @objc private func resetStatus() {
        timer?.invalidate()
        timer = nil
        state = .idle
        taskName = ""
        detailMessage = ""
        startedAt = nil
        updateDisplay()
    }

    @objc private func openRStudio() {
        let candidates = ["/Applications/RStudio.app", NSHomeDirectory() + "/Applications/RStudio.app"]
        if let path = candidates.first(where: FileManager.default.fileExists(atPath:)) {
            NSWorkspace.shared.open(URL(fileURLWithPath: path))
        }
    }

    @available(macOS 13.0, *)
    @objc private func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
                sender.state = .off
            } else {
                try SMAppService.mainApp.register()
                sender.state = .on
            }
        } catch {
            detailMessage = "로그인 실행 설정 실패: \(error.localizedDescription)"
            updateDisplay()
        }
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

@main
private enum RStudioStatusMain {
    private static var delegate: AppDelegate?

    static func main() {
        let app = NSApplication.shared
        let appDelegate = AppDelegate()
        delegate = appDelegate
        app.delegate = appDelegate
        app.run()
    }
}
