@testable import PieceTable
import XCTest

class IntWrap: Measurable {
    let weight: Int

    init(_ weight: Int) {
        self.weight = weight
    }
}

final class RedBlackTreeTests: XCTestCase {
    var tree = RedBlackTree<IntWrap>()
    let iterationCount = 1000
    let numberLimit = 10000

    func testInsert() {
        tree = RedBlackTree()
        var sum = 0
        for _ in 0..<iterationCount {
            let t = Int.random(in: 1...numberLimit)
            sum += t
            _ = tree.insert(IntWrap(t), at: Int.random(in: 0..<sum));
            assert(tree.checkValid())
        }
    }

    func testInsertPerformance() {
        tree = RedBlackTree()
        var sum = 0
        measure {
            for _ in 0..<iterationCount {
                let t = Int.random(in: 1...numberLimit)
                sum += t
                _ = tree.insert(IntWrap(t), at: Int.random(in: 0..<sum));
            }
        }
    }

    func testRemove() {
        tree = RedBlackTree()
        var sum = 0
        for _ in 0..<iterationCount {
            let t = Int.random(in: 1...numberLimit)
            sum += t
            _ = tree.insert(IntWrap(t), at: Int.random(in: 0..<sum));
            assert(tree.checkValid())
        }

        for _ in 0..<iterationCount {
            var t = Int.random(in: 0..<min(numberLimit, sum - 1))
            sum -= t
            tree.remove(tree.findByWeight(position: t)!)
            assert(tree.checkValid())
            t = Int.random(in: 1...numberLimit)
            sum += t
            _ = tree.insert(IntWrap(t), at: Int.random(in: 0..<sum));
            assert(tree.checkValid())
        }
    }

    static var allTests = [
        ("testInsert", testInsert),
        ("testInsertPerformance", testInsertPerformance),
        ("testRemove", testRemove),
    ]
}
