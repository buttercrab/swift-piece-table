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

class Timer {
    private var title: String
    private var lastStart: Double
    private var _time: Double
    private var isRunning: Bool
    public var time: Double {
        _time + (isRunning ? Double(CFAbsoluteTimeGetCurrent() - lastStart) : 0)
    }

    public init(title: String = "") {
        self.title = title
        lastStart = 0
        _time = 0
        isRunning = false
    }

    public func start() {
        if isRunning == false {
            lastStart = CFAbsoluteTimeGetCurrent()
            isRunning = true
        }
    }

    public func pause() {
        if isRunning == true {
            let timeElapsed = CFAbsoluteTimeGetCurrent() - lastStart
            _time += Double(timeElapsed)
            isRunning = false
        }
    }

    public func printTime() {
        print("timer \(title): \(_time)")
    }
}

final class PieceTableTests: XCTestCase {
    var table = PieceTable()
    var s = ""
    let iterationCount = 1000
    let stringCount = 20

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testInsert() {
        s = ""
        table = PieceTable()
        for _ in 0..<iterationCount {
            let pos = Int.random(in: 0...s.count)
            let t = randomString(length: stringCount)
            s.insert(contentsOf: t, at: s.index(s.startIndex, offsetBy: pos))
            try! table.write(content: t, from: pos)
        }
        XCTAssertEqual(table.content, s)
    }

    func testInsertPerformance() {
        table = PieceTable()
        measure {
            for _ in 0..<iterationCount {
                let pos = Int.random(in: 0...self.table.count)
                let t = randomString(length: self.stringCount)
                try! self.table.write(content: t, from: pos)
            }
        }
    }

    func testDelete() {
        s = ""
        table = PieceTable()
        for _ in 0..<iterationCount {
            let pos = Int.random(in: 0...s.count)
            let t = randomString(length: stringCount)
            s.insert(contentsOf: t, at: s.index(s.startIndex, offsetBy: pos))
            try! table.write(content: t, from: pos)
        }

        for _ in 0..<iterationCount {
            var pos = Int.random(in: 0...s.count - stringCount)
            let start = s.index(s.startIndex, offsetBy: pos)
            let end = s.index(start, offsetBy: stringCount)
            s.removeSubrange(start..<end)
            try! table.delete(pos..<pos + stringCount)

            pos = Int.random(in: 0...s.count)
            let t = randomString(length: stringCount)
            s.insert(contentsOf: t, at: s.index(s.startIndex, offsetBy: pos))
            try! table.write(content: t, from: pos)
        }
    }

    static var allTests = [
        ("testInsert", testInsert),
        ("testInsertPerformance", testInsertPerformance),
        ("testDelete", testDelete),
    ]
}
