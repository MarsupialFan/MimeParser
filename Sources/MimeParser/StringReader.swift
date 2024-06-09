//
//  StringReader.swift
//
//
//  Created by Adi Ofer on 6/8/24.
//

import Foundation


enum StringReaderError: Error {
    case noMatchFound
}


class StringReader {
    let string: String                // the string to be read
    var readingPointer: String.Index  // read location marker
    let endPointer: String.Index      // marks the end of 'string'

    var multipartDelimiterRegex: Regex<(Substring, Substring)>? = nil

    init(from string: String) {
        self.string = string
        self.readingPointer = self.string.startIndex
        self.endPointer = self.string.endIndex
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
        if readingPointer >= endPointer {
            return nil
        }

        // Perform the regex match
        do {
            guard let match = try closure() else {
                throw StringReaderError.noMatchFound
            }
            readingPointer = match.range.upperBound  // move reading pointer past 'line'
            return match
        }
    }


    func firstMatch<T>(_ regex: Regex<T>) throws -> Regex<T>.Match? {
        let searchRange = Range<String.Index>(uncheckedBounds: (readingPointer, endPointer))
        let substringToBeSearched: Substring = string[searchRange]
        return try execMatchClosure({ try regex.firstMatch(in: substringToBeSearched) })
    }


    func prefixMatch<T>(_ regex: Regex<T>, isPrefix: Bool = false) throws -> Regex<T>.Match? {
        let searchRange = Range<String.Index>(uncheckedBounds: (readingPointer, endPointer))
        let substringToBeSearched: Substring = string[searchRange]
        return try execMatchClosure({ substringToBeSearched.prefixMatch(of: regex) })
    }


    func getRemainingSuffix() -> Substring {
        let remainingRange = Range<String.Index>(uncheckedBounds: (readingPointer, endPointer))
        let remainingSuffix: Substring = string[remainingRange]
        readingPointer = endPointer
        return remainingSuffix
    }
}
