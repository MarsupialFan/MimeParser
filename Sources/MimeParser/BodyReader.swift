//
//  BodyReader.swift
//
//
//  Created by Adi Ofer on 1/23/24.
//

import Foundation


class BodyReader {
    let stringReader: StringReader

    init(from stringReader: StringReader) {
        self.stringReader = stringReader
    }


    let emptyLineRegex = #/(\n|\r\n|$)/#  // not including the old Mac "\r" option


    //
    // Returns the substring starting with the reading pointer and ending with
    // the given delimiter.
    //
    func readBody() throws -> Substring {
        // The body must be separated from the header by an empty line
        guard let _ = try stringReader.prefixMatch(emptyLineRegex) else {
            // Reached end-of-archive
            return ""
        }

        // Get the body itself
        return stringReader.getRemainingSuffix()
    }
}
