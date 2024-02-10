//
//  TestFrameworkExtensions.swift
//
//
//  Created by Adi Ofer on 1/31/24.
//
// Ref: https://hybridcattt.com/blog/how-to-test-throwing-code-in-swift/
//

import XCTest

func MyAssertNoThrow<T>(_ expression: @autoclosure () throws -> T, _ message: String = "", file: StaticString = #file, line: UInt = #line, initVal: T) -> T {
    func executeAndAssignResult(_ expression: @autoclosure () throws -> T, to: inout T) rethrows {
        to = try expression()
    }

    var result: T = initVal
    XCTAssertNoThrow(try executeAndAssignResult(expression(), to: &result), message, file: file, line: line)
    return result
}

func MyAssertNotNil<T>(_ expression: @autoclosure () throws -> T?, _ message: String = "", file: StaticString = #file, line: UInt = #line) throws -> T {
    func executeAndAssignResult(_ expression: @autoclosure () throws -> T?, to: inout T?) rethrows {
        to = try expression()
    }

    var result: T? = nil
    try executeAndAssignResult(expression(), to: &result)
    XCTAssertNotNil(result, message, file: file, line: line)
    return result!
}
