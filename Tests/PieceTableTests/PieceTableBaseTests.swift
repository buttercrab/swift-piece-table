@testable import PieceTable
import XCTest

func randomUnicodeCharacter() -> String {
    let i = arc4random_uniform(1_114_111)
    return (i > 55295 && i < 57344) ? randomUnicodeCharacter() : String(UnicodeScalar(i)!)
}

func randomString(length: Int) -> String {
    var res = ""
    let list = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    for _ in 0..<length {
        res += String(list.randomElement()!)
//        res += randomUnicodeCharacter()
    }
    return res
}

final class PieceTableTests: XCTestCase {
    var table = PieceTableBase()
    var s = ""
    let iterationCount = 100
    let stringCount = 200

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testInsert() {
        s = ""
        table = PieceTableBase()
        for _ in 0..<iterationCount {
            let pos = Int.random(in: 0...s.count)
            let t = randomString(length: stringCount)
            s.insert(contentsOf: t, at: s.index(s.startIndex, offsetBy: pos))
            table.insert(t, at: pos)
            XCTAssert(table.checkValid())
        }
        XCTAssertEqual(table.content, s)
    }

    func testInsertPerformance() {
        table = PieceTableBase()
        measure {
            for _ in 0..<iterationCount {
                let pos = Int.random(in: 0...self.table.count)
                let t = randomString(length: self.stringCount)
                self.table.insert(t, at: pos)
            }
        }
    }

    func testRemove() {
        s = ""
        table = PieceTableBase()
        for _ in 0..<iterationCount {
            let pos = Int.random(in: 0...s.count)
            let t = randomString(length: stringCount)
            s.insert(contentsOf: t, at: s.index(s.startIndex, offsetBy: pos))
            table.insert(t, at: pos)
        }

        for _ in 0..<iterationCount {
            var pos = Int.random(in: 0...s.count - stringCount)
            let start = s.index(s.startIndex, offsetBy: pos)
            let end = s.index(start, offsetBy: stringCount)
            s.removeSubrange(start..<end)
            table.removeSubrange(pos..<pos + stringCount)

            pos = Int.random(in: 0...s.count)
            let t = randomString(length: stringCount)
            s.insert(contentsOf: t, at: s.index(s.startIndex, offsetBy: pos))
            table.insert(t, at: pos)
        }
//        XCTAssertEqual(table.content, s)
    }

    static var allTests = [
        ("testInsert", testInsert),
        ("testInsertPerformance", testInsertPerformance),
        ("testRemove", testRemove),
    ]
}
