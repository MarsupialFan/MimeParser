//
//  HeaderReaderTests.swift
//
//
//  Created by Adi Ofer on 1/26/24.
//

import XCTest
@testable import MimeParser

final class HeaderReaderTests: XCTestCase {
    func testEmptyMime() throws {
        let stringReader = StringReader(from: "")
        let headerReader = HeaderReader(from: stringReader)
        XCTAssertThrowsError(try headerReader.readHeader(), "Empty header didn't throw an error")  { error in
            XCTAssertEqual(error as? HeaderReaderError, HeaderReaderError.headerNotFound)
        }
    }

    func testRegularHeaders() throws {
        for header in [dummyHeader, multipartHeader, multipartPartHeader] {
            for eol in ["\n", "\r\n"] {
                let validHeader = addEndOfHeaderMarker(header)
                let mime = (validHeader.map { $0.text(eol: eol) }).joined()
                let stringReader = StringReader(from: mime)
                let headerReader = HeaderReader(from: stringReader)
                let readHeader = MyAssertNoThrow(try headerReader.readHeader(), "Failed to read header", file: #file, line: #line, initVal: [])
                XCTAssertNotNil(readHeader)
                XCTAssertEqual(header.count, readHeader!.count)
                for (headerField, readHeaderField) in zip(header, readHeader!) {
                    XCTAssertEqual(headerField.content(), readHeaderField)
                }
            }
        }
    }

    func testHeaderTerminatedByEof() throws {
        let eofTerminatedHeaders: [[MimeEntry]] = [
            [
                NonCrlfTerminatedHeaderField("Content-Type: image/svg+xml"),
            ],
            [
                PlainHeaderField("Content-Type: text/css"),
                NonCrlfTerminatedHeaderField("Content-Transfer-Encoding: quoted-printable"),
            ],
            [
                PlainHeaderField("Content-Type: audio/x-aiff"),
                NonCrlfTerminatedHeaderField("Content-Transfer-Encoding: 7bit"),
            ],
        ]

        for header in eofTerminatedHeaders {
            for eol in ["\n", "\r\n"] {
                let mime = (header.map { $0.text(eol: eol) }).joined()
                let stringReader = StringReader(from: mime)
                let headerReader = HeaderReader(from: stringReader)
                let readHeader = MyAssertNoThrow(try headerReader.readHeader(), "Failed to read eof-terminated header", file: #file, line: #line, initVal: [])
                XCTAssertNotNil(readHeader)
                XCTAssertEqual(header.count, readHeader!.count)
                for (headerField, readHeaderField) in zip(header, readHeader!) {
                    XCTAssertEqual(headerField.content(), readHeaderField)
                }
            }
        }
    }

    func testHeaderTerminatedByNewlineEof() throws {
        for header in [dummyHeader, multipartHeader, multipartPartHeader] {
            let mime = (header.map { $0.text(eol: "\r\n") }).joined()
            let stringReader = StringReader(from: mime)
            let headerReader = HeaderReader(from: stringReader)
            let readHeader = MyAssertNoThrow(try headerReader.readHeader(), "Failed to read header", file: #file, line: #line, initVal: [])
            XCTAssertNotNil(readHeader)
            XCTAssertEqual(header.count, readHeader!.count)
            for (headerField, readHeaderField) in zip(header, readHeader!) {
                XCTAssertEqual(headerField.content(), readHeaderField)
            }
        }
    }
}
