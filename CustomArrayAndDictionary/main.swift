//
//  main.swift
//  CustomArrayAndDictionary
//
//  Created by 慧趣小歪 on 15/8/4.
//  Copyright © 2015年 慧趣小歪. All rights reserved.
//

import Foundation
let str:String = "33"
print("Hello, World!")

var defaultArray:Array<Int> = [1,2,6]

let objArray:OArray<Int> = [1,3,5]
defaultArray.insert(88, atIndex: 3)
print(defaultArray)

objArray.append(9)
objArray.append(10)
objArray.append(11)
objArray.append(12)


objArray.insert(77, atIndex: 3)
objArray[3] = 22

objArray.removeAtIndex(4)

objArray.removeFirst()
objArray.removeFirst()

objArray.insert(99, atIndex: 0)
objArray.insert(98, atIndex: 0)
objArray.insert(97, atIndex: 0)
print(objArray)
print(objArray.count)

objArray.replaceRange(0...objArray.endIndex, with: [9,44,66])
//objArray.removeAtIndex(7)
objArray.removeRange(0..<1)
objArray.splice([3,8,9], atIndex: 1)
print(objArray)
print(objArray.count)

