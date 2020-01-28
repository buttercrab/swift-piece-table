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
    func testExample() {
        let table = PieceTable()
        var s = ""
        let timer1 = Timer(title: "String Operation")
        let timer2 = Timer(title: "PieceTable Operation")
        let iterationCount = 10000
        for _ in 0..<iterationCount {
            let pos = Int.random(in: 0...s.count)
            let t = randomString(length: 6)
            timer1.start()
            s.insert(contentsOf: t, at: s.index(s.startIndex, offsetBy: pos))
            timer1.pause()
            timer2.start()
            try! table.write(content: t, from: pos)
            timer2.pause()
        }
        print("string: \(timer1.time / Double(iterationCount) * 1e6) us")
        print("piece:  \(timer2.time / Double(iterationCount) * 1e6) us")
        XCTAssertEqual(table.content, s)
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
