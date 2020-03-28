import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    [
        testCase(PieceTableTests.allTests),
        testCase(RedBlackTreeTests.allTests)
    ]
}
#endif
