import Foundation

public struct DriveMapping: Codable, Identifiable, Hashable {
    public var id = UUID()
    public var letter: String
    /// `smb://server/share` oder `\\server\share`
    public var target: String

    public init(letter: String, target: String) {
        self.letter = letter
        self.target = target
    }
}

public enum ConversionResult: Equatable {
    case converted(String)
    case unmappedDrive(String)
    case notAPath
}

public enum PathConverter {
    public static func convert(_ raw: String, mappings: [DriveMapping]) -> ConversionResult {
        let text = clean(raw)
        guard !text.isEmpty, !text.contains("\n") else { return .notAPath }

        if text.hasPrefix("\\\\") {
            let parts = text.dropFirst(2).split(separator: "\\", omittingEmptySubsequences: true).map(String.init)
            guard !parts.isEmpty, !parts[0].hasPrefix("?") else { return .notAPath }
            return .converted("smb://" + parts.joined(separator: "/"))
        }

        let chars = Array(text)
        if chars.count >= 2, chars[0].isASCII, chars[0].isLetter, chars[1] == ":",
           chars.count == 2 || chars[2] == "\\" {
            let letter = String(chars[0]).uppercased()
            guard let mapping = mappings.first(where: { $0.letter.uppercased() == letter }),
                  let base = normalizedTarget(mapping.target) else {
                return .unmappedDrive(letter)
            }
            let rest = text.dropFirst(2).split(separator: "\\", omittingEmptySubsequences: true).map(String.init)
            return .converted(([base] + rest).joined(separator: "/"))
        }
        return .notAPath
    }

    /// Bringt ein Mapping-Ziel in die Form `smb://server/share` (ohne Schrägstrich am Ende).
    public static func normalizedTarget(_ target: String) -> String? {
        let t = clean(target)
        if t.lowercased().hasPrefix("smb://") {
            let body = t.dropFirst(6).split(separator: "/", omittingEmptySubsequences: true).joined(separator: "/")
            return body.isEmpty ? nil : "smb://" + body
        }
        if case .converted(let s) = convert(t, mappings: []) { return s }
        return nil
    }

    /// Windows-UNC-Pfad zu einem `smb://`-Link (Rückrichtung).
    public static func windowsPath(from smb: String) -> String? {
        guard smb.lowercased().hasPrefix("smb://") else { return nil }
        return "\\\\" + smb.dropFirst(6).split(separator: "/", omittingEmptySubsequences: true).joined(separator: "\\")
    }

    /// Host-Teil eines `smb://`-Links.
    public static func host(of smb: String) -> String? {
        guard smb.lowercased().hasPrefix("smb://") else { return nil }
        let body = smb.dropFirst(6)
        let hostPart = body.split(separator: "/", maxSplits: 1, omittingEmptySubsequences: true).first
        return hostPart.map { String($0.split(separator: "@").last ?? $0) }
    }

    /// Prozent-kodierte URL zum Öffnen im Finder.
    public static func url(for smb: String) -> URL? {
        guard smb.lowercased().hasPrefix("smb://") else { return nil }
        let body = smb.dropFirst(6)
        let pieces = body.split(separator: "/", maxSplits: 1, omittingEmptySubsequences: true)
        guard let host = pieces.first else { return nil }
        var c = URLComponents()
        c.scheme = "smb"
        c.host = String(host)
        if pieces.count > 1 { c.path = "/" + pieces[1] }
        return c.url
    }

    private static func clean(_ s: String) -> String {
        var t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        let pairs: [(Character, Character)] = [("\"", "\""), ("'", "'"), ("<", ">")]
        if let f = t.first, let l = t.last, t.count >= 2, pairs.contains(where: { $0.0 == f && $0.1 == l }) {
            t = String(t.dropFirst().dropLast()).trimmingCharacters(in: .whitespaces)
        }
        return t
    }
}
