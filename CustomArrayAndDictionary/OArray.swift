import Foundation

func +<Element, S : SequenceType where S.Generator.Element == Element>(lhs: OArray<Element>, rhs: S) -> OArray<Element> {
    let array = OArray<Element>(lhs)
    array.extend(rhs)
    return array
}

func +<Element, C : CollectionType where C.Generator.Element == Element>(lhs: OArray<Element>, rhs: C) -> OArray<Element> {
    let array = OArray<Element>(lhs)
    array.extend(rhs)
    return array
}

func +=<Element, S : SequenceType where S.Generator.Element == Element>(inout lhs: OArray<Element>, rhs: S) {
    lhs.extend(rhs)
}

/// Extend `lhs` with the elements of `rhs`.
func +=<Element, C : CollectionType where C.Generator.Element == Element>(inout lhs: OArray<Element>, rhs: C) {
    lhs.extend(rhs)
}

class OArray<Element> : ArrayLiteralConvertible, _DestructorSafeContainer {
    
    typealias Index = Int
    
    private var _offset:Int = 0     // 元素起始位置偏移
    private var _count:Int = 0      // 元素实际数量
    private var _capacity:Int = 10  // 数组已分配空间数量
    private var _minimumCapacity:Int = 10
    private var _pointer:UnsafeMutablePointer<Element>
    private var _slice:Bool = false
    
    /// ArrayLiteralConvertible
    required init(arrayLiteral elements: Element...) {
        _count = elements.count
        _capacity = _count == 0 ? _capacity : _count
        _minimumCapacity = _capacity
        _pointer = UnsafeMutablePointer<Element>.alloc(_capacity)
        for var i:Int = 0; i<_count; i++ {
            _pointer.advancedBy(i).initialize(elements[elements.startIndex.advancedBy(i)])
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
    
    deinit {
        _releaseBuffer(0, oldCapacity: _capacity)
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
            if index > _count {
                fatalError("index(\(index)) out of count(\(_count))")
            } else if index == _count {
                append(newValue)
            } else {
                _pointer.advancedBy(_offset + index).memory = newValue
            }
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
    
    var last: Element? {
        if _count == 0 { return nil }
        return _pointer.advancedBy(_offset + _count - 1).memory
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
    func map<T>(@noescape transform: (Element) -> T) -> OArray<T> {
        let result:OArray<T> = OArray<T>(capacity: _count)
        for var i:Int = 0; i < _count; i++ {
            result.append(transform(_pointer.advancedBy(_offset + i).memory))
        }
        return result
    }
    
    /// Return an `Array` containing the elements of `self`,
    /// in order, that satisfy the predicate `includeElement`.
    func filter(@noescape includeElement: (Element) -> Bool) -> OArray<Element> {
        let result:OArray<Element> = []
        for var i:Int = 0; i < _count; i++ {
            let item:Element = _pointer.advancedBy(_offset + i).memory
            if includeElement(item) {
                result.append(item)
            }
        }
        return result
    }
    
    /// 利用闭包功能 给数组添加 查找首个符合条件元素 的 方法
    func find(@noescape includeElement: (Element) -> Bool) -> Element? {
        for var i:Int = 0; i<_count; i++ {
            let item = _pointer.advancedBy(_offset + i).memory
            if includeElement(item) {
                return item
            }
        }
        return nil
    }
    
    /// 利用闭包功能 获取数组元素某个属性值的数组
    func map<T>(@noescape transform: (Element) -> T) -> [T] {
        var result:[T] = []
        for item:Element in self {
            result.append(transform(item))
        }
        return result
    }
    
    /// 利用闭包功能 获取符合条件数组元素 相关内容的数组
    func map<T>(@noescape transform: (Element) -> T?) -> [T] {
        var result:[T] = []
        for item:Element in self {
            if let u:T = transform(item) {
                result.append(u)
            }
        }
        return result
    }
}


extension OArray : MutableSliceable, RangeReplaceableCollectionType {
    
    //typealias _Buffer = //_ArrayBufferType
//    var _buffer: _Buffer { return self }
//    func _doCopyToNativeArrayBuffer() -> _ContiguousArrayBuffer<Element> {
//
//    }
    
    var _baseAddressIfContiguous: UnsafeMutablePointer<Element> {
        return _pointer
    }
    
    func splice<S : CollectionType where S.Generator.Element == Generator.Element>(newElements: S, atIndex i: Int) {
        let newElements = OArray<Element>(newElements)
        let length = newElements.count
        if i > _count {
            fatalError("can't insert because index out of range")
        } else if i == 0 && _offset >= length {
            //print("使用普通缓冲")
            _offset -= length
            _pointer.advancedBy(_offset).moveInitializeBackwardFrom(newElements._pointer, count: length)
            _count++
            return
        }
        let oldCapacity = _capacity
        if (_offset + _count + length) > _capacity {
            _capacity = _count + length
        }
        let pointer = UnsafeMutablePointer<Element>.alloc(_capacity)
        if i > 0 { pointer.moveInitializeBackwardFrom(_pointer.advancedBy(_offset), count: i) }
        pointer.advancedBy(i).moveInitializeBackwardFrom(newElements._pointer, count: length)
        for var j:Int = 0; j < length; j++ {
            pointer.advancedBy(i + j).initialize(newElements[j])
        }
        if i < _count { pointer.advancedBy(i + length).moveInitializeBackwardFrom(_pointer.advancedBy(_offset + i), count: _count - i) }
        _releaseBuffer(_capacity, oldCapacity:oldCapacity)
        _count += length
        _pointer = pointer
    }
    
    func removeRange(subRange: Range<OArray.Index>) {
        replaceRange(subRange, with: [])
    }
    
    /// A type that can represent a sub-range of an `Array`.
    typealias SubSlice = OArray<Element>
    subscript (subRange: Range<Int>) -> SubSlice {
        get {
            
            let slice = OArray<Element>(self)
            slice._capacity = _capacity
            slice._offset = _offset + subRange.startIndex
            slice._count = subRange.count
            slice._minimumCapacity = _offset + subRange.endIndex
            slice._pointer = _pointer
            slice._slice = true
            return slice
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
            _resizeUnsafeCapacity(minimumCapacity)
        } else if _capacity < minimumCapacity {
            _resizeUnsafeCapacity(minimumCapacity)
        }
    }
    
    private func _resizeUnsafeCapacity(newCapacity: Int) {
        let pointer = UnsafeMutablePointer<Element>.alloc(newCapacity)
        pointer.moveInitializeBackwardFrom(_pointer.advancedBy(_offset), count: _count)
        _releaseBuffer(newCapacity, oldCapacity:_capacity)
        _pointer = pointer
    }
    
    private func _releaseBuffer(newCapacity: Int, oldCapacity: Int) {
        if !_slice {
            if _count > 0 {
                _pointer.advancedBy(_offset).destroy(_count)
            }
            _pointer.dealloc(oldCapacity)
        }
        _slice = false
        _capacity = newCapacity
        _offset = 0
    }
    
    /// Append `newElement` to the Array.
    ///
    /// - Complexity: Amortized O(1) unless `self`'s storage is shared with another live array; O(`count`) if `self` does not wrap a bridged `NSArray`; otherwise the efficiency is unspecified..
    func append(newElement: Element) {
        if (_offset + _count) == _capacity {
            _resizeUnsafeCapacity(Int(Double(_count) * 1.6) + 1)
        }
        _pointer.advancedBy(_offset + _count++).initialize(newElement)
    }
    
    /// Append the elements of `newElements` to `self`.
    ///
    /// - Complexity: O(*length of result*).
    func extend<S : SequenceType where S.Generator.Element == Element>(newElements: S) {
        let newElements = OArray<Element>(newElements)
        let length = newElements.count
        if (_offset + _count + length) > _capacity {
            _resizeUnsafeCapacity(_count + length)
        }
        _pointer.advancedBy(_offset + _count).moveInitializeBackwardFrom(newElements._pointer, count: length)
        _count += length
    }
    
    /// Append the elements of `newElements` to `self`.
    ///
    /// - Complexity: O(*length of result*).
    func extend<C : CollectionType where C.Generator.Element == Element>(newElements: C) {
        let newElements = OArray<Element>(newElements)
        let length = newElements.count
        if (_offset + _count + length) > _capacity {
            _resizeUnsafeCapacity(_count + length)
        }
        _pointer.advancedBy(_offset + _count).moveInitializeBackwardFrom(newElements._pointer, count: length)
        _count += length
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
        splice([newElement], atIndex: i)
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
        _releaseBuffer(_capacity, oldCapacity:_capacity)
        _pointer = pointer
        _count -= 1
        return element
    }
    
    /// Remove all elements.
    ///
    /// - Postcondition: `capacity == 0` iff `keepCapacity` is `false`.
    ///
    /// - Complexity: O(`self.count`).
    func removeAll(keepCapacity keepCapacity: Bool = false) {
        _pointer.advancedBy(_offset).destroy(_count)
        _count = 0
        if !keepCapacity {
            _releaseBuffer(_minimumCapacity, oldCapacity:_capacity)
            _pointer = UnsafeMutablePointer<Element>.alloc(_capacity)
        }
        _offset = 0
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
        let newElements = OArray<Element>(newElements)
        let length = newElements.count
        if length == subRange.count {
            _pointer.advancedBy(_offset + subRange.startIndex).assignBackwardFrom(newElements._pointer, count: subRange.count)
        } else {
            let newCapacity = _count + length - subRange.count
            let pointer = UnsafeMutablePointer<Element>.alloc(newCapacity)
            if subRange.startIndex > 0 { pointer.moveInitializeBackwardFrom(_pointer.advancedBy(_offset), count: subRange.startIndex) }
            pointer.advancedBy(subRange.startIndex).moveInitializeBackwardFrom(newElements._pointer, count: length)
            if subRange.endIndex < _count {
                pointer.advancedBy(subRange.startIndex + length).moveInitializeBackwardFrom(_pointer.advancedBy(_offset + subRange.endIndex), count: _count - subRange.endIndex)
            }
            _releaseBuffer(newCapacity, oldCapacity:_capacity)
            _count = newCapacity
            _pointer = pointer
        }

    }
    
    /// Interpose `self` between each consecutive pair of `elements`,
    /// and concatenate the elements of the resulting sequence.  For
    /// example, `[-1, -2].join([[1, 2, 3], [4, 5, 6], [7, 8, 9]])`
    /// yields `[1, 2, 3, -1, -2, 4, 5, 6, -1, -2, 7, 8, 9]`.
    func join<S : SequenceType where S.Generator.Element == OArray<Element>>(elements: S) -> OArray<Element> {
        let result:OArray<Element> = []
        var generate = elements.generate()
        while let array = generate.next() {
            result.extend(array)
            result.extend(self)
        }
        return result
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
        return "OArray<\(Element.self)>\(description) count(\(_count))"
    }
}

extension OArray : _Reflectable {
    func _getMirror() -> _MirrorType {
        return _reflect(self)
    }
}

extension OArray {

    /// Call `body(p)`, where `p` is a pointer to the `Array`'s
    /// contiguous storage. If no such storage exists, it is first created.
    ///
    /// Often, the optimizer can eliminate bounds checks within an
    /// array algorithm, but when that fails, invoking the
    /// same algorithm on `body`'s argument lets you trade safety for
    /// speed.
    func withUnsafeBufferPointer<R>(@noescape body: (UnsafeBufferPointer<Element>) -> R) -> R {
        return body(UnsafeBufferPointer<Element>(start: _pointer.advancedBy(_offset), count: _count))
    }
    
    /// Call `body(p)`, where `p` is a pointer to the `Array`'s
    /// mutable contiguous storage. If no such storage exists, it is first created.
    ///
    /// Often, the optimizer can eliminate bounds- and uniqueness-checks
    /// within an array algorithm, but when that fails, invoking the
    /// same algorithm on `body`'s argument lets you trade safety for
    /// speed.
    ///
    /// - Warning: Do not rely on anything about `self` (the `Array`
    ///   that is the target of this method) during the execution of
    ///   `body`: it may not appear to have its correct value.  Instead,
    ///   use only the `UnsafeMutableBufferPointer` argument to `body`.
    func withUnsafeMutableBufferPointer<R>(@noescape body: (inout UnsafeMutableBufferPointer<Element>) -> R) -> R {
        var pointer = UnsafeMutableBufferPointer<Element>(start: _pointer.advancedBy(_offset), count: _count)
        return body(&pointer)
    }
}

/// Returns true if these arrays contain the same elements.
func ==<Element : Equatable>(lhs: OArray<Element>, rhs: OArray<Element>) -> Bool {
    if lhs.count != rhs.count { return false }
    for var i:Int = 0; i<lhs.count; i++ {
        if lhs._pointer.advancedBy(lhs._offset + i).memory != rhs._pointer.advancedBy(rhs._offset + i).memory {
            return false
        }
    }
    return true
}
func !=<Element : Equatable>(lhs: OArray<Element>, rhs: OArray<Element>) -> Bool {
    return !(lhs == rhs)
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
        if offset >= range.count {
            offset = 0
            return nil
        }
        return generator.advancedBy(range.startIndex + offset++).memory
    }
}
