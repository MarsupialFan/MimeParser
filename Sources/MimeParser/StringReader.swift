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
    var string: String                // the string to be read

    var multipartDelimiterRegex: Regex<(Substring, Substring)>? = nil

    init(from string: String) {
        self.string = string
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
        if self.string.isEmpty {
            return nil
        }

        // Perform the regex match
        do {
            guard let match = try closure() else {
                throw StringReaderError.noMatchFound
            }
            self.string = String(self.string.suffix(from: match.range.upperBound))
            return match
        }
    }


    func firstMatch<T>(_ regex: Regex<T>) throws -> Regex<T>.Match? {
        return try execMatchClosure({ try regex.firstMatch(in: self.string) })
    }


    func prefixMatch<T>(_ regex: Regex<T>, isPrefix: Bool = false) throws -> Regex<T>.Match? {
        return try execMatchClosure({ self.string.prefixMatch(of: regex) })
    }


    func getRemainingSuffix() -> String {
        let remainingSuffix = self.string
        self.string = ""
        return remainingSuffix
    }
}
