import SwiftUI
import PathCore

struct ContentView: View {
    @Bindable var state: AppState
    @State private var showSettings = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            if let notice = state.notice {
                Label(notice, systemImage: "exclamationmark.triangle")
                    .font(.callout)
                    .foregroundStyle(.orange)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if showSettings {
                SettingsView(state: state)
            } else {
                HistoryView(state: state)
            }
        }
        .padding(14)
        .frame(width: 340)
    }

    private var header: some View {
        HStack {
            Text("path").font(.headline)
            Spacer()
            Button { showSettings.toggle() } label: {
                Image(systemName: showSettings ? "checkmark" : "gearshape")
            }
            .buttonStyle(.borderless)
            .help(showSettings ? "Fertig" : "Einstellungen")
            Button { NSApplication.shared.terminate(nil) } label: {
                Image(systemName: "power")
            }
            .buttonStyle(.borderless)
            .help("Beenden")
        }
    }
}

struct HistoryView: View {
    let state: AppState

    var body: some View {
        if let latest = state.history.first {
            VStack(alignment: .leading, spacing: 4) {
                Button { state.open(latest) } label: {
                    Text(latest.smb)
                        .font(.system(.body, design: .monospaced))
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .background(.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .help("Im Finder öffnen")
                .contextMenu { winMenu(latest) }
            }
            if state.history.count > 1 {
                Divider()
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(state.history.dropFirst()) { item in
                        HStack(spacing: 6) {
                            Button { state.open(item) } label: {
                                Text(item.smb)
                                    .lineLimit(1).truncationMode(.middle)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .contextMenu { winMenu(item) }
                            Button { state.copy(item.smb) } label: { Image(systemName: "doc.on.doc") }
                                .buttonStyle(.borderless)
                                .help("smb://-Link kopieren")
                        }
                    }
                }
            }
            HStack {
                Button { state.copy(latest.smb) } label: { Label("Kopieren", systemImage: "doc.on.doc") }
                Spacer()
                Button("Verlauf löschen") { state.clearHistory() }
            }
            .buttonStyle(.borderless)
            .font(.caption)
            .foregroundStyle(.secondary)
        } else {
            Text("Kopiere einen Windows-Pfad (\\\\server\\freigabe oder M:\\ordner) – er erscheint hier als smb://-Link.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

extension HistoryView {
    @ViewBuilder func winMenu(_ item: HistoryItem) -> some View {
        Button("smb://-Link kopieren") { state.copy(item.smb) }
        Button("Windows-Pfad kopieren") { state.copyWindowsPath(item) }
    }
}

struct SettingsView: View {
    @Bindable var state: AppState
    @State private var launchAtLogin = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Laufwerke").font(.subheadline.weight(.semibold))
            ForEach($state.mappings) { $m in
                HStack(spacing: 6) {
                    TextField("M", text: $m.letter)
                        .frame(width: 28)
                        .onChange(of: m.letter) { _, v in
                            let l = String(v.filter(\.isLetter).prefix(1)).uppercased()
                            if l != v { m.letter = l }
                        }
                    Text(":").foregroundStyle(.secondary)
                    TextField("smb://server/freigabe", text: $m.target)
                    Button { state.mappings.removeAll { $0.id == m.id } } label: { Image(systemName: "minus.circle") }
                        .buttonStyle(.borderless)
                }
                .textFieldStyle(.roundedBorder)
            }
            Button { state.mappings.append(DriveMapping(letter: "", target: "")) } label: {
                Label("Laufwerk hinzufügen", systemImage: "plus")
            }
            .buttonStyle(.borderless)

            Divider()
            Toggle("smb://-Link nach Erkennung in die Zwischenablage legen", isOn: $state.copyConvertedToClipboard)
            Toggle("Mitteilung nach Erkennung anzeigen", isOn: $state.notifyOnConversion)
            Toggle("Verlauf beim Beenden verwerfen", isOn: $state.discardHistoryOnQuit)
            Toggle("Beim Anmelden starten", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { _, on in
                    if on != state.launchAtLogin { state.setLaunchAtLogin(on) }
                    launchAtLogin = state.launchAtLogin
                }
        }
        .onAppear { launchAtLogin = state.launchAtLogin }
        .toggleStyle(.checkbox)
        .font(.callout)
    }
}
