import XCTest
@testable import PathCore

final class ConverterTests: XCTestCase {
    let maps = [DriveMapping(letter: "M", target: "smb://brudefup1/design/")]

    func testUNC() {
        XCTAssertEqual(PathConverter.convert(#"\\brudefup1\Freigabe\Projekt"#, mappings: []),
                       .converted("smb://brudefup1/Freigabe/Projekt"))
        XCTAssertEqual(PathConverter.convert("  \"\\\\srv\\a\\b\\\"\n", mappings: []), .converted("smb://srv/a/b"))
    }

    func testDrive() {
        XCTAssertEqual(PathConverter.convert(#"M:\Ordner\x"#, mappings: maps), .converted("smb://brudefup1/design/Ordner/x"))
        XCTAssertEqual(PathConverter.convert(#"m:\"#, mappings: maps), .converted("smb://brudefup1/design"))
        XCTAssertEqual(PathConverter.convert(#"Z:\a"#, mappings: maps), .unmappedDrive("Z"))
    }

    func testNonPaths() {
        XCTAssertEqual(PathConverter.convert("hello world", mappings: maps), .notAPath)
        XCTAssertEqual(PathConverter.convert("a:b", mappings: maps), .notAPath)
        XCTAssertEqual(PathConverter.convert("\\\\a\\b\nc", mappings: maps), .notAPath)
    }

    func testURL() {
        XCTAssertEqual(PathConverter.url(for: "smb://srv/Share/a b")?.absoluteString, "smb://srv/Share/a%20b")
        XCTAssertEqual(PathConverter.host(of: "smb://srv/x"), "srv")
        XCTAssertEqual(PathConverter.windowsPath(from: "smb://srv/a/b"), #"\\srv\a\b"#)
    }
}

final class MountedVolumesTests: XCTestCase {
    func testRelativePath() {
        XCTAssertEqual(MountedVolumes.relativePath(of: "smb://srv/Share/a/b", onShareMountedFrom: "smb://user@SRV.local/share"), "a/b")
        XCTAssertEqual(MountedVolumes.relativePath(of: "smb://srv/Share", onShareMountedFrom: "smb://srv/Share"), "")
        XCTAssertNil(MountedVolumes.relativePath(of: "smb://srv/other/a", onShareMountedFrom: "smb://srv/share"))
        XCTAssertNil(MountedVolumes.relativePath(of: "smb://srv", onShareMountedFrom: "smb://srv/share"))
    }
}
