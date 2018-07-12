import Foundation
import XCTest
import Result

final class NoErrorTests: XCTestCase {
	func testEquatable() {
		let foo = DualResult<Int, NoError>(1)
		let bar = DualResult<Int, NoError>(1)
		XCTAssertTrue(foo == bar)
	}
}
