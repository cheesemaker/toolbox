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
}
