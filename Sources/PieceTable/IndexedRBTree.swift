/// Measure protocol for getting weight of Element in Red Black Tree
public protocol Measurable {
    var weight: Int { get }
}

// Test Done!
// Correct Red Black Tree
public class IndexedRBTreeNode<Element: Measurable> {
    fileprivate var _value: Element
    public var value: Element {
        _value
    }

    /// node count of subtree
    fileprivate var _count: Int

    fileprivate var count: Int {
        get {
            _count >> 1
        }

        set {
            _count = _count & 1 + newValue << 1
        }
    }

    /// color of node
    /// 0: Black
    /// 1: Red
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

    fileprivate var left: IndexedRBTreeNode?
    fileprivate var right: IndexedRBTreeNode?
    fileprivate weak var parent: IndexedRBTreeNode?

    public init(_ value: Element, left: IndexedRBTreeNode?, right: IndexedRBTreeNode?, parent: IndexedRBTreeNode?) {
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
extension IndexedRBTreeNode: Equatable {
    public static func ==(lhs: IndexedRBTreeNode, rhs: IndexedRBTreeNode) -> Bool {
        lhs === rhs
    }
}

/// Node update for count
extension IndexedRBTreeNode {
    fileprivate func update() {
//        version 1
//        weight = (left?.weight ?? 0) + (right?.weight ?? 0) + value.weight
//        count = (left?.count ?? 0) + (right?.count ?? 0) + 1

//        version 2 - fastest on bench
        if let left = left {
            if let right = right {
                weight = left.weight + right.weight + value.weight
                count = left.count + right.count + 1
            } else {
                weight = left.weight + value.weight
                count = left.count + 1
            }
        } else {
            if let right = right {
                weight = right.weight + value.weight
                count = right.count + 1
            } else {
                weight = value.weight
                count = 1
            }
        }

//        version 3
//        if left == nil {
//            if right == nil {
//                weight = value.weight
//                count = 1
//            } else {
//                weight = right!.weight + value.weight
//                count = right!.count + 1
//            }
//        } else {
//            if right == nil {
//                weight = left!.weight + value.weight
//                count = left!.count + 1
//            } else {
//                weight = left!.weight + right!.weight + value.weight
//                count = left!.count + right!.count + 1
//            }
//        }

//        version 4
//        weight = value.weight
//        count = 1
//
//        if let left = left {
//            weight += left.weight
//            count += left.count
//        }
//
//        if let right = right {
//            weight += right.weight
//            count += right.count
//        }
    }

    fileprivate func updateToTop() {
        var i: IndexedRBTreeNode<Element>? = self
        while let cur = i {
            cur.update()
            i = cur.parent
        }
    }
}

extension IndexedRBTreeNode {
    public func updateValue(_ value: Element) {
        _value = value
        updateToTop()
    }
}

/// Minimum and Maximum
extension IndexedRBTreeNode {
    fileprivate func min() -> IndexedRBTreeNode {
        var tmp = self
        while let left = tmp.left {
            tmp = left
        }
        return tmp
    }

    fileprivate func max() -> IndexedRBTreeNode {
        var tmp = self
        while let right = tmp.right {
            tmp = right
        }
        return tmp
    }
}

extension IndexedRBTreeNode {
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
extension IndexedRBTreeNode {
    public func prev() -> IndexedRBTreeNode? {
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

    public func next() -> IndexedRBTreeNode? {
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

public class IndexedRBTree<Element: Measurable> {
    public typealias Node = IndexedRBTreeNode<Element>

    private var root: Node?
    private var _count: Int = 0
    public var count: Int {
        _count
    }
}

/// Rotation in tree
extension IndexedRBTree {
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

extension IndexedRBTree {
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
                    if pos == k + n.value.weight {
                        return n
                    } else {
                        return nil
                    }
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

extension IndexedRBTree {
    private func balanceAfterInsert(_ n: Node) {
        var n = n
        while n != root {
            let p = n.parent!
            if p.color == 0 {
                break
            }

            let g = p.parent!
            let u = g.left == p ? g.right : g.left

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
                    n.color = 0
                } else {
                    rightRotate(g)
                    p.color = 0
                }
            } else {
                if p.left == n {
                    rightRotate(p)
                    leftRotate(g)
                    n.color = 0
                } else {
                    leftRotate(g)
                    p.color = 0
                }
            }
            g.color = 1
            break
        }

        root?.color = 0
    }

    private func balanceAfterRemove(_ n: Node) {
        var n = n
        while n != root {
            let p = n.parent!

            if n == p.left {
                if let s = p.right {
                    if s.color == 1 {
                        leftRotate(p)
                        p.color = 1
                        s.color = 0
                    } else {
                        let l = s.left
                        let r = s.right

                        if r?.color == 1 {
                            leftRotate(p)
                            r!.color = 0
                            s.color = p.color
                            p.color = 0
                            break
                        }
                        if l?.color == 1 {
                            rightRotate(s)
                            leftRotate(p)
                            l!.color = p.color
                            p.color = 0
                            break
                        }
                        if p.color == 1 {
                            p.color = 0
                            s.color = 1
                            break
                        }
                        s.color = 1
                        n = p
                    }
                } else {
                    if p.color == 0 {
                        n = p
                    } else {
                        p.color = 0
                        break
                    }
                }
            } else {
                if let s = p.left {
                    if s.color == 1 {
                        rightRotate(p)
                        p.color = 1
                        s.color = 0
                    } else {
                        let l = s.left
                        let r = s.right

                        if l?.color == 1 {
                            rightRotate(p)
                            l!.color = 0
                            s.color = p.color
                            p.color = 0
                            break
                        }
                        if r?.color == 1 {
                            leftRotate(s)
                            rightRotate(p)
                            r!.color = p.color
                            p.color = 0
                            break
                        }
                        if p.color == 1 {
                            p.color = 0
                            s.color = 1
                            break
                        }
                        s.color = 1
                        n = p
                    }
                } else {
                    if p.color == 0 {
                        n = p
                    } else {
                        p.color = 0
                        break
                    }
                }
            }
        }
    }
}

extension IndexedRBTree {
    public func insert(_ value: Element, at: Int) -> Node {
        _count += 1
        let new = Node(value: value)
        guard var n = root else {
            new.color = 0
            root = new
            return new
        }

        var at = at
        while true {
            if let left = n.left {
                if left.weight < at {
                    if let right = n.right {
                        at -= left.weight + n.value.weight
                        n = right
                    } else {
                        n.right = new
                        break
                    }
                } else {
                    n = left
                }
            } else {
                if 0 < at {
                    if let right = n.right {
                        at -= n.value.weight
                        n = right
                    } else {
                        n.right = new
                        break
                    }
                } else {
                    n.left = new
                    break
                }
            }
        }

        new.parent = n
        new.updateToTop()

        balanceAfterInsert(new)
        return new
    }

    public func remove(_ node: Node) {
        if _count == 0 {
            return
        }
        _count -= 1
        if _count == 0 {
            root = nil
            return
        }

        let last: Node
        let child: Node?
        if var right = node.right {
            while let left = right.left {
                right = left
            }
            swap(&right._value, &node._value)
            right.updateToTop()
            last = right
            child = last.right
        } else {
            last = node
            child = last.left
        }

        if let parent = last.parent {
            if child?.color ?? 0 == 0, last.color == 0 {
                balanceAfterRemove(last)
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
            if let c = child {
                c.color = 0
                c.parent = nil
                root = c
            } else {
                root = nil
            }
        }

        last.parent = nil
        last.left = nil
        last.right = nil
    }
}

extension IndexedRBTree {
    public var startNode: Node? {
        root?.min()
    }

    public var endNode: Node? {
        root?.max()
    }
}

extension IndexedRBTree: Collection {
    public typealias Index = Int

    public var startIndex: Index {
        0
    }

    public var endIndex: Index {
        count
    }

    public subscript(i: Index) -> Element {
        get {
            findByCount(position: i)!.value
        }

        set {
            findByCount(position: i)!.updateValue(newValue)
        }
    }

    public func index(after i: Index) -> Index {
        i + 1
    }
}

extension IndexedRBTree: Sequence {
    public class Iterator: IteratorProtocol {
        public typealias Node = IndexedRBTreeNode<Element>

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

// For debugging
extension IndexedRBTree {
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
