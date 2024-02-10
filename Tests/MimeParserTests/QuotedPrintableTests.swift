//
//  QuotedPrintableTests.swift
//
//
//  Created by Adi Ofer on 1/23/24.
//

import XCTest
@testable import MimeParser

//
// Useful resources:
//    https://dencode.com/string/quoted-printable
//    https://www.kermitproject.org/utf8.html
//
final class QuotedPrintableTests: XCTestCase {
    let loremIpsumPlainLines = [
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore",
        "et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut",
        "aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum",
        "dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui",
        "officia deserunt mollit anim id est laborum."
    ]
    let loremIpsumEncodedLines = [
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tem=",
        "por incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, q=",
        "uis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo cons=",
        "equat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillu=",
        "m dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non pr=",
        "oident, sunt in culpa qui officia deserunt mollit anim id est laborum."
    ]

    func testCRLF() {
        let loremIpsumPlain = loremIpsumPlainLines.joined(separator: " ")
        let loremIpsumEncodedLF = loremIpsumEncodedLines.joined(separator: "\n")
        XCTAssertEqual(loremIpsumEncodedLF.decodeQuotedPrintable(), loremIpsumPlain)
        let loremIpsumEncodedCRLF = loremIpsumEncodedLines.joined(separator: "\r\n")
        XCTAssertEqual(loremIpsumEncodedCRLF.decodeQuotedPrintable(), loremIpsumPlain)
    }

    let odysseusPlain = """
        Τη γλώσσα μου έδωσαν ελληνική
        το σπίτι φτωχικό στις αμμουδιές του Ομήρου.
        Μονάχη έγνοια η γλώσσα μου στις αμμουδιές του Ομήρου.

        από το Άξιον Εστί
        του Οδυσσέα Ελύτη
        """
    let odysseusEncoded = """
        =CE=A4=CE=B7 =CE=B3=CE=BB=CF=8E=CF=83=CF=83=CE=B1 =CE=BC=CE=BF=CF=85 =CE=AD=
        =CE=B4=CF=89=CF=83=CE=B1=CE=BD =CE=B5=CE=BB=CE=BB=CE=B7=CE=BD=CE=B9=CE=BA=
        =CE=AE
        =CF=84=CE=BF =CF=83=CF=80=CE=AF=CF=84=CE=B9 =CF=86=CF=84=CF=89=CF=87=CE=B9=
        =CE=BA=CF=8C =CF=83=CF=84=CE=B9=CF=82 =CE=B1=CE=BC=CE=BC=CE=BF=CF=85=CE=B4=
        =CE=B9=CE=AD=CF=82 =CF=84=CE=BF=CF=85 =CE=9F=CE=BC=CE=AE=CF=81=CE=BF=CF=85.=

        =CE=9C=CE=BF=CE=BD=CE=AC=CF=87=CE=B7 =CE=AD=CE=B3=CE=BD=CE=BF=CE=B9=CE=B1 =
        =CE=B7 =CE=B3=CE=BB=CF=8E=CF=83=CF=83=CE=B1 =CE=BC=CE=BF=CF=85 =CF=83=CF=84=
        =CE=B9=CF=82 =CE=B1=CE=BC=CE=BC=CE=BF=CF=85=CE=B4=CE=B9=CE=AD=CF=82 =CF=84=
        =CE=BF=CF=85 =CE=9F=CE=BC=CE=AE=CF=81=CE=BF=CF=85.

        =CE=B1=CF=80=CF=8C =CF=84=CE=BF =CE=86=CE=BE=CE=B9=CE=BF=CE=BD =CE=95=CF=83=
        =CF=84=CE=AF
        =CF=84=CE=BF=CF=85 =CE=9F=CE=B4=CF=85=CF=83=CF=83=CE=AD=CE=B1 =CE=95=CE=BB=
        =CF=8D=CF=84=CE=B7
        """
    let runePlain = """
        ᚠᛇᚻ᛫ᛒᛦᚦ᛫ᚠᚱᚩᚠᚢᚱ᛫ᚠᛁᚱᚪ᛫ᚷᛖᚻᚹᛦᛚᚳᚢᛗ
        ᛋᚳᛖᚪᛚ᛫ᚦᛖᚪᚻ᛫ᛗᚪᚾᚾᚪ᛫ᚷᛖᚻᚹᛦᛚᚳ᛫ᛗᛁᚳᛚᚢᚾ᛫ᚻᛦᛏ᛫ᛞᚫᛚᚪᚾ
        ᚷᛁᚠ᛫ᚻᛖ᛫ᚹᛁᛚᛖ᛫ᚠᚩᚱ᛫ᛞᚱᛁᚻᛏᚾᛖ᛫ᛞᚩᛗᛖᛋ᛫ᚻᛚᛇᛏᚪᚾ᛬
        """
    let runeEncoded = """
        =E1=9A=A0=E1=9B=87=E1=9A=BB=E1=9B=AB=E1=9B=92=E1=9B=A6=E1=9A=A6=E1=9B=AB=E1=
        =9A=A0=E1=9A=B1=E1=9A=A9=E1=9A=A0=E1=9A=A2=E1=9A=B1=E1=9B=AB=E1=9A=A0=E1=9B=
        =81=E1=9A=B1=E1=9A=AA=E1=9B=AB=E1=9A=B7=E1=9B=96=E1=9A=BB=E1=9A=B9=E1=9B=A6=
        =E1=9B=9A=E1=9A=B3=E1=9A=A2=E1=9B=97
        =E1=9B=8B=E1=9A=B3=E1=9B=96=E1=9A=AA=E1=9B=9A=E1=9B=AB=E1=9A=A6=E1=9B=96=E1=
        =9A=AA=E1=9A=BB=E1=9B=AB=E1=9B=97=E1=9A=AA=E1=9A=BE=E1=9A=BE=E1=9A=AA=E1=9B=
        =AB=E1=9A=B7=E1=9B=96=E1=9A=BB=E1=9A=B9=E1=9B=A6=E1=9B=9A=E1=9A=B3=E1=9B=AB=
        =E1=9B=97=E1=9B=81=E1=9A=B3=E1=9B=9A=E1=9A=A2=E1=9A=BE=E1=9B=AB=E1=9A=BB=E1=
        =9B=A6=E1=9B=8F=E1=9B=AB=E1=9B=9E=E1=9A=AB=E1=9B=9A=E1=9A=AA=E1=9A=BE
        =E1=9A=B7=E1=9B=81=E1=9A=A0=E1=9B=AB=E1=9A=BB=E1=9B=96=E1=9B=AB=E1=9A=B9=E1=
        =9B=81=E1=9B=9A=E1=9B=96=E1=9B=AB=E1=9A=A0=E1=9A=A9=E1=9A=B1=E1=9B=AB=E1=9B=
        =9E=E1=9A=B1=E1=9B=81=E1=9A=BB=E1=9B=8F=E1=9A=BE=E1=9B=96=E1=9B=AB=E1=9B=9E=
        =E1=9A=A9=E1=9B=97=E1=9B=96=E1=9B=8B=E1=9B=AB=E1=9A=BB=E1=9B=9A=E1=9B=87=E1=
        =9B=8F=E1=9A=AA=E1=9A=BE=E1=9B=AC
        """

    func testUnicode() {
        XCTAssertEqual(odysseusEncoded.decodeQuotedPrintable(), odysseusPlain)
        XCTAssertEqual(runeEncoded.decodeQuotedPrintable(), runePlain)
    }
}
