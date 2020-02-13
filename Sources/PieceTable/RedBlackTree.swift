public protocol Measurable {
    var count: Int { get }
}

public class RedBlackTreeNode<Element: Equatable & Measurable> {
    fileprivate var _value: Element
    public var value: Element {
        get {
            self._value
        }
    }

    /// count contains size of subtree and color
    /// `count = (size << 1) + color`
    /// color
    ///  - 0: black
    ///  - 1: red
    fileprivate var _count: Int
    public var count: Int {
        get {
            self._count >> 1
        }
    }

    fileprivate var color: Int {
        get {
            self._count & 1
        }

        // assert: val is 0 or 1
        set(val) {
            self._count = _count & ~1 | val
        }
    }

    fileprivate var left: RedBlackTreeNode?
    fileprivate var right: RedBlackTreeNode?
    fileprivate weak var parent: RedBlackTreeNode?

    public init(value: Element, left: RedBlackTreeNode?, right: RedBlackTreeNode?, parent: RedBlackTreeNode?) {
        self._value = value
        self._count = 3 // (1 << 1) + 1
        self.left = left
        self.right = right
        self.parent = parent

        self.left?.parent = self
        self.right?.parent = self
    }

    public convenience init(value: Element) {
        self.init(value: value, left: nil, right: nil, parent: nil)
    }
}

/// Equatable extension
extension RedBlackTreeNode: Equatable {
    public static func ==(lhs: RedBlackTreeNode, rhs: RedBlackTreeNode) -> Bool {
        lhs._value == rhs._value
    }
}

/// Node update for count
extension RedBlackTreeNode {
    fileprivate func update() {
        let count = (self.left?.count ?? 0) + (self.right?.count ?? 0) + self.value.count
        self._count = count << 1 + self._count & 1
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
    public var position: Int {
        get {
            var res = self.left?.count ?? 0
            var n = self

            while true {
                guard let parent = n.parent else {
                    break
                }
                if parent.right == n {
                    res += (parent.left?.count ?? 0) + parent.value.count
                }
                n = parent
            }

            return res
        }
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

public class RedBlackTree<Element: Equatable & Measurable> {
    public typealias Node = RedBlackTreeNode<Element>

    private var root: Node?
    private var _count: Int
    public var count: Int {
        get {
            self._count
        }
    }

    public init() {
        self._count = 0
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

        a._count = n._count
        n.update()

        if p == nil {
            self.root = a
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

        a._count = n._count
        n.update()

        if p == nil {
            self.root = a
        }
    }
}

extension RedBlackTree {
    private func findOrLast(_ position: inout Int) -> Node? {
        guard var n = self.root else {
            return nil
        }

        while true {
            let k = n.left?.count ?? 0

            if k < position {
                if let right = n.right {
                    position -= k + n.value.count
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

    public func findContains(position: Int) -> Node? {
        guard var n = self.root else {
            return nil
        }
        var pos = position

        while true {
            let k = n.left?.count ?? 0

            if k <= pos && pos < k + n.value.count {
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
                    pos -= k + n.value.count
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
        while n != self.root {
            let p = n.parent!
            if p.color == 0 {
                break
            }

            let u = self.siblingNode(p)
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
                    self.leftRotate(p)
                    self.rightRotate(g)
                    g.color = 1
                    n.color = 0
                } else {
                    self.rightRotate(g)
                    g.color = 1
                    p.color = 0
                }
            } else {
                if p.left == n {
                    self.rightRotate(p)
                    self.leftRotate(g)
                    g.color = 1
                    n.color = 0
                } else {
                    self.leftRotate(g)
                    g.color = 1
                    p.color = 0
                }
            }
            break
        }

        self.root?.color = 0
    }

    private func balanceAfterErase(_ n: Node) {
        var n = n
        while n != self.root {
            let p = n.parent!

            if n == p.left {
                let s = p.right
                let l = s?.left
                let r = s?.right

                if r?.color == 1 {
                    self.leftRotate(p)
                    r?.color = 0
                    s?.color = p.color
                    p.color = 1
                    break
                }
                if l?.color == 1 {
                    self.rightRotate(s!)
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
                    self.leftRotate(p)
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
                    self.rightRotate(p)
                    l?.color = 0
                    s?.color = p.color
                    p.color = 1
                    break
                }
                if r?.color == 1 {
                    self.leftRotate(s!)
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
                    self.rightRotate(p)
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
        self._count += 1
        var position = position
        let new = Node(value: value)
        guard let last = self.findOrLast(&position) else {
            self.root = new
            self.root?.color = 0
            return new
        }

        if position == 0 {
            last.left = new
        } else {
            last.right = new
        }
        new.parent = last
        new.updateToTop()

        self.balanceAfterInsert(new)
        return new
    }

    public func erase(_ node: Node) {
        if self._count == 0 {
            return
        }
        self._count -= 1
        if self._count == 0 {
            self.root = nil
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
            if child?.color ?? 0 == 0 && last.color == 0 {
                self.balanceAfterErase(last)
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
            self.root = child
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
        get {
            self.root?.min()
        }
    }

    public var endNode: Node? {
        get {
            self.root?.max()
        }
    }
}

extension RedBlackTree: Sequence {
    public class Iterator: IteratorProtocol {
        public typealias Node = RedBlackTreeNode<Element>

        private var _value: Node?
        public var value: Node? {
            get {
                self._value
            }
        }

        public init(_ value: Node?) {
            self._value = value
        }

        public func next() -> Element? {
            defer {
                self._value = self._value?.next()
            }
            return self._value?.value
        }
    }

    public func makeIterator() -> Iterator {
        Iterator(self.startNode)
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

        let a = self._checkValid(node.left)
        let b = self._checkValid(node.right)

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
        self._checkValid(self.root).0
    }
}