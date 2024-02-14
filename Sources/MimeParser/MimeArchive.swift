//
//  MimeArchive.swift
//
//
//  Created by Adi Ofer on 1/23/24.
//

import Foundation

//
// Represents one section/file/part (header + non-multipart body) of a mime archive
//
public class MimeArchiveResource {
    public let header: Header
    public let body: Data

    init(header: Header, body: Data) {
        self.header = header
        self.body = body
    }
}

//
// In-memory representation of a mime archive
//
public class MimeArchive {
    public let mainResource: MimeArchiveResource
    public var subResources: [MimeArchiveResource]  // For multipart mime archives

    init(mainResource: MimeArchiveResource, subResources: [MimeArchiveResource] = []) {
        self.mainResource = mainResource
        self.subResources = subResources
    }

    func addSubresource(_ subresource: MimeArchiveResource) {
        self.subResources.append(subresource)
    }
}
