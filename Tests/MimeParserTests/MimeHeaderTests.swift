//
//  MimeHeaderTests.swift
//  
//
//  Created by Adi Ofer on 1/25/24.
//

import XCTest
@testable import MimeParser

final class MimeHeaderTests: XCTestCase {
    func testDocumentHeader() {
        // nil content type
        XCTAssertNil(DocumentHeader(mimeVersion: "1.0", contentType: nil, contentSubtype: "jpeg",
                                    boundary: "--", contentLocation: "here", contentEncoding: "base64"))
        // nil content subtype
        XCTAssertNil(DocumentHeader(mimeVersion: "1.0", contentType: "text", contentSubtype: nil,
                                    boundary: "--", contentLocation: "here", contentEncoding: "base64"))
        // Mime version must be specified
        XCTAssertNil(DocumentHeader(mimeVersion: nil, contentType: "text", contentSubtype: "jpeg",
                                    boundary: "--", contentLocation: "here", contentEncoding: "base64"))
        // Multipart document headers much have boundary specification
        XCTAssertNil(DocumentHeader(mimeVersion: "1.0", contentType: "multipart", contentSubtype: "jpeg",
                                    boundary: nil, contentLocation: "here", contentEncoding: "base64"))
        // Multipart document headers much have passthrough content transfer encoding
        XCTAssertNil(DocumentHeader(mimeVersion: "1.0", contentType: "multipart", contentSubtype: "jpeg",
                                    boundary: "--", contentLocation: "here", contentEncoding: "base64"))
        XCTAssertNil(DocumentHeader(mimeVersion: "1.0", contentType: "multipart", contentSubtype: "jpeg",
                                    boundary: "--", contentLocation: "here", contentEncoding: "quoted-printable"))
        XCTAssertNil(DocumentHeader(mimeVersion: "1.0", contentType: "multipart", contentSubtype: "jpeg",
                                    boundary: "--", contentLocation: "here", contentEncoding: "blah blah blah"))

        // Valid headers of single part Mime archives
        XCTAssertNotNil(DocumentHeader(mimeVersion: "1.0", contentType: "text", contentSubtype: "html",
                                       boundary: nil, contentLocation: "https://github.com", contentEncoding: nil))
        XCTAssertNotNil(DocumentHeader(mimeVersion: "1.0", contentType: "text", contentSubtype: "plain",
                                       boundary: nil, contentLocation: "https://github.com", contentEncoding: "binaRY"))
        XCTAssertNotNil(DocumentHeader(mimeVersion: "1.0", contentType: "text", contentSubtype: "xml",
                                       boundary: nil, contentLocation: "https://github.com", contentEncoding: "8bit"))

        // Valid headers of multipart Mime archives
        XCTAssertNotNil(DocumentHeader(mimeVersion: "1.0", contentType: "multipart", contentSubtype: "related",
                                       boundary: "-#-#-", contentLocation: "right here", contentEncoding: nil))
        XCTAssertNotNil(DocumentHeader(mimeVersion: "1.4", contentType: "multipart", contentSubtype: "jpeg",
                                       boundary: "(((*", contentLocation: "over there", contentEncoding: "7bIt"))
        XCTAssertNotNil(DocumentHeader(mimeVersion: "2.0", contentType: "multipart", contentSubtype: "related",
                                       boundary: "@@@@@$$$", contentLocation: "no, there", contentEncoding: "8BiT"))
        XCTAssertNotNil(DocumentHeader(mimeVersion: "1.0", contentType: "multipart", contentSubtype: "related",
                                       boundary: "abcd", contentLocation: "Paris", contentEncoding: "BInaRy"))
    }

    func testSectionHeader() {
        // nil content type
        XCTAssertNil(SectionHeader(mimeVersion: "1.0", contentType: nil, contentSubtype: "jpeg",
                                   boundary: "--", contentLocation: "here", contentEncoding: "base64"))
        // nil content subtype
        XCTAssertNil(SectionHeader(mimeVersion: "1.0", contentType: "text", contentSubtype: nil,
                                   boundary: "--", contentLocation: "here", contentEncoding: "base64"))
        // Section headers cannot be of multipart type
        XCTAssertNil(SectionHeader(mimeVersion: "1.0", contentType: "multipart", contentSubtype: "jpeg",
                                   boundary: "--", contentLocation: nil, contentEncoding: "base64"))
    }
}
