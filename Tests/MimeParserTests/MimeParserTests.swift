//
//  MimeParserTests.swift
//
//
//  Created by Adi Ofer on 1/26/24.
//

import XCTest
@testable import MimeParser

let encodings: [String] = ["base64", "quoted-printable", "8bit", "7bit", "binary"]

final class MimeParserTests: XCTestCase {
    func testParseHeaderOnlyMime() throws {
        let mimeEntries: [MimeEntry] = [
            PlainHeaderField("MIME-Version: 1.0"),
            PlainHeaderField("Content-Type: text/plain; charset=UTF-8"),
            PlainHeaderField("Content-Transfer-Encoding: 8bit"),
        ]
        for eol in ["\n", "\r\n"] {
            let mime = (mimeEntries.map { $0.text(eol: eol) }).joined()
            let mimeParser = MimeParser(from: mime)
            let mimeArchive = MyAssertNoThrow(try mimeParser.parse(), "Failed to parse", file: #file, line: #line, initVal: nil)
            XCTAssertNotNil(mimeArchive)
            let decodedBody = String(data: mimeArchive!.mainResource.body, encoding: .utf8)
            XCTAssertTrue(decodedBody!.isEmpty)
        }
    }

    func testSingleBody() throws {
        let text = """
            At vero eos et accusamus et iusto odio dignissimos ducimus qui blanditiis praesentium voluptatum deleniti atque corrupti
            quos dolores et quas molestias excepturi sint occaecati cupiditate non provident, similique sunt in culpa qui officia
            deserunt mollitia animi, id est laborum et dolorum fuga. Et harum quidem rerum facilis est et expedita distinctio. Nam
            libero tempore, cum soluta nobis est eligendi optio cumque nihil impedit quo minus id quod maxime placeat facere possimus,
            omnis voluptas assumenda est, omnis dolor repellendus. Temporibus autem quibusdam et aut officiis debitis aut rerum
            necessitatibus saepe eveniet ut et voluptates repudiandae sint et molestiae non recusandae. Itaque earum rerum hic tenetur
            a sapiente delectus, ut aut reiciendis voluptatibus maiores alias consequatur aut perferendis doloribus asperiores repellat.
            """
        for encoding in encodings {
            let mimeEntries: [MimeEntry] = [
                PlainHeaderField("MIME-Version: 1.0"),
                PlainHeaderField("Content-Type: text/plain; charset=UTF-8"),
                PlainHeaderField("Content-Transfer-Encoding: \(encoding)"),
                EmptyMimeEntry(),
                BodyEntry(text, encoding: encoding),
            ]
            for eol in ["\n", "\r\n"] {
                let mime = (mimeEntries.map { $0.text(eol: eol) }).joined()
                let mimeParser = MimeParser(from: mime)
                let mimeArchive = MyAssertNoThrow(try mimeParser.parse(), "Failed to parse", file: #file, line: #line, initVal: nil)
                XCTAssertNotNil(mimeArchive)
                let decodedBody = String(data: mimeArchive!.mainResource.body, encoding: .utf8)
                if encoding == "quoted-printable" {  // quoted-printable messes with \n and \r\n
                    XCTAssertEqual(decodedBody!.replacingOccurrences(of: "\r\n", with: "\n"), text.replacingOccurrences(of: "\r\n", with: "\n"))
                } else {
                    XCTAssertEqual(decodedBody!, text)
                }
            }
        }
    }

    func testMultipartBodyHeaderOnlyPartBodyMime() throws {
        let boundary = "===---==="
        let mimeEntries: [MimeEntry] = [
            PlainHeaderField("MIME-Version: 1.0"),
            PlainHeaderField("Content-Type: multipart/related; type=\"text/html\"; boundary=\"\(boundary)\""),
            //EmptyMimeEntry(),
            MultipartBodyStart(boundary),
            PlainHeaderField("Content-Type: text/plain; charset=UTF-8"),
            PlainHeaderField("Content-Transfer-Encoding: binary"),
            //EmptyMimeEntry(),
            MultipartBodyEnd(boundary)
        ]
        for eol in ["\n", "\r\n"] {
            let mime = (mimeEntries.map { $0.text(eol: eol) }).joined()
            let mimeParser = MimeParser(from: mime)
            let mimeArchive = MyAssertNoThrow(try mimeParser.parse(), "Failed to parse", file: #file, line: #line, initVal: nil)
            XCTAssertNotNil(mimeArchive)
            let decodedBody = String(data: mimeArchive!.mainResource.body, encoding: .utf8)
            XCTAssertTrue(decodedBody!.isEmpty)
        }
    }

    func testMultipartBody() throws {
        func bodyLineText(_ i: Int) -> String {
            return "Body line #\(i)"
        }

        func bodyLine(_ i: Int, encoding: String = "7bit") -> MimeEntry {
            return BodyEntry(bodyLineText(i), encoding: encoding)
        }

        for boundary in ["___=_Part_lasjflkjlkjasdf___", "------MultipartBoundary--8asdf8asdf8766asdf------"] {
            let mimeEntriesBase: [MimeEntry] = [
                PlainHeaderField("MIME-Version: 1.0"),
                FoldedHeaderField([
                    "Content-Type: multipart/related;",
                    "type=\"text/html\";",
                    "boundary=\"\(boundary)\""
                ]),
                //EmptyMimeEntry(),
                MultipartBodyStart(boundary),
            ]

            let nEncodings = encodings.count
            for nParts in 1...(nEncodings * 2) {
                var mimeEntries = mimeEntriesBase
                for i in 0..<nParts {
                    let encoding = encodings[i % nEncodings]
                    let partHeader: [MimeEntry] = [
                        PlainHeaderField("Content-Type: text/plain; charset=UTF-8"),
                        PlainHeaderField("Content-Transfer-Encoding: \(encoding)"),
                        EmptyMimeEntry(),
                    ]
                    mimeEntries += partHeader + [
                        bodyLine(i, encoding: encoding),
                        i == nParts - 1 ? MultipartBodyEnd(boundary) : MultipartBodyBoundary(boundary),
                    ]
                }
                for eol in ["\n", "\r\n"] {
                    let mime = (mimeEntries.map { $0.text(eol: eol) }).joined()
                    let mimeParser = MimeParser(from: mime)
                    let mimeArchive = MyAssertNoThrow(try mimeParser.parse(), "Failed to parse", file: #file, line: #line, initVal: nil)
                    XCTAssertNotNil(mimeArchive)
                    XCTAssertEqual(mimeArchive!.subResources.count, nParts)
                    for (i, subResource) in mimeArchive!.subResources.enumerated() {
                        XCTAssertEqual(subResource.body, Data(bodyLineText(i).utf8))
                    }
                }
            }
        }
    }

    func testParseTestFiles() throws {
        struct TestFile {
            let fileName: String
            let nMultipartParts: Int
        }
        let testFiles: [TestFile] = [
            TestFile(fileName: "BasicMhtml", nMultipartParts: 1),
            TestFile(fileName: "MultipartEmail", nMultipartParts: 2),
            //TestFile(fileName: "NestedMultipartsEmail", nMultipartParts: 1),
            TestFile(fileName: "SimpleMessage", nMultipartParts: 0),
        ]

        for testFile in testFiles {
            let filePath = try MyAssertNotNil(
                Bundle.module.url(forResource: testFile.fileName, withExtension: "txt"),
                "Failed to get file URL", file: #file, line: #line)
            let mimeParser = try MyAssertNotNil(
                MimeParser(for: filePath),
                "Failed to get instantiate MimeParser", file: #file, line: #line)
            XCTAssertNotNil(mimeParser)
            let mimeArchive = MyAssertNoThrow(try mimeParser.parse(), "Failed to parse", file: #file, line: #line, initVal: nil)
            XCTAssertNotNil(mimeArchive)
            XCTAssertEqual(mimeArchive!.subResources.count, testFile.nMultipartParts)
        }
    }
}
