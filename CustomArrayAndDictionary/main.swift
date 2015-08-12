//
//  main.swift
//  CustomArrayAndDictionary
//
//  Created by 慧趣小歪 on 15/8/4.
//  Copyright © 2015年 慧趣小歪. All rights reserved.
//

import Foundation
print("Hello, World!")

var info:mach_timebase_info = mach_timebase_info()
mach_timebase_info(&info);

func timeDec(start:UInt64, _ end:UInt64) -> NSTimeInterval {
    return Double(end - start) * Double(info.numer) / Double(info.denom) / 1e9
}

// 定义C式的函数
let timeDecin : @convention(c) (UInt64, UInt64) -> NSTimeInterval = {
    (start, end) -> NSTimeInterval in
    return Double(end - start) * Double(info.numer) / Double(info.denom) / 1e9
}

func main() {
    
    var dictionary:Dictionary<Int, String> = [:]
    let orderedMap:OrderedMap<Int, String> = [:]
    
    var length = 1000000
    
    var startTime = mach_absolute_time()
    for var i:Int=0; i<length; i++ {
        dictionary[i] = "i\(i)"
    }
    print("普通字典初始化时间: \(timeDecin(startTime, mach_absolute_time())) s")
    
    startTime = mach_absolute_time()
    for var i:Int=0; i<length; i++ {
        orderedMap[i] = "i\(i)"
    }
    print("序列字典初始化时间: \(timeDecin(startTime, mach_absolute_time())) s")
    
    
    startTime = mach_absolute_time()
    for var i:Int=0; i<length; i++ {
        dictionary[i] == "i\(i)"
    }
    print("普通字典读取时间: \(timeDecin(startTime, mach_absolute_time())) s")
    
    startTime = mach_absolute_time()
    for var i:Int=0; i<length; i++ {
        orderedMap[i] == "i\(i)"
    }
    print("序列字典读取时间: \(timeDecin(startTime, mach_absolute_time())) s")
    
    length = 100000000
    var array:Array<Int> = []
    let oarray:OArray<Int> = []
    var carray:ContiguousArray<Int> = []
    
    startTime = mach_absolute_time()
    for var i:Int=0; i<length; i++ {
        array.append(i)
    }
    print("普通数组初始化时间: \(timeDec(startTime, mach_absolute_time())) s")
    
    startTime = mach_absolute_time()
    for var i:Int=0; i<length; i++ {
        oarray.append(i)
    }
    print("对象数组初始化时间: \(timeDec(startTime, mach_absolute_time())) s")
    
    startTime = mach_absolute_time()
    for var i:Int=0; i<length; i++ {
        carray.append(i)
    }
    print("高效数组初始化时间: \(timeDec(startTime, mach_absolute_time())) s")
    
    
    startTime = mach_absolute_time()
    for var i:Int=0; i<length; i++ {
        array[i] == i
        
    }
    print("普通数组读取时间: \(timeDec(startTime, mach_absolute_time())) s")
    
    startTime = mach_absolute_time()
    for var i:Int=0; i<length; i++ {
        oarray[i] == i
    }
    print("序列数组读取时间: \(timeDec(startTime, mach_absolute_time())) s")
    
    startTime = mach_absolute_time()
    for var i:Int=0; i<length; i++ {
        carray[i] == i
    }
    print("高效数组读取时间: \(timeDec(startTime, mach_absolute_time())) s")

}
main()
print("比较完毕")
//print("appTime:\(appTime) startTime:\(startTime)")
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