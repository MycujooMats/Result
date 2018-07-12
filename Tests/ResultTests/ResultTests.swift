//  Copyright (c) 2015 Rob Rix. All rights reserved.

final class ResultTests: XCTestCase {
	func testMapTransformsSuccesses() {
		XCTAssertEqual(success.map { $0.count } ?? 0, 7)
	}

	func testMapRewrapsFailures() {
		XCTAssertEqual(failure.map { $0.count } ?? 0, 0)
	}

	func testInitOptionalSuccess() {
		XCTAssert(DualResult("success" as String?, failWith: error) == success)
	}

	func testInitOptionalFailure() {
		XCTAssert(DualResult(nil, failWith: error) == failure)
	}

	func testFanout() {
		let resultSuccess = success.fanout(success)
		if let (x, y) = resultSuccess.value {
			XCTAssertTrue(x == "success" && y == "success")
		} else {
			XCTFail()
		}

		let resultFailureBoth = failure.fanout(failure2)
		XCTAssert(resultFailureBoth.error == error)

		let resultFailureLeft = failure.fanout(success)
		XCTAssert(resultFailureLeft.error == error)

		let resultFailureRight = success.fanout(failure2)
		XCTAssert(resultFailureRight.error == error2)
	}

	func testBimapTransformsSuccesses() {
		XCTAssertEqual(success.bimap(
			success: { $0.count },
			failure: { $0 }
		) ?? 0, 7)
	}

	func testBimapTransformsFailures() {
		XCTAssert(failure.bimap(
			success: { $0 },
			failure: { _ in error2 }
		) == failure2)
	}

	// MARK: Errors

	func testErrorsIncludeTheSourceFile() {
		let file = #file
		XCTAssert(DualResult<(), NSError>.error().file == file)
	}

	func testErrorsIncludeTheSourceLine() {
		let (line, error) = (#line, DualResult<(), NSError>.error())
		XCTAssertEqual(error.line ?? -1, line)
	}

	func testErrorsIncludeTheCallingFunction() {
		let function = #function
		XCTAssert(DualResult<(), NSError>.error().function == function)
	}

	func testAnyErrorDelegatesLocalizedDescriptionToUnderlyingError() {
		XCTAssertEqual(error.errorDescription, "localized description")
		XCTAssertEqual(error.localizedDescription, "localized description")
		XCTAssertEqual(error3.errorDescription, "localized description")
		XCTAssertEqual(error3.localizedDescription, "localized description")
	}

	func testAnyErrorDelegatesLocalizedFailureReasonToUnderlyingError() {
		XCTAssertEqual(error.failureReason, "failure reason")
	}

	func testAnyErrorDelegatesLocalizedRecoverySuggestionToUnderlyingError() {
		XCTAssertEqual(error.recoverySuggestion, "recovery suggestion")
	}

	func testAnyErrorDelegatesLocalizedHelpAnchorToUnderlyingError() {
		XCTAssertEqual(error.helpAnchor, "help anchor")
	}

	// MARK: Try - Catch
	
	func testTryCatchProducesSuccesses() {
		let result: DualResult<String, AnyError> = Result(try tryIsSuccess("success"))
		XCTAssert(result == success)
	}
	
	func testTryCatchProducesFailures() {
		let result: DualResult<String, AnyError> = Result(try tryIsSuccess(nil))
		XCTAssert(result.error == error)
	}

	func testTryCatchWithFunctionProducesSuccesses() {
		let function = { try tryIsSuccess("success") }

		let result: DualResult<String, AnyError> = DualResult(attempt: function)
		XCTAssert(result == success)
	}

	func testTryCatchWithFunctionCatchProducesFailures() {
		let function = { try tryIsSuccess(nil) }

		let result: DualResult<String, AnyError> = DualResult(attempt: function)
		XCTAssert(result.error == error)
	}

	func testTryCatchWithFunctionThrowingNonAnyErrorCanProducesAnyErrorFailures() {
		let nsError = NSError(domain: "", code: 0)
		let function: () throws -> String = { throw nsError }

		let result: DualResult<String, AnyError> = DualResult(attempt: function)
		XCTAssert(result.error == AnyError(nsError))
	}

	func testMaterializeProducesSuccesses() {
		let result1: DualResult<String, AnyError> = DualResult(try tryIsSuccess("success"))
		XCTAssert(result1 == success)

		let result2: DualResult<String, AnyError> = DualResult(attempt: { try tryIsSuccess("success") })
		XCTAssert(result2 == success)
	}

	func testMaterializeProducesFailures() {
		let result1: DualResult<String, AnyError> = DualResult(try tryIsSuccess(nil))
		XCTAssert(result1.error == error)

		let result2: DualResult<String, AnyError> = DualResult(attempt: { try tryIsSuccess(nil) })
		XCTAssert(result2.error == error)
	}

	func testMaterializeInferrence() {
		let result = Result(attempt: { try tryIsSuccess(nil) })
		XCTAssert((type(of: result) as Any.Type) is DualResult<String, AnyError>.Type)
	}

	// MARK: Recover

	func testRecoverProducesLeftForLeftSuccess() {
		let left = DualResult<String, Error>.success("left")
		XCTAssertEqual(left.recover("right"), "left")
	}

	func testRecoverProducesRightForLeftFailure() {
		let left = DualResult<String, Error>.failure(Error.a)
		XCTAssertEqual(left.recover("right"), "right")
	}

	// MARK: Recover With

	func testRecoverWithProducesLeftForLeftSuccess() {
		let left = DualResult<String, NSError>.success("left")
		let right = DualResult<String, NSError>.success("right")

		XCTAssertEqual(left.recover(with: right).value, "left")
	}

	func testRecoverWithProducesRightSuccessForLeftFailureAndRightSuccess() {
		struct Error: Swift.Error {}

		let left = DualResult<String, Error>.failure(Error())
		let right = DualResult<String, Error>.success("right")

		XCTAssertEqual(left.recover(with: right).value, "right")
	}

	func testRecoverWithProducesRightFailureForLeftFailureAndRightFailure() {
		enum Error: Swift.Error { case left, right }

		let left = DualResult<String, Error>.failure(.left)
		let right = DualResult<String, Error>.failure(.right)

		XCTAssertEqual(left.recover(with: right).error, .right)
	}

	func testTryMapProducesSuccess() {
		let result = success.tryMap(tryIsSuccess)
		XCTAssert(result == success)
	}

	func testTryMapProducesFailure() {
		let result = DualResult<String, AnyError>.success("fail").tryMap(tryIsSuccess)
		XCTAssert(result == failure)
	}
}


// MARK: - Fixtures

enum Error: Swift.Error, LocalizedError {
	case a, b

	var errorDescription: String? {
		return "localized description"
	}

	var failureReason: String? {
		return "failure reason"
	}

	var helpAnchor: String? {
		return "help anchor"
	}

	var recoverySuggestion: String? {
		return "recovery suggestion"
	}
}

let success = DualResult<String, AnyError>.success("success")
let error = AnyError(Error.a)
let error2 = AnyError(Error.b)
let error3 = AnyError(NSError(domain: "Result", code: 42, userInfo: [NSLocalizedDescriptionKey: "localized description"]))
let failure = DualResult<String, AnyError>.failure(error)
let failure2 = DualResult<String, AnyError>.failure(error2)

// MARK: - Helpers

extension AnyError: Equatable {
	public static func ==(lhs: AnyError, rhs: AnyError) -> Bool {
		return lhs.error._code == rhs.error._code
			&& lhs.error._domain == rhs.error._domain
	}
}

func tryIsSuccess(_ text: String?) throws -> String {
	guard let text = text, text == "success" else {
		throw error
	}

	return text
}

extension NSError {
	var function: String? {
		return userInfo[DualResult<(), NSError>.functionKey] as? String
	}
	
	var file: String? {
		return userInfo[DualResult<(), NSError>.fileKey] as? String
	}

	var line: Int? {
		return userInfo[DualResult<(), NSError>.lineKey] as? Int
	}
}

import Foundation
import Result
import XCTest
