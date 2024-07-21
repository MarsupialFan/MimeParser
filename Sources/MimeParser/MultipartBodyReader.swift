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
    case missingStartingCrlf
    case missingTrailingCrlf
}


class MultipartBodyReader {
    let stringReader: StringReader
    let boundary: String
    let dashBoundary: String

    let crlf = "(\n|\r\n)"
    let extraDashes = "--"
    let transportPadding = "[ \t]*"
    let delimiterOrCloseDelimiterSuffix: String

    let multipartBodyStartRegex: Regex<AnyRegexOutput>
    let partBoundaryRegex: Regex<AnyRegexOutput>

    init(with boundary: String, using stringReader: StringReader) throws {
        self.stringReader = stringReader
        self.boundary = boundary
        self.dashBoundary = extraDashes + boundary
        self.delimiterOrCloseDelimiterSuffix = "([ \t]*\n|[ \t]*\r\n|\(extraDashes))"

        // Regex preparation
        self.multipartBodyStartRegex = try Regex(crlf + dashBoundary + transportPadding + crlf)
        self.partBoundaryRegex = try Regex(dashBoundary + delimiterOrCloseDelimiterSuffix)
    }


    // TODO: allow mime nesting once the \r\n issue is fixed
    func skipToMultipartBodyStart() throws {
        let (_, match) = try stringReader.firstMatch(multipartBodyStartRegex)
        if match == nil {
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
        // Perform the boundary match
        let (crlfPartBodyCrlf, optionalMatch) = try stringReader.firstMatch(partBoundaryRegex)
        guard let match = optionalMatch else {
            logger.error("\(#function): part boundary not found")
            throw MultipartBodyReaderError.missingPartBoundary
        }

        // Check if this is the end of the multipart body
        guard let delimiterSuffix = match[1].substring else {
            logger.error("\(#function): delimiter suffix match error")
            throw MultipartBodyReaderError.matchError
        }
        let isClosingDelimiter = delimiterSuffix.starts(with: extraDashes)

        // Drop trailing crlf
        let lastCharacter = crlfPartBodyCrlf.last
        if lastCharacter == nil || (lastCharacter != "\n"  && lastCharacter != "\r\n") {
            logger.error("\(#function): missing trailing CRLF")
            throw MultipartBodyReaderError.missingTrailingCrlf
        }
        let crlfPartBody = crlfPartBodyCrlf.dropLast()

        // Cover the case of an empty body
        if crlfPartBody.isEmpty {
            return ("", isClosingDelimiter)
        }

        // Drop starting crlf
        let firstCharacter = crlfPartBody.first
        if firstCharacter == nil || (firstCharacter != "\n"  && firstCharacter != "\r\n") {
            logger.error("\(#function): missing starting CRLF")
            throw MultipartBodyReaderError.missingStartingCrlf
        }
        return (crlfPartBody.dropFirst(), isClosingDelimiter)
    }
}
