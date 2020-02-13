import XCTest
@testable import PieceTable

func randomUnicodeCharacter() -> String {
    let i = arc4random_uniform(1114111)
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
        get {
            _time + (isRunning ? Double(CFAbsoluteTimeGetCurrent() - lastStart) : 0)
        }
    }

    public init(title: String = "") {
        self.title = title
        self.lastStart = 0
        self._time = 0
        self.isRunning = false
    }

    public func start() {
        if self.isRunning == false {
            self.lastStart = CFAbsoluteTimeGetCurrent()
            self.isRunning = true
        }
    }

    public func pause() {
        if self.isRunning == true {
            let timeElapsed = CFAbsoluteTimeGetCurrent() - self.lastStart
            self._time += Double(timeElapsed)
            self.isRunning = false
        }
    }

    public func printTime() {
        print("timer \(self.title): \(self._time)")
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
        self.s = ""
        self.table = PieceTable()
        for _ in 0..<iterationCount {
            let pos = Int.random(in: 0...self.s.count)
            let t = randomString(length: self.stringCount)
            self.s.insert(contentsOf: t, at: self.s.index(self.s.startIndex, offsetBy: pos))
            try! self.table.write(content: t, from: pos)
        }
        XCTAssertEqual(self.table.content, self.s)
    }

    func testInsertPerformance() {
        self.table = PieceTable()
        self.measure {
            for _ in 0..<iterationCount {
                let pos = Int.random(in: 0...self.table.count)
                let t = randomString(length: self.stringCount)
                try! self.table.write(content: t, from: pos)
            }
        }
    }

    func testDelete() {
        self.s = ""
        self.table = PieceTable()
        for _ in 0..<iterationCount {
            let pos = Int.random(in: 0...self.s.count)
            let t = randomString(length: self.stringCount)
            self.s.insert(contentsOf: t, at: self.s.index(self.s.startIndex, offsetBy: pos))
            try! self.table.write(content: t, from: pos)
        }

        for _ in 0..<iterationCount {
            var pos = Int.random(in: 0...self.s.count - self.stringCount)
            let start = self.s.index(self.s.startIndex, offsetBy: pos)
            let end = self.s.index(start, offsetBy: self.stringCount)
            self.s.removeSubrange(start..<end)
            try! self.table.delete(pos..<pos + self.stringCount)

            pos = Int.random(in: 0...self.s.count)
            let t = randomString(length: self.stringCount)
            self.s.insert(contentsOf: t, at: self.s.index(self.s.startIndex, offsetBy: pos))
            try! self.table.write(content: t, from: pos)
        }
    }

    static var allTests = [
        ("testInsert", testInsert),
        ("testInsertPerformance", testInsertPerformance),
        ("testDelete", testDelete),
    ]
}
