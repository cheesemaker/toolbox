//
//  UUDebugLog.swift
//  Useful Utilities - NSLog wrapper that only prints in debug mode
//
//	License:
//  You are free to use this code for whatever purposes you desire.
//  The only requirement is that you smile everytime you use it.
//

import Foundation

// 
// UUDebugLog appends file, method, and line information to your custom logging
// message and prints to NSLog only when the preprocessor symbol DEBUG is defined
//
// In Swift projects, you can define a symbol in the 'Other Swift Flags' as
// "-D DEBUG" (without the quotes)
//
// Usage is identical to traditional Objective-C NSLog,
//
// UUDebugLog("Some interesting log statement")
//
// or with paramaters:
//
// UUDebugLog("Another interesting log statement, foo: %@, bar: %@", "Foo", "Bar")
//
public func UUDebugLog(function : NSString = #function, file : NSString = #file, line : Int = #line, _ format : String, _ args: CVarArg...)
{
#if DEBUG
    withVaList(args,
    { (p : CVaListPointer) -> Void in
 
        let now = Date().uuRfc3339WithMillisString()
        let fileNameOnly : String = file.lastPathComponent
        let s = NSString.init(format: "\(now) \(fileNameOnly) [\(function):\(line)] - \(format)", arguments: p) as String
        print(s)
    })
#endif
}
