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

private class LineHandler {
    private var _count: Int = 0
    public var count: Int {
        _count
    }

    private var lines: RedBlackTree<LineSize> = RedBlackTree()

    init() {
    }
}

extension LineHandler {
    private func insertLine(position: Int) {
        if let n = lines.findByWeight(position: position) {
            let pos = n.positionByWeight
            if pos != position {
                n.updateValue(LineSize(position - pos))
                _ = lines.insert(LineSize(n.value.weight - position + pos), at: position)
            }
        }
    }

    private func insertContent(position: Int, size: Int) {
        if let n = lines.findByWeight(position: position) {
            n.updateValue(LineSize(n.value.weight + size))
        }
        let n = lines.endNode
        n?.updateValue(LineSize(n?.value.weight ?? 0 + size))
    }

    public func insert(_ content: String, position: Int) {
        var position = position
        var count = 0

        for c in content {
            if c == "\n" {
                insertContent(position: position, size: count)
                position += count
                count = 0
                insertLine(position: position)
                position += 1
            } else {
                count += 1
            }
        }

        if count > 0 {
            insertContent(position: position, size: count)
        }
    }

    public func removeSubrange(_ range: Range<Int>) {
    }
}

extension LineHandler {
    public func getLine(_ i: Int) -> (Int, Int) {
        let n = lines.findByCount(position: i)
        guard let a = n else {
            return (-1, -1)
        }
        let pos = a.positionByWeight;
        return (pos, pos + a.value.weight)
    }
}
