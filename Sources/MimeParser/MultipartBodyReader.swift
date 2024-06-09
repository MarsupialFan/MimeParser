//
//  MultipartBodyReader.swift
//
//
//  Created by Adi Ofer on 6/8/24.
//

import Foundation


enum MultipartBodyReaderError: Error {
    case partBodyNotFound
    case matchError
    case missingMultipartBodyStartMarker
    case missingPartBoundary
}


class MultipartBodyReader {
    let stringReader: StringReader
    let boundary: String
    let dashBoundary: String

    let crlf = "(\n|\r\n)"
    let extraDashes = "--"
    let transportPadding = "[ \t]*"
    let delimiterOrCloseDelimiterSuffix: String
    let partBoundaryRegexStr: String


    init(with boundary: String, using stringReader: StringReader) {
        self.stringReader = stringReader
        self.boundary = boundary
        self.dashBoundary = extraDashes + boundary
        self.delimiterOrCloseDelimiterSuffix = "([ \t]*\n|[ \t]*\r\n|\(extraDashes))"
        self.partBoundaryRegexStr = "^(?s)(.*?)" + crlf + dashBoundary + delimiterOrCloseDelimiterSuffix  // the (?s) flag allows "." to match newline, ".*?" means non-greedy
    }


    // TODO: allow mime nesting once the \r\n issue is fixed
    func skipToMultipartBodyStart() throws {
        let multipartBodyStartRegex = try Regex(crlf + dashBoundary + transportPadding + crlf)
        guard let _ = try stringReader.firstMatch(multipartBodyStartRegex) else {
            logger.error("\(#function): failed to find multipart body start marker")
            throw MultipartBodyReaderError.missingMultipartBodyStartMarker
        }
    }


    //
    // TODO: Simplify the following once the \r?\n issue is resolved:
    //       - change partBoundaryRegexStr to isolate (perhaps with lookbehind?) the body from the newline preceeding it
    //       - call self.firstMatch directly
    //
    func readPartBody(boundary: String) throws -> (Substring, Bool) {
        // Prepare the boundary regex
        let partBoundaryRegex = try Regex(partBoundaryRegexStr)  // TODO: move to ctor

        // Perform the boundary match
        guard let match = try stringReader.firstMatch(partBoundaryRegex) else {
            logger.error("\(#function): part boundary not found")
            throw MultipartBodyReaderError.missingPartBoundary
        }

        // Check if this is the end of the multipart body
        guard let delimiterSuffix = match[3].substring else {
            logger.error("\(#function): match 3 error")
            throw MultipartBodyReaderError.matchError
        }
        let isClosingDelimiter = delimiterSuffix.starts(with: extraDashes)

        // Find the body
        guard let crlfPartBody = match[1].substring else {
            logger.error("\(#function): match 1 error")
            throw MultipartBodyReaderError.matchError
        }
        if crlfPartBody.isEmpty {
            return ("", isClosingDelimiter)
        }

        let bodyMatchStr = "^(?s)\(crlf)(.*)$"             // the (?s) flag allows "." to match newline
        let bodyMatchRegex = try Regex(bodyMatchStr)       // TODO: move to constructor
        guard let bodyMatch = try bodyMatchRegex.wholeMatch(in: crlfPartBody) else {
            logger.error("\(#function): part body not found")
            throw MultipartBodyReaderError.partBodyNotFound
        }
        guard let partBody = bodyMatch[2].substring else {
            logger.error("\(#function): body match error")
            throw MultipartBodyReaderError.matchError
        }

        return (partBody, isClosingDelimiter)
    }
}
