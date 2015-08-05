import Foundation

class OArray<Element> : CollectionType, Indexable, SequenceType, MutableCollectionType, _DestructorSafeContainer {
    
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
    
    /// Construct from an arbitrary sequence with elements of type `Element`.
    init<S : SequenceType where S.Generator.Element == Element>(_ s: S) {
        _pointer = UnsafeMutablePointer<Element>.alloc(_capacity)
        var generate = s.generate()
        while let element:Element = generate.next() {
            self.append(element)
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
        _pointer.destroy(_count)
        _pointer.dealloc(_capacity)
        _pointer = nil
    }
    
    /// Always zero, which is the index of the first element when non-empty.
    var startIndex: Int { return 0 }
    
    /// A "past-the-end" element index; the successor of the last valid
    /// subscript argument.
    var endIndex: Int { return _count - 1 }
    
    subscript (index: Int) -> Element {
        get {
//            if index >= _count {
//                fatalError("index(\(index)) out of count(\(_count))")
//            }
            return _pointer.advancedBy(_offset + index).memory
        }
        set {
//            if index >= _count {
//                fatalError("index(\(index)) out of count(\(_count))")
//            }
            _pointer.advancedBy(_offset + index).memory = newValue
        }
    }
    
    
    /// A type that can represent a sub-range of an `Array`.
//    typealias SubSlice = ArraySlice<Element>
//    subscript (subRange: Range<Int>) -> SubSlice {
//
//    }
}


extension OArray :  RangeReplaceableCollectionType, ArrayLiteralConvertible {
    
    
    /// The number of elements the Array stores.
    var count: Int { return _count }
    
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
        var generate = newElements.generate()
        while let element:Element = generate.next() {
            self.append(element)
        }
    }
    
    /// Append the elements of `newElements` to `self`.
    ///
    /// - Complexity: O(*length of result*).
    func extend<C : CollectionType where C.Generator.Element == Element>(newElements: C) {
        for element in newElements {
            append(element)
        }
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
        _pointer.destroy(_count)
        if !keepCapacity {
            _pointer.dealloc(_capacity)
            _capacity = _minimumCapacity
            _pointer = UnsafeMutablePointer<Element>.alloc(_capacity)
        }
    }
    
    func replaceRange<C : CollectionType where C.Generator.Element == Element>(subRange: Range<Int>, with newElements: C) {
        if subRange.endIndex >= _count {
            fatalError("can't replaceRange because subRange out of range")
        }
        var elements:Array<Element> = Array<Element>(newElements)
        if elements.count == subRange.count {
            for var i:Int = subRange.startIndex; i<subRange.endIndex; i++ {
                _pointer.advancedBy(_offset + i).memory = elements[i - subRange.startIndex]
            }
        } else {
            _capacity = _count + elements.count - subRange.count
            print("_capacity:\(_capacity)")
            let pointer = UnsafeMutablePointer<Element>.alloc(_capacity)
            if subRange.startIndex > 0 { pointer.moveInitializeBackwardFrom(_pointer.advancedBy(_offset), count: subRange.startIndex) }
            for var i:Int = subRange.startIndex; i<subRange.endIndex; i++ {
                print("i:\(i) index:\(i - subRange.startIndex)")
                pointer.advancedBy(i).initialize(elements[i - subRange.startIndex])
            }
            if subRange.endIndex < _count - 1 { pointer.advancedBy(subRange.endIndex).moveInitializeBackwardFrom(_pointer.advancedBy(_offset + subRange.endIndex + 1), count: _count - subRange.endIndex - 1) }
            _count = _capacity
            _offset = 0
        }
//        if newElements.count == subRange.count {
//            
//        }
//        let length:Int = subRange.count
//        let newLength:Int = distance(newElements.startIndex, newElements.endIndex)
//        let length:Int = distance(newElements.startIndex, newElements.endIndex)
//        if length == subRange.count {
//            
//        }
    }
    
    /// Interpose `self` between each consecutive pair of `elements`,
    /// and concatenate the elements of the resulting sequence.  For
    /// example, `[-1, -2].join([[1, 2, 3], [4, 5, 6], [7, 8, 9]])`
    /// yields `[1, 2, 3, -1, -2, 4, 5, 6, -1, -2, 7, 8, 9]`.
    func join<S : SequenceType where S.Generator.Element == Array<Element>>(elements: S) -> [Element] {
        return []
    }
}

//extension OArray : _Reflectable {
//    
//    func getMirror() -> MirrorType {
//        return _reflect(self)
//    }
//}

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
