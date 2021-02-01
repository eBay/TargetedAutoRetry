//
//  TargetedAutoRetryTests.swift
//
//  Created by Pierce, Evan on 9/22/20.
//  Copyright © 2020 Pierce, Evan. All rights reserved.
//
import XCTest
@testable import TargetedAutoRetry

final class TargetedAutoRetryTests: XCTestCase, TargetedAutoRetry {
	// MARK: - Internal Functions
	
	func testBlockSyntax() {
		var count = 0
		autoRetry(mainAction: { count += 1 },
				  successCondition: { count == 3 },
				  retryAttempts: 5,
				  actionDescription: "Count To Three")
		
		XCTAssertEqual(count, 3)
	}
	
	func testInternalFunctionSyntax() {
		var count = 0
		func incrementCount() {
			count += 1
		}
		func countEqualsThree() -> Bool {
			return count == 3
		}
		
		autoRetry(mainAction: incrementCount,
				  successCondition: countEqualsThree,
				  retryAttempts: 5,
				  actionDescription: "Count To Three")
		
		XCTAssert(countEqualsThree())
	}
	
	func testInternalBlockFunctionSyntax() {
		var count = 0
		func incrementCount() {
			count += 1
		}
		func countEqualsThree() -> Bool {
			return count == 3
		}
		
		autoRetry(mainAction: { incrementCount() },
				  successCondition: { countEqualsThree() },
				  retryAttempts: 5,
				  actionDescription: "Count To Three")
		
		XCTAssert(countEqualsThree())
	}
	
	// MARK: - External Functions
	
	private var externalCount = 0
	private func externalIncrementCount() {
		externalCount += 1
	}
	private func externalCountEqualsThree() -> Bool {
		return externalCount == 3
	}
	
	func testExternalFunctionSyntax() {
		autoRetry(mainAction: externalIncrementCount,
				  successCondition: externalCountEqualsThree,
				  retryAttempts: 5,
				  actionDescription: "Count To Three")
		
		XCTAssert(externalCountEqualsThree())
	}
	
	func testExternalBlockFunctionSyntax() {
		autoRetry(mainAction: { externalIncrementCount() },
				  successCondition: { externalCountEqualsThree() },
				  retryAttempts: 5,
				  actionDescription: "Count To Three")
		
		XCTAssert(externalCountEqualsThree())
	}
	
	func testWeakSelfBlockFunctionSyntax() {
		autoRetry(mainAction: { [weak self] in self?.externalIncrementCount() },
				  successCondition: { [weak self] in  self?.externalCountEqualsThree() },
				  retryAttempts: 5,
				  actionDescription: "Count To Three")
		
		XCTAssert(externalCountEqualsThree())
	}
	
	func testStrongSelfBlockFunctionSyntax() {
		autoRetry(
			mainAction: { [weak self] in
				guard let strongSelf = self else { return }
				strongSelf.externalIncrementCount()
			},
			successCondition: { [weak self] in
				guard let strongSelf = self else { return false }
				return strongSelf.externalCountEqualsThree() },
			retryAttempts: 5,
			actionDescription: "Count To Three")
		
		XCTAssert(externalCountEqualsThree())
	}
	
	// MARK: - Nested Auto Retry
	
	private var apple = 0
	private var banana = 0
	private var orange = 0
	
	private func incrementAppleTo(_ number: Int, failTestOnFailure: Bool = true) {
		autoRetry(mainAction: { if (apple < number) { apple += 1 } },
				  successCondition: { apple == number },
				  actionDescription: "Increment apple until it gets to \(number)",
				  failTestOnFailure: failTestOnFailure)
		
		if failTestOnFailure == true {
			XCTAssertEqual(apple, number)
		}
	}
	
	private func incrementBananaTo(_ number: Int, failTestOnFailure: Bool = true) {
		autoRetry(mainAction: { if (banana < number) { banana += 1 } },
				  successCondition: { banana == number },
				  actionDescription: "Increment banana until it gets to \(number)",
				  failTestOnFailure: failTestOnFailure)
		
		if failTestOnFailure == true {
			XCTAssertEqual(banana, number)
		}
	}
	
	private func incrementOrangeTo(_ number: Int, failTestOnFailure: Bool = true) {
		autoRetry(mainAction: { if (orange < number) { orange += 1 } },
				  successCondition: { orange == number },
				  actionDescription: "Increment orange until it gets to \(number)",
				  failTestOnFailure: failTestOnFailure)
		
		if failTestOnFailure == true {
			XCTAssertEqual(orange, number)
		}
	}
	
	func testNestedSyntax() {
		autoRetry(mainAction: {
					incrementAppleTo(2, failTestOnFailure: false)
					incrementBananaTo(4, failTestOnFailure: false)
					incrementOrangeTo(6, failTestOnFailure: false)
				  },
				  successCondition: { apple == 2 && banana == 4 && orange == 6 },
				  actionDescription: "Counting Two Apples, Four Bananas, and Six Oranges.")
		
		XCTAssertEqual(apple, 2)
		XCTAssertEqual(banana, 4)
		XCTAssertEqual(orange, 6)
	}
	
	// MARK: - Chained Auto Retry
	
	func testChainedSyntax() {
		apple = 0
		banana = 0
		orange = 0
		
		incrementAppleTo(1)
		incrementBananaTo(2)
		incrementOrangeTo(3)
		
		XCTAssertEqual(apple, 1)
		XCTAssertEqual(banana, 2)
		XCTAssertEqual(orange, 3)
	}
}
