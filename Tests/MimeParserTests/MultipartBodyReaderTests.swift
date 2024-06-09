//
//  MultipartBodyReaderTests.swift
//
//
//  Created by Adi Ofer on 6/8/24.
//

import XCTest
@testable import MimeParser

final class MultipartBodyReaderTests: XCTestCase {
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
                    let stringReader = StringReader(from: mime)
                    let multipartBodyReader = MultipartBodyReader(with: boundary, using: stringReader)
                    XCTAssertNoThrow(try multipartBodyReader.skipToMultipartBodyStart())
                }
            }
        }
    }
}
