public protocol Measurable {
    var weight: Int { get }
}

public class RedBlackTreeNode<Element: Measurable> {
    fileprivate var _value: Element
    public var value: Element {
        _value
    }

    /// node count of subtree
    fileprivate var _count: Int

    fileprivate var count: Int {
        get {
            _count &>> 1
        }

        set {
            _count = _count & 1 &+ newValue &<< 1
        }
    }

    /// color of node
    fileprivate var color: Int {
        get {
            _count & 1
        }

        // assert: val is 0 or 1
        set {
            _count = _count & ~1 | newValue
        }
    }

    /// contains total weight of subtree
    fileprivate var weight: Int

    fileprivate var left: RedBlackTreeNode?
    fileprivate var right: RedBlackTreeNode?
    fileprivate weak var parent: RedBlackTreeNode?

    public init(_ value: Element, left: RedBlackTreeNode?, right: RedBlackTreeNode?, parent: RedBlackTreeNode?) {
        _value = value
        _count = 3 // 1 << 1 + 1
        weight = value.weight
        self.left = left
        self.right = right
        self.parent = parent

        self.left?.parent = self
        self.right?.parent = self
    }

    public convenience init(value: Element) {
        self.init(value, left: nil, right: nil, parent: nil)
    }
}

/// Equatable extension
extension RedBlackTreeNode: Equatable {
    public static func ==(lhs: RedBlackTreeNode, rhs: RedBlackTreeNode) -> Bool {
        lhs === rhs
    }
}

/// Node update for count
extension RedBlackTreeNode {
    fileprivate func update() {
        weight = (left?.weight ?? 0) &+ (right?.weight ?? 0) &+ value.weight
        count = (left?.count ?? 0) &+ (right?.count ?? 0) &+ 1
    }

    fileprivate func updateToTop() {
        var i: RedBlackTreeNode<Element>? = self
        while let cur = i {
            cur.update()
            i = cur.parent
        }
    }
}

/// Minimum and Maximum
extension RedBlackTreeNode {
    fileprivate func min() -> RedBlackTreeNode {
        var tmp = self
        while let left = tmp.left {
            tmp = left
        }
        return tmp
    }

    fileprivate func max() -> RedBlackTreeNode {
        var tmp = self
        while let right = tmp.right {
            tmp = right
        }
        return tmp
    }
}

extension RedBlackTreeNode {
    public var positionByWeight: Int {
        var res = left?.weight ?? 0
        var n = self

        while true {
            guard let parent = n.parent else {
                break
            }
            if parent.right == n {
                res += (parent.left?.weight ?? 0) + parent.value.weight
            }
            n = parent
        }

        return res
    }

    public var positionByCount: Int {
        var res = left?.count ?? 0
        var n = self

        while true {
            guard let parent = n.parent else {
                break
            }
            if parent.right == n {
                res += (parent.left?.count ?? 0) + 1
            }
            n = parent
        }

        return res
    }

    public var position: (Int, Int) {
        var res = (left?.count ?? 0, left?.weight ?? 0)
        var n = self

        while true {
            guard let parent = n.parent else {
                break
            }
            if parent.right == n {
                res.0 += (parent.left?.count ?? 0) + 1
                res.1 += (parent.left?.weight ?? 0) + parent.value.weight
            }
            n = parent
        }

        return res
    }
}

/// Iterable extension
extension RedBlackTreeNode {
    public func prev() -> RedBlackTreeNode? {
        if let left = self.left {
            return left.max()
        }

        var n = self

        while let parent = n.parent {
            if parent.right == n {
                return parent
            }
            n = parent
        }

        return nil
    }

    public func next() -> RedBlackTreeNode? {
        if let right = self.right {
            return right.min()
        }

        var n = self

        while let parent = n.parent {
            if parent.left == n {
                return parent
            }
            n = parent
        }

        return nil
    }
}

public class RedBlackTree<Element: Measurable> {
    public typealias Node = RedBlackTreeNode<Element>

    private var root: Node?
    private var _count: Int = 0
    public var count: Int {
        _count
    }
}

/// Rotation in tree
extension RedBlackTree {
    /// Left Rotation
    ///
    ///   p            p
    ///   |            |
    ///   n            a
    ///  / \    =>    / \
    /// x   a        n   y
    ///    / \      / \
    ///   b   y    x   b
    ///
    /// `a` must not be nil

    private func leftRotate(_ n: Node) {
        guard let a = n.right else {
            return
        }
        let p = n.parent, b = a.left
        n.right = b
        a.left = n
        p?.left == n ? (p?.left = a) : (p?.right = a)
        a.parent = p
        n.parent = a
        b?.parent = n

        a.count = n.count
        a.weight = n.weight
        n.update()

        if p == nil {
            root = a
        }
    }

    /// Right Rotation
    ///
    ///     p        p
    ///     |        |
    ///     n        a
    ///    / \  =>  / \
    ///   a   y    x   n
    ///  / \          / \
    /// x   b        b   y
    ///
    /// `a` must not be null

    private func rightRotate(_ n: Node) {
        guard let a = n.left else {
            return
        }
        let p = n.parent, b = a.right
        n.left = b
        a.right = n
        p?.left == n ? (p?.left = a) : (p?.right = a)
        a.parent = p
        n.parent = a
        b?.parent = n

        a.count = n.count
        a.weight = n.weight
        n.update()

        if p == nil {
            root = a
        }
    }
}

extension RedBlackTree {
    private func findOrLastByWeight(_ position: inout Int) -> Node? {
        guard var n = root else {
            return nil
        }

        while true {
            let k = n.left?.weight ?? 0

            if k < position {
                if let right = n.right {
                    position -= k + n.value.weight
                    n = right
                } else {
                    return n
                }
            } else {
                if let left = n.left {
                    n = left
                } else {
                    return n
                }
            }
        }
    }

    public func findByWeight(position: Int) -> Node? {
        guard var n = root else {
            return nil
        }
        var pos = position

        while true {
            let k = n.left?.weight ?? 0

            if k <= pos, pos < k + n.value.weight {
                return n
            }
            if pos < k {
                if let left = n.left {
                    n = left
                } else {
                    return nil
                }
            } else {
                if let right = n.right {
                    pos -= k + n.value.weight
                    n = right
                } else {
                    return nil
                }
            }
        }
    }

    public func findByCount(position: Int) -> Node? {
        guard var n = root else {
            return nil
        }
        var pos = position

        while true {
            let k = n.left?.count ?? 0

            if k == pos {
                return n
            }
            if pos < k {
                if let left = n.left {
                    n = left
                } else {
                    return nil
                }
            } else {
                if let right = n.right {
                    pos -= k + 1
                    n = right
                } else {
                    return nil
                }
            }
        }
    }
}

extension RedBlackTree {
    @inline(__always)
    private func siblingNode(_ n: Node) -> Node? {
        n.parent?.left == n ? n.parent?.right : n.parent?.left
    }

    private func balanceAfterInsert(_ n: Node) {
        var n = n
        while n != root {
            let p = n.parent!
            if p.color == 0 {
                break
            }

            let u = siblingNode(p)
            let g = p.parent!

            if u?.color == 1 {
                u?.color = 0
                p.color = 0
                g.color = 1
                n = g
                continue
            }

            if g.left == p {
                if p.right == n {
                    leftRotate(p)
                    rightRotate(g)
                    g.color = 1
                    n.color = 0
                } else {
                    rightRotate(g)
                    g.color = 1
                    p.color = 0
                }
            } else {
                if p.left == n {
                    rightRotate(p)
                    leftRotate(g)
                    g.color = 1
                    n.color = 0
                } else {
                    leftRotate(g)
                    g.color = 1
                    p.color = 0
                }
            }
            break
        }

        root?.color = 0
    }

    private func balanceAfterErase(_ n: Node) {
        var n = n
        while n != root {
            let p = n.parent!

            if n == p.left {
                let s = p.right
                let l = s?.left
                let r = s?.right

                if r?.color == 1 {
                    leftRotate(p)
                    r?.color = 0
                    s?.color = p.color
                    p.color = 1
                    break
                }
                if l?.color == 1 {
                    rightRotate(s!)
                    s?.color = 1
                    l?.color = 0
                    continue
                }
                if p.color == 1 {
                    p.color = 0
                    s?.color = 1
                    break
                }
                if s?.color == 1 {
                    leftRotate(p)
                    p.color = 1
                    s?.color = 0
                    continue
                }
                s?.color = 1
                n = p
            } else {
                let s = p.left
                let l = s?.left
                let r = s?.right

                if l?.color == 1 {
                    rightRotate(p)
                    l?.color = 0
                    s?.color = p.color
                    p.color = 1
                    break
                }
                if r?.color == 1 {
                    leftRotate(s!)
                    s?.color = 1
                    r?.color = 0
                    continue
                }
                if p.color == 1 {
                    p.color = 0
                    s?.color = 1
                    break
                }
                if s?.color == 1 {
                    rightRotate(p)
                    p.color = 1
                    s?.color = 0
                    continue
                }
                s?.color = 1
                n = p
            }
        }
    }
}

extension RedBlackTree {
    public func insert(position: Int, value: Element) -> Node {
        _count += 1
        var position = position
        let new = Node(value: value)
        guard let last = findOrLastByWeight(&position) else {
            root = new
            root?.color = 0
            return new
        }

        if position == 0 {
            last.left = new
        } else {
            last.right = new
        }
        new.parent = last
        new.updateToTop()

        balanceAfterInsert(new)
        return new
    }

    public func erase(_ node: Node) {
        if _count == 0 {
            return
        }
        _count -= 1
        if _count == 0 {
            root = nil
            return
        }

        let last: Node
        if var right = node.right {
            while let left = right.left {
                right = left
            }
            swap(&right._value, &node._value)
            right.updateToTop()
            last = right
        } else {
            last = node
        }
        let child = last.left ?? last.right

        if let parent = last.parent {
            if child?.color ?? 0 == 0, last.color == 0 {
                balanceAfterErase(last)
            } else {
                child?.color = 0
            }

            if parent.left == last {
                parent.left = child
            } else {
                parent.right = child
            }
            child?.parent = parent
            parent.updateToTop()
        } else {
            root = child
            child?.parent = nil
            child?.color = 0
        }

        last.parent = nil
        last.left = nil
        last.right = nil
    }
}

extension RedBlackTree {
    public var startNode: Node? {
        root?.min()
    }

    public var endNode: Node? {
        root?.max()
    }
}

extension RedBlackTree: Collection {
    public typealias Index = Int

    public var startIndex: Index {
        0
    }

    public var endIndex: Index {
        count
    }

    public subscript(i: Index) -> Element {
        findByCount(position: i)!.value
    }

    public func index(after i: Index) -> Index {
        i + 1
    }
}

extension RedBlackTree: Sequence {
    public class Iterator: IteratorProtocol {
        public typealias Node = RedBlackTreeNode<Element>

        private var _value: Node?
        public var value: Node? {
            _value
        }

        public init(_ value: Node?) {
            _value = value
        }

        public func next() -> Element? {
            defer {
                self._value = self._value?.next()
            }
            return _value?.value
        }
    }

    public func makeIterator() -> Iterator {
        Iterator(startNode)
    }
}

extension RedBlackTree {
    private func _checkValid(_ node: Node?) -> (Bool, Int) {
        guard let node = node else {
            return (true, 0)
        }

        if node.parent?.color == 1 && node.color == 1 {
            return (false, 0)
        }

        let a = _checkValid(node.left)
        let b = _checkValid(node.right)

        if !a.0 || !b.0 {
            return (false, 0)
        }

        if a.1 != b.1 {
            return (false, 0)
        }

        if node.color == 0 {
            return (true, a.1 + 1)
        } else {
            return (true, a.1)
        }
    }

    public func checkValid() -> Bool {
        _checkValid(root).0
    }
}
