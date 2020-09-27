import Foundation

/// Line Size with enter character
private class LineSize {
    private var _weight: Int

    init(_ weight: Int) {
        _weight = weight
    }
}

extension LineSize: Measurable {
    public var weight: Int {
        _weight
    }
}

public class LineHandler {
    private var _count: Int = 0
    public var count: Int {
        _count
    }

    private var lines: IndexedRBTree<LineSize> = IndexedRBTree()

    init() {
    }
}

extension LineHandler {
    public func insertNewLine(_ pos: PieceTableBase.Index) {

    }
}
