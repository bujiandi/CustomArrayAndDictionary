import Foundation

class OArray<Element> : CollectionType, Indexable, SequenceType, MutableCollectionType, _DestructorSafeContainer, ArrayLiteralConvertible {
    
    private var _count:Int = 0
    private var _capacity:Int = 10
    private var _minimumCapacity:Int = 10
    private var _pointer:UnsafeMutablePointer<Element>
    
    /// Construct an empty Array.
    init() {
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
    
    required init(capacity: Int) {
        _capacity = capacity
        _minimumCapacity = capacity
        _pointer = UnsafeMutablePointer<Element>.alloc(_capacity)
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
            return _pointer.advancedBy(index).memory
        }
        set {
            //            if index >= _count {
            //                fatalError("index(\(index)) out of count(\(_count))")
            //            }
            _pointer.advancedBy(index).memory = newValue
        }
    }
    
    
    /// A type that can represent a sub-range of an `Array`.
    //    typealias SubSlice = ArraySlice<Element>
    //    subscript (subRange: Range<Int>) -> SubSlice {
    //
    //    }
    required init(arrayLiteral elements: Element...) {
        _capacity = elements.count
        _minimumCapacity = _capacity
        
        _pointer = UnsafeMutablePointer<Element>.alloc(_capacity)
        for var i:Int = 0; i<_capacity; i++ {
            _pointer.advancedBy(i).initialize(elements[elements.startIndex])
        }
    }
}


extension OArray  {
    
    
    /// The number of elements the Array stores.
    var count: Int { return _count }
    
    /// The number of elements the `Array` can store without reallocation.
    var capacity: Int { return _capacity }
    
    /// Reserve enough space to store `minimumCapacity` elements.
    ///
    /// - Postcondition: `capacity >= minimumCapacity` and the array has
    ///   mutable contiguous storage.
    ///
    /// - Complexity: O(`count`).
    func reserveCapacity(minimumCapacity: Int) {
        _minimumCapacity = minimumCapacity
        if _capacity >= minimumCapacity && _count < _minimumCapacity {
            resizeUnsafeCapacity(minimumCapacity)
        } else if _capacity < minimumCapacity {
            resizeUnsafeCapacity(minimumCapacity)
        }
    }
    
    private func resizeUnsafeCapacity(minimumCapacity: Int) {
        let pointer = UnsafeMutablePointer<Element>.alloc(minimumCapacity)
        pointer.moveInitializeBackwardFrom(_pointer, count: _count)
        _pointer.dealloc(_capacity)
        _pointer = pointer
        _capacity = minimumCapacity
    }
    
    
    /// Append `newElement` to the Array.
    ///
    /// - Complexity: Amortized O(1) unless `self`'s storage is shared with another live array; O(`count`) if `self` does not wrap a bridged `NSArray`; otherwise the efficiency is unspecified..
    func append(newElement: Element) {
        if _count == _capacity {
            resizeUnsafeCapacity(Int(Double(_count) * 1.6) + 1)
        }
        _pointer.advancedBy(_count++).initialize(newElement)
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
    
    /// Insert `newElement` at index `i`.
    ///
    /// - Requires: `i <= count`.
    ///
    /// - Complexity: O(`count`).
    func insert(newElement: Element, atIndex i: Int) {
        
    }
    
    /// Remove and return the element at index `i`.
    ///
    /// Invalidates all indices with respect to `self`.
    ///
    /// - Complexity: O(`count`).
    func removeAtIndex(index: Int) -> Element {
        return _pointer.memory
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
    
    /// A textual representation of `self`.
    var description: String {
        return ""
    }
    
    /// A textual representation of `self`, suitable for debugging.
    var debugDescription: String {
        return description
    }
}
