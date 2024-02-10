# MimeParser
A Swift package for basic parsing of mime files, enough to work with mhtml files.

Note: at this point in time the parser does not support all the details of the mime specification(s), e.g.
- It doesn't fully validate header fields
- It doesn't handle nested multipart bodies
- It doesn't support weird character in header field names

## Usage Example
To parse a Mime file:
```
guard let mimeParser = MimeParser(for: fileURL) else {
    // handle failure
}
let mimeArchive = try mimeParser.parse()
```
See `MimeArchive.swift` for the structure of the returned parsed archive.

To parse a Mime string:
```
let mimeParser = MimeParser(from: string)
let mimeArchive = try mimeParser.parse()
```
