//
//  HeaderReader.swift
//
//
//  Created by Adi Ofer on 6/8/24.
//

import Foundation


enum HeaderReaderError: Error {
    case headerNotFound
}


class HeaderReader {
    let stringReader: StringReader

    init(from stringReader: StringReader) {
        self.stringReader = stringReader
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
            let match = try stringReader.prefixMatch(headerFieldRegex)
            guard let headerFieldMatch = match else {
                // End-of-archive reached
                return nil
            }
            headerFieldLines.append(headerFieldMatch.1)
        } catch StringReaderError.noMatchFound {
            return nil
        }

        // Add any folded lines
        while true {
            do {
                let match = try stringReader.prefixMatch(foldedLineRegex)
                guard let foldedLineMatch = match else {
                    break
                }
                headerFieldLines.append(foldedLineMatch.1)
            } catch StringReaderError.noMatchFound {
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
                    throw HeaderReaderError.headerNotFound
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
}
