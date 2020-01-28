import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    [
        testCase(PieceTableTests.allTests),
    ]
}
#endif
