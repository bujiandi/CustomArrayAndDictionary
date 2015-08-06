import Foundation

class OArray<Element> : ArrayLiteralConvertible, _DestructorSafeContainer {
    
    typealias Index = Int
    
    private var _offset:Int = 0
    private var _count:Int = 0
    private var _capacity:Int = 10
    private var _minimumCapacity:Int = 10
    private var _pointer:UnsafeMutablePointer<Element>
    
    /// ArrayLiteralConvertible
    required init(arrayLiteral elements: Element...) {
        _count = elements.count
        _capacity = _count
        _minimumCapacity = _capacity
        _pointer = UnsafeMutablePointer<Element>.alloc(_capacity)
        for var i:Int = 0; i<_capacity; i++ {
            _pointer.advancedBy(i).initialize(elements[advance(elements.startIndex, i)])
        }
    }
    
    init(capacity: Int) {
        _capacity = capacity
        _minimumCapacity = capacity
        _pointer = UnsafeMutablePointer<Element>.alloc(_capacity)
    }
    
    /// Construct an empty Array.
    required init() {
        _pointer = UnsafeMutablePointer<Element>.alloc(_capacity)
    }
    
    
    typealias _Buffer = OArray<Element>
    init(_ buffer: _Buffer) {
        _minimumCapacity = buffer._minimumCapacity
        _capacity = buffer._count
        _count = buffer._count
        _offset = 0
        _pointer = UnsafeMutablePointer<Element>.alloc(_capacity)
        _pointer.moveInitializeBackwardFrom(buffer._pointer.advancedBy(buffer._offset), count: _count)
    }
    /// Construct from an arbitrary sequence with elements of type `Element`.
    init<S : SequenceType where S.Generator.Element == Element>(_ s: S) {
        _pointer = UnsafeMutablePointer<Element>.alloc(_capacity)
        var generate = s.generate()
        while let element:Element = generate.next() {
            append(element)
        }
    }
    
    /// Construct a Array of `count` elements, each initialized to
    /// `repeatedValue`.
    init(count: Int, repeatedValue: Element) {
        _pointer = UnsafeMutablePointer<Element>.alloc(count)
        for var i:Int = 0; i < count; i++ {
            _pointer.advancedBy(i).initialize(repeatedValue)
        }
        _capacity = count
        _count = count
    }
    
    private init(_ pointer:UnsafeMutablePointer<Element>, _ subRange:Range<Int>, _ capacity:Int) {
        _offset = subRange.startIndex
        _count = subRange.count
        _capacity = capacity
        _minimumCapacity = subRange.endIndex
        _pointer = pointer
    }
    
    deinit {
        _pointer.destroy(_count)
        _pointer.dealloc(_capacity)
        _pointer = nil
    }
    
}

extension OArray : MutableCollectionType, CollectionType, Indexable, SequenceType {
    
    typealias Generator = OArrayGenerator<Element>
    
    func generate() -> Generator {
        return OArrayGenerator(_pointer, 0..<_count)
    }
    
    subscript (index: Int) -> Element {
        get {
            if index >= _count {
                fatalError("index(\(index)) out of count(\(_count))")
            }
            return _pointer.advancedBy(_offset + index).memory
        }
        set {
            if index >= _count {
                fatalError("index(\(index)) out of count(\(_count))")
            }
            _pointer.advancedBy(_offset + index).memory = newValue
        }
    }
    
    
    /// Always zero, which is the index of the first element when non-empty.
    var startIndex: Int { return 0 }
    
    /// A "past-the-end" element index; the successor of the last valid
    /// subscript argument.
    var endIndex: Int { return _count - 1 }
    
    /// Returns `true` iff `self` is empty.
    var isEmpty: Bool { return _count == 0 }
    
    /// The number of elements the Array stores.
    var count: Int { return _count }
    
    /// Returns the first element of `self`, or `nil` if `self` is empty.
    var first: Element? {
        if _count == 0 { return nil }
        return _pointer.advancedBy(_offset).memory
    }
    
    /// Return a value less than or equal to the number of elements in
    /// `self`, **nondestructively**.
    ///
    /// - Complexity: O(N).
    func underestimateCount() -> Int { return _count }
    
    /// Return an `Array` containing the results of mapping `transform`
    /// over `self`.
    ///
    /// - Complexity: O(N).
    func map<T>(@noescape transform: (Element) -> T) -> [T] {
        var result:[T] = []
        for var i:Int = 0; i < _count; i++ {
            result.append(transform(_pointer.advancedBy(_offset + i).memory))
        }
        return result
    }
    
    /// Return an `Array` containing the elements of `self`,
    /// in order, that satisfy the predicate `includeElement`.
    func filter(@noescape includeElement: (Element) -> Bool) -> [Element] {
        var result:[Element] = []
        for var i:Int = 0; i < _count; i++ {
            let item:Element = _pointer.advancedBy(_offset + i).memory
            if includeElement(item) {
                result.append(item)
            }
        }
        return result
    }
}

func +<Element> (lhs: OArray<Element>, rhs: Element) -> OArray<Element> {
    lhs.append(rhs)
    return lhs
}

/// Extend `lhs` with the elements of `rhs`.
func +=<Element, S : SequenceType where S.Generator.Element == Element>(inout lhs: OArray<Element>, rhs: S) {
    lhs.extend(rhs)
}

extension OArray : MutableSliceable, RangeReplaceableCollectionType {
    
    var _baseAddressIfContiguous: UnsafeMutablePointer<Element> {
        return _pointer
    }
    
    func splice<S : CollectionType where S.Generator.Element == Generator.Element>(newElements: S, atIndex i: Int) {
        let newElements = [Element](newElements)
        let length = newElements.count
        if i > _count {
            fatalError("can't insert because index out of range")
        } else if i == 0 && _offset > length {
            //print("使用普通缓冲")
            for var j:Int = length - 1; j >= 0; j++ {
                _pointer.advancedBy(--_offset).initialize(newElements[j])
            }
            _count++
            return
        }
        let oldCapacity = _capacity
        if (_offset + _count + length) > _capacity {
            _capacity = _count + length
        }
        let pointer = UnsafeMutablePointer<Element>.alloc(_capacity)
        if i > 0 { pointer.moveInitializeBackwardFrom(_pointer.advancedBy(_offset), count: i) }
        for var j:Int = 0; j < length; j++ {
            pointer.advancedBy(i + j).initialize(newElements[j])
        }
        if i < _count { pointer.advancedBy(i + length).moveInitializeBackwardFrom(_pointer.advancedBy(_offset + i), count: _count - i) }
        _pointer.advancedBy(_offset).destroy(_count)
        _pointer.dealloc(oldCapacity)
        _offset = 0
        _count += length
        _pointer = pointer
    }
    
    func removeRange(subRange: Range<OArray.Index>) {
        replaceRange(subRange, with: [])
    }
    /// A type that can represent a sub-range of an `Array`.
    //typealias SubSequence = OArray<Element>
    typealias SubSlice = OArray<Element>
    subscript (subRange: Range<Int>) -> SubSlice {
        get {
            return OArray<Element>(_pointer, (_offset + subRange.startIndex)..<(_offset + subRange.endIndex), _capacity)
        }
        set {
            replaceRange(subRange, with: newValue)
        }
    }
    /// The number of elements the `Array` can store without reallocation.
    var capacity: Int { return _capacity - _offset }
    
    /// Reserve enough space to store `minimumCapacity` elements.
    ///
    /// - Postcondition: `capacity >= minimumCapacity` and the array has
    ///   mutable contiguous storage.
    ///
    /// - Complexity: O(`count`).
    func reserveCapacity(minimumCapacity: Int) {
        _minimumCapacity = minimumCapacity
        if _capacity >= minimumCapacity && _count < minimumCapacity {
            resizeUnsafeCapacity(minimumCapacity)
        } else if _capacity < minimumCapacity {
            resizeUnsafeCapacity(minimumCapacity)
        }
    }
    
    private func resizeUnsafeCapacity(minimumCapacity: Int) {
        let pointer = UnsafeMutablePointer<Element>.alloc(minimumCapacity)
        pointer.moveInitializeBackwardFrom(_pointer.advancedBy(_offset), count: _count)
        _pointer.dealloc(_capacity)
        _pointer = pointer
        _capacity = minimumCapacity
        _offset = 0
    }
    
    
    /// Append `newElement` to the Array.
    ///
    /// - Complexity: Amortized O(1) unless `self`'s storage is shared with another live array; O(`count`) if `self` does not wrap a bridged `NSArray`; otherwise the efficiency is unspecified..
    func append(newElement: Element) {
        if (_offset + _count) == _capacity {
            resizeUnsafeCapacity(Int(Double(_count) * 1.6) + 1)
        }
        _pointer.advancedBy(_offset + _count++).initialize(newElement)
    }
    
    /// Append the elements of `newElements` to `self`.
    ///
    /// - Complexity: O(*length of result*).
    func extend<S : SequenceType where S.Generator.Element == Element>(newElements: S) {
        let newElements = [Element](newElements)
        if (_offset + _count + newElements.count) > _capacity {
            resizeUnsafeCapacity(_count + newElements.count)
        }
        for var i:Int = 0; i<newElements.count; i++ {
            _pointer.advancedBy(_offset + i).initialize(newElements[i])
        }
        _count += newElements.count
    }
    
    /// Append the elements of `newElements` to `self`.
    ///
    /// - Complexity: O(*length of result*).
    func extend<C : CollectionType where C.Generator.Element == Element>(newElements: C) {
        //extend(newElements)

        let newElements = [Element](newElements)
        if (_offset + _count + newElements.count) > _capacity {
            resizeUnsafeCapacity(_count + newElements.count)
        }
        for var i:Int = 0; i<newElements.count; i++ {
            _pointer.advancedBy(_offset + i).initialize(newElements[i])
        }
        _count += newElements.count
    }
    
    /// Remove an element from the end of the Array in O(1).
    ///
    /// - Requires: `count > 0`.
    func removeLast() -> Element {
        if _count == 0 {
            fatalError("can't remove last because count is zero")
        }
        let lastPointer = _pointer.advancedBy(--_count)
        let element = lastPointer.memory
        lastPointer.destroy()
        return element
    }
    
    func removeFirst() -> Element {
        if _count-- == 0 {
            fatalError("can't remove first because count is zero")
        }
        return _pointer.advancedBy(_offset++).move()
    }
    
    /// Insert `newElement` at index `i`.
    ///
    /// - Requires: `i <= count`.
    ///
    /// - Complexity: O(`count`).
    func insert(newElement: Element, atIndex i: Int) {
        if i > _count {
            fatalError("can't insert because index out of range")
        } else if i == 0 && _offset > 0 {
            //print("使用普通缓冲")
            _pointer.advancedBy(--_offset).initialize(newElement)
             _count++
            return
        }
        let oldCapacity = _capacity
        if (_offset + _count) == _capacity {
            _capacity = Int(Double(_count) * 1.6) + 1
        }
        let pointer = UnsafeMutablePointer<Element>.alloc(_capacity)
        if i > 0 { pointer.moveInitializeBackwardFrom(_pointer.advancedBy(_offset), count: i) }
        pointer.advancedBy(i).initialize(newElement)
        if i < _count { pointer.advancedBy(i + 1).moveInitializeBackwardFrom(_pointer.advancedBy(_offset + i), count: _count - i) }
        _pointer.advancedBy(_offset).destroy(_count++)
        _pointer.dealloc(oldCapacity)
        _offset = 0
        _pointer = pointer
    }
    
    /// Remove and return the element at index `i`.
    ///
    /// Invalidates all indices with respect to `self`.
    ///
    /// - Complexity: O(`count`).
    func removeAtIndex(index: Int) -> Element {
        if index >= _count {
            fatalError("can't insert because index out of range")
        } else if index == 0 {
            return removeFirst()
        } else if index == _count - 1 {
            return removeLast()
        }
        let element = _pointer.advancedBy(_offset + index).memory
        let pointer = UnsafeMutablePointer<Element>.alloc(_capacity)
        if index > 0 { pointer.moveInitializeBackwardFrom(_pointer.advancedBy(_offset), count: index) }
        if index < _count - 1 { pointer.advancedBy(index).moveInitializeBackwardFrom(_pointer.advancedBy(_offset + index + 1), count: _count - index - 1) }
        _pointer.advancedBy(_offset).destroy(_count--)
        _pointer.dealloc(_capacity)
        _offset = 0
        _pointer = pointer

        return element
    }
    
    /// Remove all elements.
    ///
    /// - Postcondition: `capacity == 0` iff `keepCapacity` is `false`.
    ///
    /// - Complexity: O(`self.count`).
    func removeAll(keepCapacity keepCapacity: Bool = false) {
        _pointer.advancedBy(_offset).destroy(_count)
        if !keepCapacity {
            _pointer.dealloc(_capacity)
            _capacity = _minimumCapacity
            _pointer = UnsafeMutablePointer<Element>.alloc(_capacity)
        }
        _offset = 0
        _count = 0
    }
    
    /// Replace the given `subRange` of elements with `newElements`.
    ///
    /// Invalidates all indices with respect to `self`.
    ///
    /// - Complexity: O(`subRange.count`) if
    ///   `subRange.endIndex == self.endIndex` and `isEmpty(newElements)`,
    ///   O(`self.count` + `newElements.count`) otherwise.
    func replaceRange<C : CollectionType where C.Generator.Element == Element>(subRange: Range<Int>, with newElements: C) {
        if subRange.endIndex > _count {
            fatalError("can't replaceRange because subRange out of range")
        }
        var elements:Array<Element> = Array<Element>(newElements)
        if elements.count == subRange.count {
            for var i:Int = subRange.startIndex; i<subRange.endIndex; i++ {
                _pointer.advancedBy(_offset + i).memory = elements[i - subRange.startIndex]
            }
        } else {
            let length = elements.count
            let newCapacity = _count + length - subRange.count
            let pointer = UnsafeMutablePointer<Element>.alloc(newCapacity)
            if subRange.startIndex > 0 { pointer.moveInitializeBackwardFrom(_pointer.advancedBy(_offset), count: subRange.startIndex) }
            for var i:Int = 0; i<length; i++ {
                pointer.advancedBy(i + subRange.startIndex).initialize(elements[i])
            }
            if subRange.endIndex < _count {
                pointer.advancedBy(subRange.startIndex + length).moveInitializeBackwardFrom(_pointer.advancedBy(_offset + subRange.endIndex), count: _count - subRange.endIndex)
            }
            _pointer.advancedBy(_offset).destroy(_count)
            _pointer.dealloc(_capacity)
            _pointer = pointer
            _count = newCapacity
            _capacity = newCapacity
            _offset = 0
        }

    }
    
    /// Interpose `self` between each consecutive pair of `elements`,
    /// and concatenate the elements of the resulting sequence.  For
    /// example, `[-1, -2].join([[1, 2, 3], [4, 5, 6], [7, 8, 9]])`
    /// yields `[1, 2, 3, -1, -2, 4, 5, 6, -1, -2, 7, 8, 9]`.
    func join<S : SequenceType where S.Generator.Element == Array<Element>>(elements: S) -> OArray<Element> {
        return []
    }
    
    /// Return the result of repeatedly calling `combine` with an
    /// accumulated value initialized to `initial` and each element of
    /// `self`, in turn, i.e. return
    /// `combine(combine(...combine(combine(initial, self[0]),
    /// self[1]),...self[count-2]), self[count-1])`.
    func reduce<T>(initial: T, @noescape combine: (T, Element) -> T) -> T {
        return initial
    }
    
    
    func sort(isOrderedBefore: (Element, Element) -> Bool) {
        
    }
}


extension OArray : CustomStringConvertible, CustomDebugStringConvertible {
    
    func componentsJoinedByString(separator: String) -> String {
        var result = ""
        for var i:Int = _offset; i<_count + _offset; i++ {
            if !result.isEmpty {
                result += separator
            }
            result += "\(_pointer.advancedBy(i).memory)"
        }
        return result
    }
    /// A textual representation of `self`.
    var description: String {
        let content = componentsJoinedByString(", ")
        return "[\(content)]"
    }
    
    /// A textual representation of `self`, suitable for debugging.
    var debugDescription: String {
        return "OArray<\(Element.self)>\(description)"
    }
}

extension OArray {
    // 利用闭包功能 给数组添加 查找首个符合条件元素 的 方法
    func find(@noescape includeElement: (Element) -> Bool) -> Element? {
        for var i:Int = 0; i<_count; i++ {
            let item = _pointer.advancedBy(_offset + i).memory
            if includeElement(item) {
                return item
            }
        }
        return nil
    }
    
    // 利用闭包功能 给数组添加 查找首个符合条件元素下标 的 方法
    func indexOf(@noescape includeElement: (Element) -> Bool) -> Int {
        for var i:Int = 0; i<count; i++ {
            if includeElement(self[i]) {
                return i
            }
        }
        return NSNotFound
    }
    
    // 利用闭包功能 获取数组元素某个属性值的数组
    func valuesFor<U>(@noescape includeElement: (Element) -> U) -> [U] {
        var result:[U] = []
        for item:Element in self {
            result.append(includeElement(item))
        }
        return result
    }
    
    // 利用闭包功能 获取符合条件数组元素 相关内容的数组
    func valuesFor<U>(@noescape includeElement: (Element) -> U?) -> [U] {
        var result:[U] = []
        for item:Element in self {
            if let u:U = includeElement(item) {
                result.append(u)
            }
        }
        return result
    }

}

struct OArrayGenerator<Element> : GeneratorType {
    private var generator: UnsafeMutablePointer<Element>
    private var range:Range<Int>
    private var offset:Int
    
    init(_ pointer:UnsafeMutablePointer<Element>, _ subRange:Range<Int>) {
        generator = pointer
        range = subRange
        offset = 0
    }
    
    mutating func next() -> Element? {
        if offset >= range.count { return nil }
        return generator.advancedBy(range.startIndex + offset++).memory
    }
}
