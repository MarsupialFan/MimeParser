//
//  MimeParser.swift
//
//
//  Created by Adi Ofer on 1/23/24.
//
//
// Ref:
//   - https://datatracker.ietf.org/doc/html/rfc5322#section-2.1
//   - https://datatracker.ietf.org/doc/html/rfc5322#section-3.5
//   - https://datatracker.ietf.org/doc/html/rfc2046#section-5.1.1
//
//  General mime specification
// ----------------------------
//
//  message         =   (fields / obs-fields)
//                      [CRLF body]
//
//  body            =   (*(*998text CRLF) *998text) / obs-body
//
//  text            =   %d1-9 /            ; Characters excluding CR
//                      %d11 /             ;  and LF
//                      %d12 /
//                      %d14-127
//
//  Multipart body specification
// ------------------------------
//
// dash-boundary := "--" boundary
//                  ; boundary taken from the value of
//                  ; boundary parameter of the
//                  ; Content-Type field.
//
// multipart-body := [preamble CRLF]
//                   dash-boundary transport-padding CRLF
//                   body-part *encapsulation
//                   close-delimiter transport-padding
//                   [CRLF epilogue]
// transport-padding := *LWSP-char
//                      ; Composers MUST NOT generate
//                      ; non-zero length transport
//                      ; padding, but receivers MUST
//                      ; be able to handle padding
//                      ; added by message transports.
//
// encapsulation := delimiter transport-padding
//                  CRLF body-part
//
// delimiter := CRLF dash-boundary
//
// close-delimiter := delimiter "--"
//
// preamble := discard-text
//
// epilogue := discard-text
//
// discard-text := *(*text CRLF) *text
//                 ; May be ignored or discarded.
//
// body-part := MIME-part-headers [CRLF *OCTET]
//              ; Lines in a body-part must not start
//              ; with the specified dash-boundary and
//              ; the delimiter must not appear anywhere
//              ; in the body part.  Note that the
//              ; semantics of a body-part differ from
//              ; the semantics of a message, as
//              ; described in the text.
//
// OCTET := <any 0-255 octet value>
//

import Foundation
import os

let logger = Logger(subsystem: "com.adi.MimeParser", category: "MimeParser")


enum MimeParserError: Error {
    case missingDocumentHeader
    case missingPartHeader
    case bodyConversionFailure
    case decodingFailure
    case unsupportedEncodingScheme
    case missingBoundaryInMultipartDocument
}


public class MimeParser {
    let mimeReader: MimeReader

    //
    // Init with the contents of a file
    //
    public init?(for fileURL: URL) {
        do {
            let content = try String(contentsOf: fileURL)
            mimeReader = MimeReader(from: content)
        } catch {
            logger.error("Failed to read content of file \(fileURL.path()) (error: \(error.localizedDescription))")
            return nil
        }
    }

    //
    // Init with the contents of a string
    //
    public init(from mimeString: String) {
        mimeReader = MimeReader(from: mimeString)
    }


    //
    // Decode 'str' using 'encoding'
    //
    private func decode(_ str: String, with encoding: Header.ContentTransferEncoding) throws -> String {
        switch encoding {
        case .base64:
            guard let encodedData = Data(base64Encoded: str, options: .ignoreUnknownCharacters) else {
                logger.error("\(#function): failed to covert to Data")
                throw MimeParserError.bodyConversionFailure
            }
            guard let decodedBody = String(data: encodedData, encoding: .ascii) else {
                logger.error("\(#function): failed to base64-decode")
                throw MimeParserError.decodingFailure
            }
            return decodedBody
        case .quotedPrintable:
            guard let decodedBody = str.decodeQuotedPrintable() else {
                logger.error("\(#function): failed to QuotedPrintable-decode")
                throw MimeParserError.decodingFailure
            }
            return decodedBody
        case .passThrough:
            return str
        case .other:
            logger.error("\(#function): unsupported encoding scheme")
            throw MimeParserError.unsupportedEncodingScheme
        }
    }


    let mimeVersionRegex = #/^M(IME|ime)-Version:\s+(.+)\s*$/#
    let contentTypeRegex = #/^Content-Type:\s+"?(\w+)\/(\w+)"?(.*)\s*$/#
    let boundaryRegex = #/boundary="([^"]+)"/#
    let contentTransferEncodingRegex = #/^Content-Transfer-Encoding:\s+(.+)\s*$/#
    let contentLocationRegex = #/^(Snapshot-)?Content-Location:\s+(.+)\s*$/#

    //
    // Parse an expected header
    //
    // Note: We don't fully check the validity of the mime format --- there
    //       can be duplicate field (e.g. "MIME-Version") definitions. Rather,
    //       in the case of duplicates we sloppily take either the first one
    //       or the last one, depending on the field.
    //
    private func parseHeader(isDocumentHeader: Bool) throws -> Header? {
        var mimeVersion: String? = nil
        var contentType: String? = nil
        var contentSubtype: String? = nil
        var boundary: String? = nil
        var contentTransferEncoding: String? = nil
        var contentLocation: String? = nil

        guard let headerFields = try mimeReader.readHeader() else {
            return nil
        }
        for headerField in headerFields {
            // Check for a mime version header field
            if mimeVersion == nil {
                if let match = headerField.wholeMatch(of: mimeVersionRegex) {
                    mimeVersion = String(match.2)
                    continue
                }
            }
            
            // Check for content type header field
            if let match = headerField.wholeMatch(of: contentTypeRegex) {
                (contentType, contentSubtype) = (String(match.1), String(match.2))
                if isDocumentHeader {
                    if let boundaryMatch = headerField.firstMatch(of: boundaryRegex) {
                        boundary = String(boundaryMatch.1)
                    }
                }
                continue
            }
            
            // Check for content transfer encoding
            if let match = headerField.wholeMatch(of: contentTransferEncodingRegex) {
                contentTransferEncoding = String(match.1)
                continue
            }
            
            // Check for content location header field
            if let match = headerField.wholeMatch(of: contentLocationRegex) {
                contentLocation = String(match.2)
                continue
            }
        }

        let header = isDocumentHeader ?
            DocumentHeader(mimeVersion: mimeVersion, contentType: contentType, contentSubtype: contentSubtype,
                       boundary: boundary, contentLocation: contentLocation, contentEncoding: contentTransferEncoding) :
            SectionHeader(mimeVersion: mimeVersion, contentType: contentType, contentSubtype: contentSubtype,
                          boundary: boundary, contentLocation: contentLocation, contentEncoding: contentTransferEncoding)
        
        return header
    }


    //
    // Parse an expected body
    //
    private func parseBody(with encoding: Header.ContentTransferEncoding) throws -> String {
        // Read the encoded body into a string
        let encodedBody = try String(mimeReader.readBody())

        return try decode(encodedBody, with: encoding)
    }


    //
    // Parse a multipart body
    //
    private func parseMultipartBody(boundary: String) throws -> [MimeArchiveResource] {
        try mimeReader.skipToMultipartBodyStart(boundary: boundary)

        // Parse the parts
        var parts: [MimeArchiveResource] = []  // return value
        while true {
            // Parse the part's header
            guard let partHeader = try parseHeader(isDocumentHeader: false) else {
                logger.error("\(#function): part header not found")
                throw MimeParserError.missingPartHeader
            }

            // Parse the part's body
            let (partBody, isClosingDelimiter) = try mimeReader.readPartBody(boundary: boundary)
            let decodedBody = try decode(String(partBody), with: partHeader.contentTransferEncoding)

            parts.append(MimeArchiveResource(header: partHeader, body: Data(decodedBody.utf8)))
            if isClosingDelimiter {
                break
            }
        }

        return parts
    }


    //
    // Top-level parse function
    //
    public func parse() throws -> MimeArchive {
        // Parse the header of the archive
        guard let header = try parseHeader(isDocumentHeader: true) else {
            logger.error("\(#function): document header not found, aborting...")
            throw MimeParserError.missingDocumentHeader
        }

        // Handle single/multi part archives differently
        if header.isMultipartHeader() {
            let mainArchiveResource = MimeArchiveResource(header: header, body: Data("".utf8))
            guard let boundary = header.boundary else {
                logger.error("\(#function): missing boundary in multipart document, aborting...")
                throw MimeParserError.missingBoundaryInMultipartDocument
            }
            let subResources = try parseMultipartBody(boundary: boundary)
            return MimeArchive(mainResource: mainArchiveResource, subResources: subResources)
        } else {
            let body = try parseBody(with: header.contentTransferEncoding)
            let mainArchiveResource = MimeArchiveResource(header: header, body: Data(body.utf8))
            return MimeArchive(mainResource: mainArchiveResource, subResources: [])
        }
    }
}
