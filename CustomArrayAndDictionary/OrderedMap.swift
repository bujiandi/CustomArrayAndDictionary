//
//  OrderedDictionary.swift
//
//  Created by bujiandi on 15/8/11.
//

import Foundation

public class OrderedMap<Key : Hashable, Value> : CollectionType, Indexable, SequenceType, DictionaryLiteralConvertible {

    private var _pointer:UnsafeMutablePointer<Int>
    private var _keys:ContiguousArray<Key>
    private var _values:ContiguousArray<Value>
    private var _count:Int = 0
    private var _offset:Int = 0
    private var _capacity:Int = 10
    private var _minimumCapacity:Int = 10
    private var _slice:Bool = false

    
    public typealias Element = (Key, Value)
    public typealias Index = MapIndex<Key, Value>
    /// Create an empty dictionary.
    public convenience init() {
        self.init(minimumCapacity:10)
    }
    /// Create a dictionary with at least the given number of
    /// elements worth of storage.  The actual capacity will be the
    /// smallest power of 2 that's >= `minimumCapacity`.
    public init(minimumCapacity: Int) {
        _capacity = minimumCapacity
        _minimumCapacity = minimumCapacity
        _keys = ContiguousArray<Key>()
        _keys.reserveCapacity(minimumCapacity)
        _values = ContiguousArray<Value>()
        _values.reserveCapacity(minimumCapacity)
        _pointer = UnsafeMutablePointer<Int>.alloc(minimumCapacity)
    }
    /// The position of the first element in a non-empty dictionary.
    ///
    /// Identical to `endIndex` in an empty dictionary.
    ///
    /// - Complexity: Amortized O(1) if `self` does not wrap a bridged
    ///   `NSDictionary`, O(N) otherwise.
    public var startIndex: Index {
        return MapIndex<Key, Value>(rawValue: 0)
    }
    /// The collection's "past the end" position.
    ///
    /// `endIndex` is not a valid argument to `subscript`, and is always
    /// reachable from `startIndex` by zero or more applications of
    /// `successor()`.
    ///
    /// - Complexity: Amortized O(1) if `self` does not wrap a bridged
    ///   `NSDictionary`, O(N) otherwise.
    public var endIndex: Index { return MapIndex<Key, Value>(rawValue: _count - 1) }
    /// Returns the `Index` for the given key, or `nil` if the key is not
    /// present in the dictionary.
    public func indexForKey(key: Key) -> Index? {
        let hasValue = key.hashValue
        for var i:Int = 0; i < _count; i++ {
            if _pointer.advancedBy(_offset + i).memory == hasValue { return MapIndex<Key, Value>(rawValue: i) }
        }
        return nil
    }
    public subscript (position: Index) -> (Key, Value) {
        get {
            let position = position.rawValue
            if position >= _count {
                fatalError("position(\(position)) out of count(\(_count))")
            }
            return (_keys[position], _values[position])
        }
        set {
            let position = position.rawValue
            if position > _count {
                fatalError("position(\(position)) out of count(\(_count))")
            } else if position == _count {
                putValue(newValue.1, forKey: newValue.0)
            } else {
                _pointer.advancedBy(_offset + position).memory = newValue.0.hashValue
                _keys[position] = newValue.0
                _values[position] = newValue.1
            }
        }
    }
    public subscript (key: Key) -> Value? {
        get {
            if let position = indexForKey(key) {
                return _values[position.rawValue]
            }
            return nil
        }
        set {
            if let value = newValue {
                if let position = indexForKey(key) {
                    _values[position.rawValue] = value
                }
            } else {
                if let position = indexForKey(key) {
                    removeAtIndex(position)
                }
            }
        }
    }
    
    public func putValue(value: Value, forKey key: Key) -> Index {
        if (_count + _offset) == _capacity {
            _resizeUnsafeCapacity(Int(Double(_count) * 1.6) + 1)
        }
        _pointer.advancedBy(_offset + _count).initialize(key.hashValue)
        _keys.append(key)
        _values.append(value)
        return MapIndex<Key, Value>(rawValue:_count++)
    }
    /// Update the value stored in the dictionary for the given key, or, if they
    /// key does not exist, add a new key-value pair to the dictionary.
    ///
    /// Returns the value that was replaced, or `nil` if a new key-value pair
    /// was added.
    public func updateValue(value: Value, forKey key: Key) -> Value? {
        if let position = indexForKey(key) {
            let oldValue = _values[position.rawValue]
            _values[position.rawValue] = value
            return oldValue
        }
        putValue(value, forKey: key)
        return nil
    }
    /// Remove the key-value pair at `index`.
    ///
    /// Invalidates all indices with respect to `self`.
    ///
    /// - Complexity: O(`count`).
    public func removeAtIndex(index: Index) -> (Key, Value) {
        let index = index.rawValue
        if index >= _count {
            fatalError("index(\(index)) out of count(\(_count))")
        } else if index == 0 {
            return removeFirst()
        } else if index == _count - 1 {
            return removeLast()
        }
//        let element = _pointer.advancedBy(_offset + index).memory
        let pointer = UnsafeMutablePointer<Int>.alloc(_capacity)
        if index > 0 { pointer.moveInitializeBackwardFrom(_pointer.advancedBy(_offset), count: index) }
        if index < _count - 1 { pointer.advancedBy(index).moveInitializeBackwardFrom(_pointer.advancedBy(_offset + index + 1), count: _count - index - 1) }
        _releaseBuffer(_capacity, oldCapacity:_capacity)
        _pointer = pointer
        _count -= 1
        return (_keys.removeAtIndex(index), _values.removeAtIndex(index))
    }
    
    public func popFirst() -> (Key, Value)? {
        if isEmpty { return nil }
        return removeAtIndex(startIndex)
    }
    /// Remove an element from the end of the Array in O(1).
    ///
    /// - Requires: `count > 0`.
    func removeLast() -> (Key, Value) {
        if _count == 0 {
            fatalError("can't remove last because count is zero")
        }
        let lastPointer = _pointer.advancedBy(--_count)
        lastPointer.destroy()
        return (_keys.removeAtIndex(_count), _values.removeAtIndex(_count))
    }
    
    func removeFirst() -> (Key, Value) {
        if _count-- == 0 {
            fatalError("can't remove first because count is zero")
        }
        _pointer.advancedBy(_offset++).destroy()
        return (_keys.removeAtIndex(0), _values.removeAtIndex(0))
    }
    
    /// Remove a given key and the associated value from the dictionary.
    /// Returns the value that was removed, or `nil` if the key was not present
    /// in the dictionary.
    public func removeValueForKey(key: Key) -> Value? {
        if let position = indexForKey(key) {
            return removeAtIndex(position).1
        }
        return nil
    }
    /// Remove all elements.
    ///
    /// - Postcondition: `capacity == 0` if `keepCapacity` is `false`, otherwise
    ///   the capacity will not be decreased.
    ///
    /// Invalidates all indices with respect to `self`.
    ///
    /// - parameter keepCapacity: If `true`, the operation preserves the
    ///   storage capacity that the collection has, otherwise the underlying
    ///   storage is released.  The default is `false`.
    ///
    /// Complexity: O(`count`).
    public func removeAll(keepCapacity keepCapacity: Bool = false) {
        _pointer.advancedBy(_offset).destroy(_count)
        _count = 0
        if !keepCapacity {
            _releaseBuffer(_minimumCapacity, oldCapacity:_capacity)
            _pointer = UnsafeMutablePointer<Int>.alloc(_capacity)
        }
        _offset = 0
    }
    /// The number of entries in the dictionary.
    ///
    /// - Complexity: O(1).
    public var count: Int {
        return _count
    }
    /// Return a *generator* over the (key, value) pairs.
    ///
    /// - Complexity: O(1).
    public func generate() -> OrderedDictionaryGenerator<Key, Value> {
        return OrderedDictionaryGenerator(self)
    }
    /// Create an instance initialized with `elements`.
    public required init(dictionaryLiteral elements: (Key, Value)...) {
        _capacity = elements.count
        _minimumCapacity = _capacity
        _keys = ContiguousArray<Key>()
        _keys.reserveCapacity(_capacity)
        _values = ContiguousArray<Value>()
        _values.reserveCapacity(_capacity)
        _pointer = UnsafeMutablePointer<Int>.alloc(_capacity)
        for var i:Int = 0; i<_capacity; i++ {
            let element = elements[i]
            _pointer.advancedBy(i).initialize(element.0.hashValue)
            _keys.append(element.0)
            _values.append(element.1)
        }
        _count = _capacity
    }
    
    
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
        let pointer = UnsafeMutablePointer<Int>.alloc(newCapacity)
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
    
    /// A collection containing just the keys of `self`.
    ///
    /// Keys appear in the same order as they occur as the `.0` member
    /// of key-value pairs in `self`.  Each key in the result has a
    /// unique value.
    public var keys: [Key] { //LazyForwardCollection<MapCollection<[Key : Value], Key>> {
        return [Key](_keys)
    }
    /// A collection containing just the values of `self`.
    ///
    /// Values appear in the same order as they occur as the `.1` member
    /// of key-value pairs in `self`.
    public var values: [Value] { //LazyForwardCollection<MapCollection<[Key : Value], Value>> {
        return [Value](_values) //LazyForwardCollection<MapCollection<[Key : Value], Value>>(_values)
    }
    /// `true` iff `count == 0`.
    public var isEmpty: Bool { return count == 0 }
}

extension OrderedMap : CustomStringConvertible, CustomDebugStringConvertible {
    /// A textual representation of `self`.
    public var description: String {
        var result:String = ""
        for var i:Int = 0; i<_count; i++ {
            if !result.isEmpty { result += ", " }
            result += "\(_keys[i]): \(_values[i])"
        }
        return "[\(result)]"
    }
    /// A textual representation of `self`, suitable for debugging.
    public var debugDescription: String {
        return "OrderedMap<\(Key.self), \(Value.self)> \(description) count(\(_count))"
    }
}

extension OrderedMap : _Reflectable {
    public func _getMirror() -> _MirrorType {
        return _reflect(self)
    }
}

public func ==<Key : Hashable, Value>(lhs: MapIndex<Key, Value>, rhs: MapIndex<Key, Value>) -> Bool {
    return lhs.rawValue == rhs.rawValue
}
public func < <Key : Hashable, Value>(lhs: MapIndex<Key, Value>, rhs: MapIndex<Key, Value>) -> Bool {
    return lhs.rawValue < rhs.rawValue
}
public func <= <Key : Hashable, Value>(lhs: MapIndex<Key, Value>, rhs: MapIndex<Key, Value>) -> Bool {
    return lhs.rawValue <= rhs.rawValue
}
public func >= <Key : Hashable, Value>(lhs: MapIndex<Key, Value>, rhs: MapIndex<Key, Value>) -> Bool {
    return lhs.rawValue >= rhs.rawValue
}
public func > <Key : Hashable, Value>(lhs: MapIndex<Key, Value>, rhs: MapIndex<Key, Value>) -> Bool {
    return lhs.rawValue > rhs.rawValue
}

public struct MapIndex<Key : Hashable, Value> : ForwardIndexType, _Incrementable, Equatable, Comparable, RawRepresentable, IntegerLiteralConvertible {
    public typealias IntegerLiteralType = Int
 
    public init(integerLiteral value: IntegerLiteralType) {
        _rawValue = value
    }
    
    public typealias RawValue = Int
    
    public init(rawValue: RawValue) {
        _rawValue = rawValue
    }
    /// The corresponding value of the "raw" type.
    ///
    /// `Self(rawValue: self.rawValue)!` is equivalent to `self`.
    public var rawValue: RawValue { return _rawValue }
    private var _rawValue:RawValue
    /// Returns the next consecutive value after `self`.
    ///
    /// - Requires: The next value is representable.
    public func successor() -> MapIndex<Key, Value> {
        return MapIndex<Key, Value>(rawValue: _rawValue + 1)
    }

}

public struct OrderedDictionaryGenerator<Key : Hashable, Value> : GeneratorType {
    
    private var _position: Int = 0
    private var _dictionary:OrderedMap<Key, Value>
    private init(_ dictionary:OrderedMap<Key, Value>) {
        _dictionary = dictionary
    }
    
    public mutating func next() -> (Key, Value)? {
        if _position < _dictionary.count {
            return _dictionary[MapIndex<Key, Value>(rawValue: _position++)]
        }
        return nil
    }
}
