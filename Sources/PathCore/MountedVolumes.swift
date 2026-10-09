import Foundation

public enum MountedVolumes {
    /// Lokaler Pfad, falls die Freigabe des `smb://`-Links bereits eingehängt ist und der Ordner existiert.
    public static func localURL(forSMB smb: String) -> URL? {
        let keys: [URLResourceKey] = [.volumeURLForRemountingKey]
        let volumes = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: keys, options: []) ?? []
        for volume in volumes {
            guard let remount = try? volume.resourceValues(forKeys: Set(keys)).volumeURLForRemounting,
                  let rest = relativePath(of: smb, onShareMountedFrom: remount.absoluteString) else { continue }
            let target = rest.isEmpty ? volume : volume.appendingPathComponent(rest)
            if FileManager.default.fileExists(atPath: target.path) { return target }
        }
        return nil
    }

    /// Unterpfad innerhalb der Freigabe, wenn `smb` zu `remountURL` (z. B. `smb://user@host/share`) gehört.
    public static func relativePath(of smb: String, onShareMountedFrom remountURL: String) -> String? {
        guard let a = parts(smb), let b = parts(remountURL), a.host == b.host, a.share == b.share else { return nil }
        return a.rest
    }

    private static func parts(_ s: String) -> (host: String, share: String, rest: String)? {
        guard s.lowercased().hasPrefix("smb://") else { return nil }
        let comps = s.dropFirst(6).split(separator: "/", omittingEmptySubsequences: true).map { String($0).removingPercentEncoding ?? String($0) }
        guard comps.count >= 2 else { return nil }
        let host = (comps[0].split(separator: "@").last.map(String.init) ?? comps[0]).lowercased()
        let short = host.split(separator: ".").first.map(String.init) ?? host
        return (short, comps[1].lowercased(), comps.dropFirst(2).joined(separator: "/"))
    }
}
