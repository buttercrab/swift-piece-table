public class Piece {
    fileprivate let index: Int
    fileprivate let start: Int, end: Int

    public init(index: Int, start: Int, end: Int) {
        self.index = index
        self.start = start
        self.end = end
    }
}

extension Piece {
    fileprivate var isEmpty: Bool {
        start == end
    }
}

extension Piece: Measurable {
    public var weight: Int {
        end - start
    }
}

extension Piece: Equatable {
    public static func ==(lhs: Piece, rhs: Piece) -> Bool {
        lhs.index == rhs.index && lhs.start == rhs.start && lhs.end == rhs.end
    }
}

extension Piece {
    fileprivate func split(at: Int) -> (Piece, Piece) {
        (Piece(index: index, start: start, end: at), Piece(index: index, start: at, end: end))
    }
}

private class Buffer {
    public typealias Index = (Int, Int)

    public var data = [[Character]]()
    public let bufferSize: Int

    public init(origin: String, bufferSize: Int) {
        self.bufferSize = bufferSize
        _ = append(origin)
    }
}

extension Buffer {
    public func getAllPieces() -> [Piece] {
        var res = [Piece]()
        res.reserveCapacity(data.count)
        for i in 0..<data.count {
            res.append(Piece(index: i, start: data[i].startIndex, end: data[i].endIndex))
        }
        return res
    }

    public func getContent(_ piece: Piece) -> ArraySlice<Character> {
        data[piece.index][piece.start..<piece.end]
    }
}

extension Buffer {
    public func append(_ content: String) -> [Piece] {
        var index = 0
        var res = [Piece]()
        let content = Array(content)

        if let lastCount = data.last?.count {
            let start = lastCount
            let size = min(content.count - index, bufferSize - start)
            data[data.count - 1].append(contentsOf: content[index..<index + size])
            index += size
            res.append(Piece(index: data.count - 1, start: start, end: start + size))
        }

        while index < content.count {
            if data.isEmpty || data.last!.count == bufferSize {
                var arr = [Character]()
                arr.reserveCapacity(bufferSize)
                data.append(arr)
            }

            let start = data.last!.count
            let size = min(content.count - index, bufferSize - start)
            data[data.count - 1].append(contentsOf: content[index..<index + size])
            index += size
            res.append(Piece(index: data.count - 1, start: start, end: start + size))
        }

        return res
    }
}

public class PieceTableBase {
    public typealias Index = Int
    public typealias Element = Character
    fileprivate typealias Node = RedBlackTreeNode<Piece>

    fileprivate var buffer: Buffer
    public var bufferSize: Int {
        buffer.bufferSize
    }

    private var _count: Int = 0
    public var count: Int {
        _count
    }

    public var tree: RedBlackTree<Piece> = RedBlackTree()

    public init(origin: String = "", bufferSize: Int = 64000) {
        buffer = Buffer(origin: origin, bufferSize: bufferSize)
        try! write(content: origin, from: 0)
    }
}

enum IndexError: Error {
    case outOfRange
}

extension PieceTableBase {
    fileprivate func splitNode(node: Node?, pos: Index) -> (Node?, Node?) {
        guard let node = node else {
            return (nil, nil)
        }

        let start = node.positionByWeight
        let (a, b) = node.value.split(at: pos - start + node.value.start)

        if !a.isEmpty, !b.isEmpty {
            tree.erase(node)
            return (tree.insert(position: start, value: a),
                    tree.insert(position: pos, value: b))
        }

        return (nil, nil)
    }

    fileprivate func combineNode(_ node: Node?) -> Node? {
        guard let node = node, let before = node.prev() else {
            return nil
        }

        guard node.value.index == before.value.index, before.value.end == node.value.start else {
            return nil
        }

        let value = Piece(index: node.value.index, start: before.value.start, end: node.value.end)
        let pos = before.positionByWeight
        tree.erase(node)
        tree.erase(before)
        return tree.insert(position: pos, value: value)
    }

    public func write(content: String, from: Index) throws {
        if from < 0 || from > count {
            throw IndexError.outOfRange
        }

        let node = tree.findByWeight(position: from)
        _ = splitNode(node: node, pos: from)
        let pieces = buffer.append(content)

        var index = from
        for piece in pieces {
            _ = combineNode(tree.insert(position: index, value: piece))
            index += piece.weight
        }

        _count += content.count
    }

    public func delete(_ range: Range<Index>) throws {
        let start = range.lowerBound
        let end = start + range.count

        if start < 0 || start > count || end < 0 || end > count {
            throw IndexError.outOfRange
        }

        var startNode = tree.findByWeight(position: start)
        _ = splitNode(node: startNode, pos: start)
        startNode = tree.findByWeight(position: start)
        var endNode = tree.findByWeight(position: end)
        _ = splitNode(node: endNode, pos: end)
        endNode = tree.findByWeight(position: end)

        while let s = startNode, s != endNode {
            let next = s.next()
            tree.erase(s)
            startNode = next
        }
        _ = combineNode(endNode)

        _count -= range.count
    }
}

extension PieceTableBase {
    public var startIndex: Index {
        0
    }

    public var endIndex: Index {
        _count
    }
}

extension PieceTableBase {
    public func find(_ s: String) -> [Index] {
        var res = [Index]()
        var fail = [Int](repeating: 0, count: s.count)
        let s = Array(s)

        var j = 0
        for i in 0..<s.count {
            while j > 0, s[i] != s[j] {
                j = fail[j]
            }
            if s[i] == s[j] {
                j += 1
                fail[i] = j
            }
        }

        var i = 0
        j = 0
        for value in tree {
            for c in buffer.getContent(value) {
                while j > 0, c != s[j] {
                    j = fail[j]
                }
                if c == s[j] {
                    j += 1
                    if j == s.count {
                        res.append(i)
                        j = fail[j]
                    }
                }
                i += 1
            }
        }

        return res
    }
}

extension PieceTableBase {
    public var content: String {
        var res = ""
        for value in tree {
            res += buffer.getContent(value)
        }
        return res
    }
}

public class SubPieceTable {
    private let table: PieceTableBase
    fileprivate let start: PieceTableBase.Index
    fileprivate let end: PieceTableBase.Index

    fileprivate init(table: PieceTableBase, start: PieceTableBase.Index, end: PieceTableBase.Index) {
        self.table = table
        self.start = start
        self.end = end
    }

    public var content: String {
        var res = ""
        guard var startNode = table.tree.findByWeight(position: self.start) else {
            return ""
        }
        let endNode = table.tree.findByWeight(position: end)
        var start = self.start - startNode.value.start

        while startNode != endNode {
            res += table.buffer.data[startNode.value.index][start..<startNode.value.end]
            if let next = startNode.next() {
                startNode = next
                start = 0
            } else {
                break
            }
        }

        if let last = endNode {
            res += table.buffer.data[last.value.index][start..<end - last.value.start]
        }
        return res
    }
}

extension PieceTableBase {
    public subscript(index: Index) -> Character {
        guard let node = tree.findByWeight(position: index) else {
            fatalError("[PieceTable] Index out of range")
        }
        return buffer.getContent(node.value)[index - node.value.start]
    }

    public subscript(range: Range<Index>) -> SubPieceTable {
        let start = range.lowerBound
        let end = start + range.count
        if start < 0 || end > count {
            fatalError("[PieceTable] Index out of range")
        }
        return SubPieceTable(table: self, start: start, end: end)
    }
}

extension PieceTableBase: Sequence {
    public class Iterator: IteratorProtocol {
        public typealias Element = Character

        fileprivate var node: Node?
        fileprivate var index: Index
        fileprivate let table: PieceTableBase

        fileprivate init(node: Node?, index: Index, table: PieceTableBase) {
            self.node = node
            self.index = index
            self.table = table
        }

        public func next() -> Character? {
            defer {
                self.index += 1
                if let node = self.node {
                    if node.value.end == self.index {
                        self.node = node.next()
                    }
                }
            }
            guard let node = self.node else {
                return nil
            }
            return table.buffer.getContent(node.value)[index - node.value.start]
        }
    }

    public func makeIterator() -> Iterator {
        Iterator(node: tree.startNode, index: 0, table: self)
    }
}

private class LineSize {
    private var _count: Int

    init(count: Int) {
        _count = count
    }
}

extension LineSize: Measurable {
    public var weight: Int {
        _count
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
    public func insert(at _: Int) {
    }
}
