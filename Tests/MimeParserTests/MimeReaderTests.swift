//
//  MimeReaderTests.swift
//  
//
//  Created by Adi Ofer on 1/26/24.
//

import XCTest
@testable import MimeParser

final class MimeReaderTests: XCTestCase {
    let emptyHeader: [MimeEntry] = []
    let dummyHeader: [MimeEntry] = [
        PlainHeaderField("header-field-1: value 1"),
        PlainHeaderField("header-field-2: value 2"),
        FoldedHeaderField(["folded-header-field-3: value 3", "3.A", "3.B", "3.C"], whitespace: "\t"),
        PlainHeaderField("header-field-4: value 4"),
        FoldedHeaderField(["folded-header-field-5: value 5", "5.i", "5.ii", "5.iii", "5.iv", "5.v"]),
    ]
    let multipartHeader: [MimeEntry] = [
        PlainHeaderField("From: <Saved by Blink>"),
        PlainHeaderField("Snapshot-Content-Location: https://google.com"),
        PlainHeaderField("Subject: =?utf-8?Q?The=20=E2=80=98"),
        PlainHeaderField("Date: Sat, 2 Dec 2023 18:16:40 -0800"),
        PlainHeaderField("MIME-Version: 1.0"),
        FoldedHeaderField([
            "Content-Type: multipart/related;",
            "type=\"text/html\";",
            "boundary=\"----MultipartBoundary--91CIefJbpm72OBDEE6zCI8OLw8h18kJbYxeqmjA2Zd----\""
        ]),
    ]
    let multipartPartHeader: [MimeEntry] = [
        PlainHeaderField("Content-Type: application/x-authorware-map"),
        PlainHeaderField("Content-Transfer-Encoding: binary"),
        PlainHeaderField("Content-Location: cid:b44c8605-ad39-43d4-973f-d7f747ccc741@mhtml.blink"),
    ]

    private func addEndOfHeaderMarker(_ headerFields: [MimeEntry]) -> [MimeEntry] {
        return headerFields + [EmptyMimeEntry()]
    }

    func testEmptyMime() throws {
        let reader = MimeReader(from: "")
        XCTAssertThrowsError(try reader.readHeader(), "Empty header didn't throw an error")  { error in
            XCTAssertEqual(error as? MimeReaderError, MimeReaderError.headerNotFound)
        }
    }

    func testRegularHeaders() throws {
        for header in [dummyHeader, multipartHeader, multipartPartHeader] {
            for eol in ["\n", "\r\n"] {
                let validHeader = addEndOfHeaderMarker(header)
                let mime = (validHeader.map { $0.text(eol: eol) }).joined()
                let reader = MimeReader(from: mime)
                let readHeader = MyAssertNoThrow(try reader.readHeader(), "Failed to read header", file: #file, line: #line, initVal: [])
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
                let reader = MimeReader(from: mime)
                let readHeader = MyAssertNoThrow(try reader.readHeader(), "Failed to read eof-terminated header", file: #file, line: #line, initVal: [])
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
            let reader = MimeReader(from: mime)
            let readHeader = MyAssertNoThrow(try reader.readHeader(), "Failed to read header", file: #file, line: #line, initVal: [])
            XCTAssertNotNil(readHeader)
            XCTAssertEqual(header.count, readHeader!.count)
            for (headerField, readHeaderField) in zip(header, readHeader!) {
                XCTAssertEqual(headerField.content(), readHeaderField)
            }
        }
    }

    func testSkipToMultipartBodyStart() throws {
        let body = """
            Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed
            do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut
            """
        for boundary in ["dummy boundary", "----MultipartBoundary--91CIefJbpm72OBDEE6zbYxeqmjA2Zd----"] {
            let body: [MimeEntry] = [
                MultipartBodyStart(boundary),
                BodyEntry(body),
            ]

            for header in [emptyHeader, dummyHeader, multipartHeader] {
                for eol in ["\n", "\r\n"] {
                    let mimeEntries = addEndOfHeaderMarker(header) + body
                    let mime = (mimeEntries.map { $0.text(eol: eol) }).joined()
                    let reader = MimeReader(from: mime)
                    XCTAssertNoThrow(try reader.skipToMultipartBodyStart(boundary: boundary))
                }
            }
        }
    }
}
