public class Piece: Measurable {
    fileprivate let index: Int
    fileprivate let start: Int, end: Int
    public var count: Int {
        get {
            end - start
        }
    }

    public init(index: Int, start: Int, end: Int) {
        self.index = index
        self.start = start
        self.end = end
    }
}

extension Piece {
    fileprivate var isEmpty: Bool {
        get {
            self.start == self.end
        }
    }
}

extension Piece: Equatable {
    public static func ==(lhs: Piece, rhs: Piece) -> Bool {
        lhs.index == rhs.index && lhs.start == rhs.start && lhs.end == rhs.end
    }
}

extension Piece {
    fileprivate func split(at: Int) -> (Piece, Piece) {
        (Piece(index: self.index, start: self.start, end: at), Piece(index: self.index, start: at, end: self.end))
    }
}

fileprivate class Buffer {
    public typealias Index = (Int, Int)

    public var data = [[Character]]()
    public let bufferSize: Int

    public init(origin: String, bufferSize: Int) {
        self.bufferSize = bufferSize
        _ = self.append(origin)
    }
}

extension Buffer {
    public func getAllPieces() -> [Piece] {
        var res = [Piece]()
        res.reserveCapacity(self.data.count)
        for i in 0..<self.data.count {
            res.append(Piece(index: i, start: self.data[i].startIndex, end: self.data[i].endIndex))
        }
        return res
    }

    public func getContent(_ piece: Piece) -> ArraySlice<Character> {
        self.data[piece.index][piece.start..<piece.end]
    }
}

extension Buffer {
    public func append(_ content: String) -> [Piece] {
        var index = 0
        var res = [Piece]()
        let content = Array(content)

        if let lastCount = self.data.last?.count {
            let start = lastCount
            let size = min(content.count - index, self.bufferSize - start)
            self.data[self.data.count - 1].append(contentsOf: content[index..<index + size])
            index += size
            res.append(Piece(index: self.data.count - 1, start: start, end: start + size))
        }

        while index < content.count {
            if self.data.isEmpty || self.data.last!.count == self.bufferSize {
                var arr = [Character]()
                arr.reserveCapacity(bufferSize)
                self.data.append(arr)
            }

            let start = self.data.last!.count
            let size = min(content.count - index, self.bufferSize - start)
            self.data[self.data.count - 1].append(contentsOf: content[index..<index + size])
            index += size
            res.append(Piece(index: self.data.count - 1, start: start, end: start + size))
        }

        return res
    }
}

public class PieceTable {
    public typealias Index = Int
    public typealias Element = Character
    fileprivate typealias Node = RedBlackTreeNode<Piece>

    fileprivate var buffer: Buffer
    public var bufferSize: Int {
        get {
            self.buffer.bufferSize
        }
    }

    private var _count: Int = 0
    public var count: Int {
        get {
            self._count
        }
    }

    public var tree: RedBlackTree<Piece> = RedBlackTree()

    public init(origin: String = "", bufferSize: Int = 64_000) {
        self.buffer = Buffer(origin: origin, bufferSize: bufferSize)
        try! self.write(content: origin, from: 0)
    }
}

enum IndexError: Error {
    case outOfRange
}

extension PieceTable {
    fileprivate func splitNode(node: Node?, pos: Index) -> (Node?, Node?) {
        guard let node = node else {
            return (nil, nil)
        }

        let start = node.position
        let (a, b) = node.value.split(at: pos - start + node.value.start)

        if !a.isEmpty && !b.isEmpty {
            self.tree.erase(node)
            return (self.tree.insert(position: start, value: a),
                    self.tree.insert(position: pos, value: b))
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
        let pos = before.position
        self.tree.erase(node)
        self.tree.erase(before)
        return self.tree.insert(position: pos, value: value)
    }

    public func write(content: String, from: Index) throws {
        if from < 0 || from > self.count {
            throw IndexError.outOfRange
        }

        let node = self.tree.findContains(position: from)
        _ = self.splitNode(node: node, pos: from)
        let pieces = self.buffer.append(content)

        var index = from
        for piece in pieces {
            _ = self.combineNode(self.tree.insert(position: index, value: piece))
            index += piece.count
        }

        self._count += content.count
    }

    public func delete(_ range: Range<Index>) throws {
        let start = range.lowerBound
        let end = start + range.count

        if start < 0 || start > self.count || end < 0 || end > self.count {
            throw IndexError.outOfRange
        }

        var startNode = self.tree.findContains(position: start)
        _ = self.splitNode(node: startNode, pos: start)
        startNode = self.tree.findContains(position: start)
        var endNode = self.tree.findContains(position: end)
        _ = self.splitNode(node: endNode, pos: end)
        endNode = self.tree.findContains(position: end)

        while !(startNode == endNode) {
            let next = startNode?.next()
            self.tree.erase(startNode!)
            startNode = next
        }
        _ = self.combineNode(endNode)

        self._count -= range.count
    }
}

extension PieceTable {
    public var startIndex: Index {
        get {
            0
        }
    }

    public var endIndex: Index {
        get {
            self._count
        }
    }
}

extension PieceTable {
    public func find(_ s: String) -> [Index] {
        var res = [Index]()
        var fail = [Int](repeating: 0, count: s.count)
        let s = Array(s)

        var j = 0
        for i in 0..<s.count {
            while j > 0 && s[i] != s[j] {
                j = fail[j]
            }
            if s[i] == s[j] {
                j += 1
                fail[i] = j
            }
        }

        var i = 0
        j = 0
        for value in self.tree {
            for c in self.buffer.getContent(value) {
                while j > 0 && c != s[j] {
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

extension PieceTable {
    public var content: String {
        get {
            var res = ""
            for value in self.tree {
                res += self.buffer.getContent(value)
            }
            return res
        }
    }
}

public class SubPieceTable {
    fileprivate let table: PieceTable
    fileprivate let start: PieceTable.Index
    fileprivate let end: PieceTable.Index

    fileprivate init(table: PieceTable, start: PieceTable.Index, end: PieceTable.Index) {
        self.table = table
        self.start = start
        self.end = end
    }

    public var content: String {
        get {
            var res = ""
            guard var startNode = self.table.tree.findContains(position: self.start) else {
                return ""
            }
            let endNode = self.table.tree.findContains(position: self.end)
            var start = self.start - startNode.value.start

            while startNode != endNode {
                res += self.table.buffer.data[startNode.value.index][start..<startNode.value.end]
                if let next = startNode.next() {
                    startNode = next
                    start = 0
                } else {
                    break
                }
            }

            if let last = endNode {
                res += self.table.buffer.data[last.value.index][start..<self.end - last.value.start]
            }
            return res
        }
    }
}

extension PieceTable {
    public subscript(index: Index) -> Character {
        guard let node = self.tree.findContains(position: index) else {
            fatalError("[PieceTable] Index out of range")
        }
        return self.buffer.getContent(node.value)[index - node.value.start]
    }

    public subscript(range: Range<Index>) -> SubPieceTable {
        let start = range.lowerBound
        let end = start + range.count
        if start < 0 || end > self.count {
            fatalError("[PieceTable] Index out of range")
        }
        return SubPieceTable(table: self, start: start, end: end)
    }
}

extension PieceTable: Sequence {
    public class Iterator: IteratorProtocol {
        public typealias Element = Character

        fileprivate var node: Node?
        fileprivate var index: Index
        fileprivate let table: PieceTable

        fileprivate init(node: Node?, index: Index, table: PieceTable) {
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
            return self.table.buffer.getContent(node.value)[self.index - node.value.start]
        }
    }

    public func makeIterator() -> Iterator {
        Iterator(node: self.tree.startNode, index: 0, table: self)
    }
}