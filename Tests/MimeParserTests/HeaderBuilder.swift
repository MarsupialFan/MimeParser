//
//  HeaderBuilder.swift
//
//
//  Created by Adi Ofer on 6/8/24.
//

import Foundation


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

func addEndOfHeaderMarker(_ headerFields: [MimeEntry]) -> [MimeEntry] {
    return headerFields + [EmptyMimeEntry()]
}
