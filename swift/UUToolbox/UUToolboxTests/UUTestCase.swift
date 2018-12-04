//
//  UUTestCase.swift
//  Useful Utilities
//
//  License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//

import UIKit
import XCTest
import UUToolbox

public extension XCTestCase
{
    public func UUExpectationForMethod(
        function : NSString = #function,
        tag : NSString = "") -> XCTestExpectation
    {
        return expectation(description: "_\(function)_\(tag)_")
    }
    
    public func UUWaitForExpectations(_ timeout: TimeInterval = 60)
    {
        waitForExpectations(timeout: timeout)
        { (err: Error?) in
            if (err != nil)
            {
                XCTFail("Failed waiting for expectation, error: \(err!)")
            }
        }
    }
    
    public func UULogBeginTest(function : NSString = #function)
    {
        UUDebugLog("\n\n******************** BEGIN TEST \(function) ********************\n\n")
    }
    
    public func UULogEndTest(function : NSString = #function)
    {
        UUDebugLog("\n\n******************** END TEST \(function) ********************\n\n")
    }
    
    func testXCTestCaseExtensionMethods()
    {
        UULogBeginTest()
        
        let exp = UUExpectationForMethod()
        
        DispatchQueue.main.async
        {
            exp.fulfill()
        }
        
        UUWaitForExpectations()
        UULogEndTest()
    }
    
    func testRandomWords()
    {
        let a = randomWord(20)
        XCTAssertNotNil(a)
        UUDebugLog("\(a)")
        
        let b = randomWords(5, 10)
        XCTAssertNotNil(b)
        UUDebugLog("\(b)")
    }
    
    func randomWord(_ length: Int) -> String
    {
        let sb = NSMutableString()
        
        while (sb.length < length)
        {
            let b = UURandom.randomUInt8()
            if (b >= 65 && b <= 90) || (b >= 97 && b <= 122) // A-Z or a-z
            {
                let u = UnicodeScalar(b)
                let c = Character(u)
                sb.append(String(c))
            }
        }
        
        return sb as String
    }
    
    func randomWords(_ maxNumberOfWords: Int, _ maxWordLength: Int) -> String
    {
        let sb = NSMutableString()
        
        let words = UURandom.randomUInt32(low: 0, high: UInt32(maxNumberOfWords))
        var i = 0
        while (i < words)
        {
            sb.append(randomWord(maxWordLength))
            sb.append(" ")
            i = i + 1
        }
        
        return sb as String
    }
}
