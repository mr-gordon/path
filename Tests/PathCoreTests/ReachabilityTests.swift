import XCTest
@testable import PathCore

final class ReachabilityTests: XCTestCase {
    func testUnreachableHostReturnsQuickly() async {
        let start = Date()
        let ok = await Reachability.isReachable(host: "10.255.255.1", timeout: 1)
        XCTAssertFalse(ok)
        XCTAssertLessThan(Date().timeIntervalSince(start), 3)
        let unresolvable = await Reachability.isReachable(host: "gibt-es-nicht.invalid", timeout: 1)
        XCTAssertFalse(unresolvable)
    }
}
