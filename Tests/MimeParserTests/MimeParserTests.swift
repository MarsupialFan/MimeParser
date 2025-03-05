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

    func testBase64EncodedBody() throws {
        let text = """
            /9j/4AAQSkZJRgABAQEAAAAAAAD/4QBCRXhpZgAATU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAA
            AkAAAAMAAAABAAAAAEABAAEAAAABAAAAAAAAAAAAAP/bAEMACwkJBwkJBwkJCQkLCQkJCQkJCwkL
            CwwLCwsMDRAMEQ4NDgwSGRIlGh0lHRkfHCkpFiU3NTYaKjI+LSkwGTshE//bAEMBBwgICwkLFQsL
            FSwdGR0sLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLP/A
            ABEIAK8ArwMBIgACEQEDEQH/xAAfAAABBQEBAQEBAQAAAAAAAAAAAQIDBAUGBwgJCgv/xAC1EAAC
            AQMDAgQDBQUEBAAAAX0BAgMABBEFEiExQQYTUWEHInEUMoGRoQgjQrHBFVLR8CQzYnKCCQoWFxgZ
            GiUmJygpKjQ1Njc4OTpDREVGR0hJSlNUVVZXWFlaY2RlZmdoaWpzdHV2d3h5eoOEhYaHiImKkpOU
            lZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna4eLj5OXm5+jp6vHy8/T1
            9vf4+fr/xAAfAQADAQEBAQEBAQEBAAAAAAAAAQIDBAUGBwgJCgv/xAC1EQACAQIEBAMEBwUEBAAB
            AncAAQIDEQQFITEGEkFRB2FxEyIygQgUQpGhscEJIzNS8BVictEKFiQ04SXxFxgZGiYnKCkqNTY3
            ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqCg4SFhoeIiYqSk5SVlpeYmZqio6Sl
            pqeoqaqys7S1tre4ubrCw8TFxsfIycrS09TV1tfY2dri4+Tl5ufo6ery8/T19vf4+fr/2gAMAwEA
            AhEDEQA/APXKKK4zxD4gkd5bCxk2xLlLiZDhnYcFEI7ep7/T72NatGjHmkduDwdTGVPZ0/m+xr6l
            4l06xZoov9JuF4ZImAjQ+jScjP0BrmLvxLrF0GUNFDEf4Io1OR7tJk/yrForw6uLqVOtkfdYXJ8N
            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
            """
        let mimeEntries: [MimeEntry] = [
            PlainHeaderField("MIME-Version: 1.0"),
            PlainHeaderField("Content-Type: image/png"),
            PlainHeaderField("Content-Transfer-Encoding: base64"),
            EmptyMimeEntry(),
            BodyEntry(text, encoding: "base64"),
        ]
        for eol in ["\n", "\r\n"] {
            let mime = (mimeEntries.map { $0.text(eol: eol) }).joined()
            let mimeParser = MimeParser(from: mime)
            let mimeArchive = MyAssertNoThrow(try mimeParser.parse(), "Failed to parse", file: #file, line: #line, initVal: nil)
            XCTAssertNotNil(mimeArchive)
            let decodedBody = String(data: mimeArchive!.mainResource.body, encoding: .utf8)
            XCTAssertEqual(decodedBody!, text)
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
            let mimeParser = MyAssertNoThrow(try MimeParser.mimeParserForFile(filePath), initVal: nil)
            XCTAssertNotNil(mimeParser)
            let mimeArchive = MyAssertNoThrow(try mimeParser!.parse(), "Failed to parse", file: #file, line: #line, initVal: nil)
            XCTAssertNotNil(mimeArchive)
            XCTAssertEqual(mimeArchive!.subResources.count, testFile.nMultipartParts)
        }
    }
}
