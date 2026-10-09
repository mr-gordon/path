import AppKit
import Observation
import ServiceManagement
import UserNotifications
import PathCore

struct HistoryItem: Codable, Identifiable, Hashable {
    var id = UUID()
    var smb: String
    /// Ursprünglicher Windows-Pfad (bei älteren Einträgen nicht vorhanden).
    var original: String?
    var date = Date()
}

@MainActor
@Observable
final class AppState {
    static let shared = AppState()
    static let historyLimit = 10

    private(set) var history: [HistoryItem] = []
    var notice: String?

    var mappings: [DriveMapping] { didSet { save(mappings, key: "mappings") } }
    var discardHistoryOnQuit: Bool { didSet { UserDefaults.standard.set(discardHistoryOnQuit, forKey: "discardOnQuit") } }
    var notifyOnConversion: Bool {
        didSet {
            UserDefaults.standard.set(notifyOnConversion, forKey: "notify")
            if notifyOnConversion { requestNotificationAuthorization() }
        }
    }
    var copyConvertedToClipboard: Bool { didSet { UserDefaults.standard.set(copyConvertedToClipboard, forKey: "copyConverted") } }

    @ObservationIgnored private var lastChangeCount = NSPasteboard.general.changeCount
    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private var noticeTask: Task<Void, Never>?

    private init() {
        let d = UserDefaults.standard
        mappings = Self.load([DriveMapping].self, key: "mappings") ?? []
        discardHistoryOnQuit = d.bool(forKey: "discardOnQuit")
        copyConvertedToClipboard = d.object(forKey: "copyConverted") as? Bool ?? true
        notifyOnConversion = d.object(forKey: "notify") as? Bool ?? true
        history = Self.load([HistoryItem].self, key: "history") ?? []
        if notifyOnConversion { requestNotificationAuthorization() }

        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.pollPasteboard() }
        }
        NotificationCenter.default.addObserver(forName: NSApplication.willTerminateNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated {
                if self?.discardHistoryOnQuit == true { UserDefaults.standard.removeObject(forKey: "history") }
            }
        }
    }

    // MARK: Clipboard

    private func pollPasteboard() {
        let pb = NSPasteboard.general
        guard pb.changeCount != lastChangeCount else { return }
        lastChangeCount = pb.changeCount
        // Passwortmanager & Co. markieren sensible Inhalte – die ignorieren wir.
        let types = pb.types?.map(\.rawValue) ?? []
        guard !types.contains("org.nspasteboard.ConcealedType"),
              !types.contains("org.nspasteboard.TransientType"),
              let text = pb.string(forType: .string) else { return }

        switch PathConverter.convert(text, mappings: mappings) {
        case .converted(let smb):
            add(smb, original: text.trimmingCharacters(in: .whitespacesAndNewlines))
            if copyConvertedToClipboard { copy(smb) }
            notify(smb)
        case .unmappedDrive(let letter):
            showNotice("Laufwerk \(letter): ist nicht zugeordnet – in den Einstellungen ergänzen.")
        case .notAPath:
            break
        }
    }

    private func add(_ smb: String, original: String) {
        history.removeAll { $0.smb == smb }
        history.insert(HistoryItem(smb: smb, original: original), at: 0)
        history = Array(history.prefix(Self.historyLimit))
        save(history, key: "history")
    }

    private func requestNotificationAuthorization() {
        guard Bundle.main.bundleIdentifier != nil else { return }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert]) { _, _ in }
    }

    private func notify(_ smb: String) {
        guard notifyOnConversion, Bundle.main.bundleIdentifier != nil else { return }
        let content = UNMutableNotificationContent()
        content.title = copyConvertedToClipboard ? "Konvertiert und kopiert" : "Konvertiert"
        content.body = smb
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
    }

    func clearHistory() {
        history = []
        UserDefaults.standard.removeObject(forKey: "history")
    }

    // MARK: Actions

    func copy(_ smb: String) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(smb, forType: .string)
        lastChangeCount = pb.changeCount // eigene Änderung nicht erneut verarbeiten
    }

    func copyWindowsPath(_ item: HistoryItem) {
        if let path = item.original ?? PathConverter.windowsPath(from: item.smb) { copy(path) }
    }

    func open(_ item: HistoryItem) {
        if let local = MountedVolumes.localURL(forSMB: item.smb) {
            NSWorkspace.shared.open(local) // bereits eingehängt: kein erneutes Verbinden nötig
            return
        }
        guard let url = PathConverter.url(for: item.smb), let host = PathConverter.host(of: item.smb) else { return }
        Task {
            guard await Reachability.isReachable(host: host) else {
                showNotice("\(host) nicht erreichbar – Netzwerk oder VPN prüfen.")
                return
            }
            NSWorkspace.shared.open(url)
        }
    }

    func showNotice(_ text: String) {
        notice = text
        noticeTask?.cancel()
        noticeTask = Task {
            try? await Task.sleep(for: .seconds(6))
            if !Task.isCancelled { notice = nil }
        }
    }

    // MARK: Login item

    var launchAtLogin: Bool { SMAppService.mainApp.status == .enabled }

    func setLaunchAtLogin(_ on: Bool) {
        do {
            if on { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
        } catch {
            showNotice("Autostart ließ sich nicht ändern – App ggf. in „Programme“ ablegen.")
        }
    }

    // MARK: Persistence

    private func save<T: Encodable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) { UserDefaults.standard.set(data, forKey: key) }
    }

    private static func load<T: Decodable>(_ type: T.Type, key: String) -> T? {
        UserDefaults.standard.data(forKey: key).flatMap { try? JSONDecoder().decode(type, from: $0) }
    }
}
