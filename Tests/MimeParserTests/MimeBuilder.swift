//
//  MimeBuilder.swift
//
//
//  Created by Adi Ofer on 1/29/24.
//

import Foundation
@testable import MimeParser

protocol MimeEntry {
    func text(eol: String) -> String
    func content() -> String
}


struct EmptyMimeEntry: MimeEntry {
    func text(eol: String = "\n") -> String {
        return "" + eol
    }

    func content() -> String {
        return ""
    }
}


struct PlainHeaderField: MimeEntry {
    let line: String

    init(_ line: String) {
        self.line = line
    }

    func text(eol: String = "\n") -> String {
        return line + eol
    }

    func content() -> String {
        return line
    }
}


struct NonCrlfTerminatedHeaderField: MimeEntry {
    let line: String

    init(_ line: String) {
        self.line = line
    }

    func text(eol: String = "\n") -> String {
        return line
    }

    func content() -> String {
        return line
    }
}


struct FoldedHeaderField: MimeEntry {
    let lines: [String]

    init(_ lines: [String], whitespace: String = " ") {
        self.lines = [lines[0]] + lines[1...].map { whitespace + $0}  // prepend 'whitespace' to all but first line
    }

    func text(eol: String = "\n") -> String {
        return (lines.map { $0 + eol }).joined()
    }

    func content() -> String {
        return lines.joined()
    }
}


class MultipartBodyStart: MimeEntry {
    let multipartStartDelimiter: String

    init(_ boundary: String) {
        self.multipartStartDelimiter = "--" + boundary
    }

    func text(eol: String) -> String {
        return eol + multipartStartDelimiter + eol
    }

    func content() -> String {
        return multipartStartDelimiter
    }
}


struct BodyEntry: MimeEntry {
    let line: String
    let encoding: Header.ContentTransferEncoding

    init(_ line: String, encoding: String = "7bit") {
        self.line = line
        switch encoding.lowercased() {
        case "base64":
            self.encoding = .base64
        case "quoted-printable":
            self.encoding = .quotedPrintable
        case "8bit": fallthrough
        case "7bit": fallthrough
        case "binary":
            self.encoding = .passThrough
        default:
            self.encoding = .other
        }
    }

    func text(eol: String = "\n") -> String {
        switch encoding {
        case .passThrough:
            return line //+ eol
        case .quotedPrintable:
            return QuotedPrintable.encode(string: line) //+ eol
        case .base64:
            return Data(line.utf8).base64EncodedString() //+ eol
        case .other:
            return "Other encoding scheme is not support" //+ eol
        }
    }

    func content() -> String {
        return line
    }
}


class MultipartBodyBoundary: MimeEntry {
    let multipartPartBoundary: String

    init(_ boundary: String) {
        self.multipartPartBoundary = "--" + boundary
    }

    func text(eol: String) -> String {
        return eol + multipartPartBoundary + eol
    }

    func content() -> String {
        return multipartPartBoundary
    }
}


class MultipartBodyEnd: MimeEntry {
    let multipartCloseDelimiter: String

    init(_ boundary: String) {
        self.multipartCloseDelimiter = "--" + boundary + "--"
    }

    func text(eol: String) -> String {
        return eol + multipartCloseDelimiter + eol
    }

    func content() -> String {
        return multipartCloseDelimiter
    }
}
