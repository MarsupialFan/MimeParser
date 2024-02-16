//
//  MimeReader.swift
//
//
//  Created by Adi Ofer on 1/23/24.
//

import Foundation


enum MimeReaderError: Error {
    case noMatchFound
    case headerNotFound
    case partBodyNotFound
    case matchError
    case missingMultipartBodyStartMarker
    case missingPartBoundary
}


class MimeReader {
    let mimeContent: String           // the Mime archive content
    var readingPointer: String.Index  // read location marker
    let mimeContentEnd: String.Index  // marks the end of mimeContent

    var multipartDelimiterRegex: Regex<(Substring, Substring)>? = nil

    init(from mimeString: String) {
        self.mimeContent = mimeString
        self.readingPointer = self.mimeContent.startIndex
        self.mimeContentEnd = self.mimeContent.endIndex
    }


    //
    // Runs the given regex match 'closure'; updates the reading pointer if the match succeeds.
    //
    // Returns:
    //    - nil if the reading pointer is at end-of-archive.
    //    - The found match, otherwise
    //
    // Throws:
    //    - noMatchFound if not at end-of-archive and 'regex' was not found.
    //    - propagates exceptions thrown by 'closure'
    //
    private func execMatchClosure<T>(_ closure: () throws -> Regex<T>.Match?) throws -> Regex<T>.Match? {
        // First check for end-of-archive
        if readingPointer >= mimeContentEnd {
            return nil
        }

        // Perform the regex match
        do {
            guard let match = try closure() else {
                throw MimeReaderError.noMatchFound
            }
            readingPointer = match.range.upperBound  // move reading pointer past 'line'
            return match
        }
    }

    private func firstMatch<T>(_ regex: Regex<T>) throws -> Regex<T>.Match? {
        let searchRange = Range<String.Index>(uncheckedBounds: (readingPointer, mimeContentEnd))
        let substringToBeSearched: Substring = mimeContent[searchRange]
        return try execMatchClosure({ try regex.firstMatch(in: substringToBeSearched) })
    }


    private func prefixMatch<T>(_ regex: Regex<T>, isPrefix: Bool = false) throws -> Regex<T>.Match? {
        let searchRange = Range<String.Index>(uncheckedBounds: (readingPointer, mimeContentEnd))
        let substringToBeSearched: Substring = mimeContent[searchRange]
        return try execMatchClosure({ substringToBeSearched.prefixMatch(of: regex) })
    }


    let headerFieldRegex = #/(\w[\w-]*:\s.*)(\n|\r\n|$)/#  // TODO: comply with the characters allowed by the spec
    let foldedLineRegex = #/([ \t].*)(\n|\r\n|$)/#

    //
    // Returns:
    //    - The next unfolded header field, if one is found.
    //    - nil if none found.
    //
    // Ref:
    //    - https://datatracker.ietf.org/doc/html/rfc5322).
    //
    private func readNextHeaderField() throws -> String? {
        var headerFieldLines: [Substring] = []

        // Read the next header field line
        do {
            let match = try prefixMatch(headerFieldRegex)
            guard let headerFieldMatch = match else {
                // End-of-archive reached
                return nil
            }
            headerFieldLines.append(headerFieldMatch.1)
        } catch MimeReaderError.noMatchFound {
            return nil
        }

        // Add any folded lines
        while true {
            do {
                let match = try prefixMatch(foldedLineRegex)
                guard let foldedLineMatch = match else {
                    break
                }
                headerFieldLines.append(foldedLineMatch.1)
            } catch MimeReaderError.noMatchFound {
                break
            }
        }

        return headerFieldLines.joined()
    }


    //
    // Returns:
    //    - An array of all the fields of the next header, if any are found
    //    - nil if no header fields are found
    //
    // Throws:
    //    - headerNotFound if no header fields were found
    //
    func readHeader() throws -> [String]? {
        var headerFields: [String] = []  // return value
        while true {
            guard let nextHeaderField = try readNextHeaderField() else {
                // End-of-archive reached
                if headerFields.isEmpty {
                    throw MimeReaderError.headerNotFound
                }
                break
            }

            // Handle end-of-header
            if nextHeaderField.isEmpty {
                break
            }

            headerFields.append(nextHeaderField)
        }

        return headerFields.isEmpty ? nil : headerFields
    }


    let crlf = "(\n|\r\n)"
    let extraDashes = "--"
    let transportPadding = "[ \t]*"

    // TODO: once the \r\n issue is fixed, create a separate MultipartMimeReader and allow recursion
    func skipToMultipartBodyStart(boundary: String) throws {
        let dashBoundary = extraDashes + boundary

        let multipartBodyStartRegex = try Regex(crlf + dashBoundary + transportPadding + crlf)
        guard let _ = try firstMatch(multipartBodyStartRegex) else {
            logger.error("\(#function): failed to find multipart body start marker")
            throw MimeReaderError.missingMultipartBodyStartMarker
        }
    }


    //
    // TODO: Simplify the following once the \r?\n issue is resolved:
    //       - change partBoundaryRegexStr to isolate (perhaps with lookbehind?) the body from the newline preceeding it
    //       - call self.firstMatch directly
    //
    func readPartBody(boundary: String) throws -> (Substring, Bool) {
        // Prepare the boundary regex
        let dashBoundary = extraDashes + boundary
        let delimiterOrCloseDelimiterSuffix = "([ \t]*\n|[ \t]*\r\n|\(extraDashes))"
        let partBoundaryRegexStr = "^(?s)(.*?)" + crlf + dashBoundary + delimiterOrCloseDelimiterSuffix  // the (?s) flag allows "." to match newline, ".*?" means non-greedy
        let partBoundaryRegex = try Regex(partBoundaryRegexStr)

        // Perform the boundary match
        let searchRange = Range<String.Index>(uncheckedBounds: (readingPointer, mimeContentEnd))
        let substringToBeSearched: Substring = mimeContent[searchRange]
        guard let match = try partBoundaryRegex.firstMatch(in: substringToBeSearched) else {
            logger.error("\(#function): part boundary not found")
            throw MimeReaderError.missingPartBoundary
        }

        // Check if this is the end of the multipart body
        guard let delimiterSuffix = match[3].substring else {
            logger.error("\(#function): match 3 error")
            throw MimeReaderError.matchError
        }
        let isClosingDelimiter = delimiterSuffix.starts(with: extraDashes)

        // Find the body
        guard let crlfPartBody = match[1].substring else {
            logger.error("\(#function): match 1 error")
            throw MimeReaderError.matchError
        }
        if crlfPartBody.isEmpty {
            return ("", isClosingDelimiter)
        }
        
        let bodyMatchStr = "^(?s)\(crlf)(.*)$"             // the (?s) flag allows "." to match newline
        let bodyMatchRegex = try Regex(bodyMatchStr)       // TODO: move to constructor
        guard let bodyMatch = try bodyMatchRegex.wholeMatch(in: crlfPartBody) else {
            logger.error("\(#function): part body not found")
            throw MimeReaderError.partBodyNotFound
        }
        guard let partBody = bodyMatch[2].substring else {
            logger.error("\(#function): body match error")
            throw MimeReaderError.matchError
        }

        // Update reading pointer
        readingPointer = match.range.upperBound

        return (partBody, isClosingDelimiter)
    }


    let emptyLineRegex = #/(\n|\r\n|$)/#  // not including the old Mac "\r" option

    //
    // Returns the substring starting with the reading pointer and ending with
    // the given delimiter.
    //
    func readBody() throws -> Substring {
        // The body must be separated from the header by an empty line
        guard let _ = try prefixMatch(emptyLineRegex) else {
            // Reached end-of-archive
            return ""
        }

        // Get the body itself
        let bodyRange = Range<String.Index>(uncheckedBounds: (readingPointer, mimeContentEnd))
        let body: Substring = mimeContent[bodyRange]
        readingPointer = mimeContentEnd
        return body
    }
}
