//
//  main.swift
//  CustomArrayAndDictionary
//
//  Created by 慧趣小歪 on 15/8/4.
//  Copyright © 2015年 慧趣小歪. All rights reserved.
//

import Foundation
print("Hello, World!")

var dictionary:OrderedMap<Int,String> = [1:"i1", 2:"i2", 3:"i3"]
print(dictionary)
debugPrint(dictionary)

dictionary[3] = (4, "i9")
print(dictionary[3])

/*
var a=2;

a+=a++ + ++a;
print("a:\(a)")
let b =  _reflect(a)
print(b)
debugPrint(b)
var defaultArray:Array<Int> = [1,2,6]
var objArray:OArray<Int> = [1,3,5]
defaultArray.insert(88, atIndex: 3)
print(defaultArray)

objArray.append(9)
objArray.append(10)
objArray.append(11)
objArray.append(12)

defaultArray[3] = 44


objArray.insert(77, atIndex: 3)
objArray[3] = 22

objArray.removeAtIndex(4)
//objArray.f
objArray.removeFirst()
objArray.removeFirst()

objArray.insert(99, atIndex: 0)
objArray.insert(98, atIndex: 0)
objArray.insert(97, atIndex: 0)
print(objArray)
print(objArray.count)

objArray.replaceRange(1..<objArray.endIndex, with: [9,44,66])
print(objArray)
objArray[1..<2] = [2]
print(objArray[1..<2])
print(objArray)

objArray.removeRange(0..<1)
objArray.splice([3,8,9], atIndex: 1)
//objArray += [2, 5, 7]
print(objArray)
print(objArray.count)

*/