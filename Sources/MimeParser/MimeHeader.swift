//
//  MimeHeader.swift
//
//
//  Created by Adi Ofer on 1/23/24.
//

import Foundation

public class Header {
    enum ContentTransferEncoding {
        case passThrough      // no encoding; this is the default value
        case quotedPrintable
        case base64
        case other
    }

    let mimeVersion: String?
    let contentType: String
    let contentSubtype: String
    let boundary: String?
    let contentLocation: String?
    let contentTransferEncoding: ContentTransferEncoding

    static let multipartHeaderType = "multipart"

    fileprivate init?(mimeVersion: String?, contentType: String?, contentSubtype: String?, boundary: String?, contentLocation: String?, contentEncoding: String?) {
        self.mimeVersion = mimeVersion

        guard contentType != nil else {
            logger.error("\(#function): Missing content type")
            return nil
        }
        self.contentType = contentType!

        guard contentSubtype != nil else {
            logger.error("\(#function): Missing content subtype")
            return nil
        }
        self.contentSubtype = contentSubtype!

        self.boundary = boundary

        self.contentLocation = contentLocation

        let encoding = contentEncoding ?? "7bit"  // "7bit" is the default value
        switch encoding.lowercased() {
        case "base64":
            self.contentTransferEncoding = .base64
        case "quoted-printable":
            self.contentTransferEncoding = .quotedPrintable
        case "8bit": fallthrough
        case "7bit": fallthrough
        case "binary":
            self.contentTransferEncoding = .passThrough
        default:
            self.contentTransferEncoding = .other
        }
    }

    func isMultipartHeader() -> Bool {
        return self.contentType == Header.multipartHeaderType
    }
}


//
// Represents the first header in the Mime archive
//
class DocumentHeader: Header {
    override init?(mimeVersion: String?, contentType: String?, contentSubtype: String?, boundary: String?, contentLocation: String?, contentEncoding: String?) {
        super.init(mimeVersion: mimeVersion, contentType: contentType, contentSubtype: contentSubtype,
                   boundary: boundary, contentLocation: contentLocation, contentEncoding: contentEncoding)

        // Mime version must be specified
        guard self.mimeVersion != nil else {
            logger.error("\(#function): Missing Mime version")
            return nil
        }

        if isMultipartHeader() {
            // Multipart headers must specify a boundary string
            guard self.boundary != nil else {
                logger.error("\(#function): Missing boundary definition for multipart MIME")
                return nil
            }
            // Multipart headers must have passthrough content transfer encoding
            guard self.contentTransferEncoding == .passThrough else {
                logger.error("\(#function): Illegal content transfer encoding for multipart document header")
                return nil
            }
        }
    }
}


//
// Represents all headers other than the first one in the Mime archive
// (i.e. in the case of a multipart Mime archive)
//
class SectionHeader: Header {
    override init?(mimeVersion: String?, contentType: String?, contentSubtype: String?, boundary: String?, contentLocation: String?, contentEncoding: String?) {
        super.init(mimeVersion: mimeVersion, contentType: contentType, contentSubtype: contentSubtype,
                   boundary: boundary, contentLocation: contentLocation, contentEncoding: contentEncoding)

        // Only the document header is allowed to be of multipart content type
        guard !isMultipartHeader() else {
            logger.error("\(#function): Unexpected multipart type in section")
            return nil
        }
    }
}
