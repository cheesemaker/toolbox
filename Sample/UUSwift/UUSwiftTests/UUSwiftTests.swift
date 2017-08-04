//
//  UUSwiftTests.swift
//  UUSwiftTests
//
//  Created by Ryan DeVore on 7/3/17.
//  Copyright © 2017 Useful Utilities. All rights reserved.
//

import XCTest
@testable import UUSwift

class UUCoreDataTests: XCTestCase
{
    static var isFirstTest : Bool = true
    
    override func setUp()
    {
        super.setUp()
        
        let modelBundle = Bundle(identifier: "uu.toolbox.UUSwiftTests")
        XCTAssert(modelBundle != nil)
        
        let url = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library").appendingPathComponent("UUSwiftUnitTests.db")
        
        if (UUCoreDataTests.isFirstTest)
        {
            UUCoreData.destroyStore(at: url)
            UUCoreDataTests.isFirstTest = false
        }
        
        //uuCoreData = UUCoreData(url: url, modelDefinitionBundle: modelBundle!)
        //XCTAssert(uuCoreData != nil)
        
//        for e in uuCoreData!.storeCoordinator!.managedObjectModel.entities
//        {
//            print("entity: \(e)")
//        }
        
        _ = UUCoreData.mainThreadContext
        
        UUCoreData.configure(url: url, modelDefinitionBundle: modelBundle!)
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func test_0000_FetchOnEmptyDb()
    {
        let exp = expectation(description: "testFetchOnEmptyDb")
        
        let context = UUCoreData.mainThreadContext!
        
        Player.uuFetchObjects(context: context)
        { (list : [Any]) in
        
            XCTAssert(list.count == 0)
            exp.fulfill()
        }
        
        waitForExpectations(timeout: .infinity)
        { (err : Error?) in
        
            if (err != nil)
            {
                XCTFail("failed waiting for expectations, error: \(err!)")
            }
        }
    }
    
    private static let singlePlayerId : Int64 = 1
    private static var singlePlayerName : String? = nil
    private static var singlePlayerLevel : Int32 = 0
    private static var singlePlayerUpdatedAt: NSDate? = nil
    
    func test_0001_FetchOrCreateOnEmptyDb()
    {
        let exp = expectation(description: "test_0001_FetchOrCreateOnEmptyDb")
        
        let context = UUCoreData.mainThreadContext!
        
        context.perform
        {
            let predicate = NSPredicate(format: "identifier = %@", NSNumber(value: UUCoreDataTests.singlePlayerId))
            
            let p = Player.uuFetchOrCreate(predicate: predicate, context: context)
            
            XCTAssert(p.identifier == 0)
            XCTAssert(p.name == nil)
            XCTAssert(p.level == 0)
            XCTAssert(p.updatedAt == nil)
            
            UUCoreDataTests.singlePlayerName = "Single Player Name Here"
            UUCoreDataTests.singlePlayerLevel = 57
            UUCoreDataTests.singlePlayerUpdatedAt = NSDate()
            
            p.identifier = UUCoreDataTests.singlePlayerId
            p.name = UUCoreDataTests.singlePlayerName
            p.level = UUCoreDataTests.singlePlayerLevel
            p.updatedAt = UUCoreDataTests.singlePlayerUpdatedAt
            
            _ = context.uuSubmitChanges()
            
            exp.fulfill()
        }
        
        waitForExpectations(timeout: .infinity)
        { (err : Error?) in
            
            if (err != nil)
            {
                XCTFail("failed waiting for expectations, error: \(err!)")
            }
        }
    }
    
    func test_0002_FetchOrCreateOnNonEmptyDb()
    {
        let exp = expectation(description: "test_0002_FetchOrCreateOnNonEmptyDb")
        
        let context = UUCoreData.mainThreadContext!
        
        context.perform
        {
            let predicate = NSPredicate(format: "identifier = %@", NSNumber(value: UUCoreDataTests.singlePlayerId))
            
            let p = Player.uuFetchOrCreate(predicate: predicate, context: context)
            
            XCTAssert(p.identifier == UUCoreDataTests.singlePlayerId)
            XCTAssert(p.name == UUCoreDataTests.singlePlayerName)
            XCTAssert(p.level == UUCoreDataTests.singlePlayerLevel)
            XCTAssert(p.updatedAt == UUCoreDataTests.singlePlayerUpdatedAt)
            
            _ = context.uuSubmitChanges()
            
            exp.fulfill()
        }
        
        waitForExpectations(timeout: .infinity)
        { (err : Error?) in
            
            if (err != nil)
            {
                XCTFail("failed waiting for expectations, error: \(err!)")
            }
        }
    }
    
    func test_0003_FetchRecordDoesNotExist()
    {
        let exp = expectation(description: "test_0003_FetchRecordDoesNotExist")
        
        let context = UUCoreData.mainThreadContext!
        
        context.perform
        {
            let predicate = NSPredicate(format: "identifier = %@", NSNumber(value: 2))
            
            let result = Player.uuFetchSingleObject(predicate: predicate, context: context)
            XCTAssertNil(result)
            exp.fulfill()
        }
        
        waitForExpectations(timeout: .infinity)
        { (err : Error?) in
            
            if (err != nil)
            {
                XCTFail("failed waiting for expectations, error: \(err!)")
            }
        }
    }
    
    func test_0004_FetchRecordDoesExist()
    {
        let exp = expectation(description: "testFetchRecordDoesExist")
        
        let context = UUCoreData.mainThreadContext!
        
        context.perform
        {
            let predicate = NSPredicate(format: "identifier = %@", NSNumber(value: UUCoreDataTests.singlePlayerId))
            
            let result = Player.uuFetchSingleObject(predicate: predicate, context: context)
            
            XCTAssertNotNil(result)
            
            exp.fulfill()
        }
        
        waitForExpectations(timeout: .infinity)
        { (err : Error?) in
            
            if (err != nil)
            {
                XCTFail("failed waiting for expectations, error: \(err!)")
            }
        }
    }
    
    func test_0005_DeleteObjects()
    {
        let exp = expectation(description: "testDeleteObjects")
        
        let context = UUCoreData.mainThreadContext!
        
        context.perform
        {
            let predicate = NSPredicate(format: "identifier = %@", NSNumber(value: UUCoreDataTests.singlePlayerId))
            
            Player.uuDeleteObjects(predicate: predicate, context: context)
            
            let err : Error? = context.uuSubmitChanges()
            XCTAssertNil(err)
            
            let count = Player.uuCountObjects(context: context)
            XCTAssertEqual(count, 0)
            
            exp.fulfill()
        }
        
        waitForExpectations(timeout: .infinity)
        { (err : Error?) in
            
            if (err != nil)
            {
                XCTFail("failed waiting for expectations, error: \(err!)")
            }
        }
    }
    
    func test_0006_DeleteAll()
    {
        let context = UUCoreData.mainThreadContext!
        
        context.uuDeleteAllObjects()
        
        let count = Player.uuCountObjects(context: context)
        XCTAssertEqual(count, 0)
    }
    
    func test_0007_BackgroundMoc()
    {
        let mainMoc = UUCoreData.mainThreadContext!
        
        mainMoc.performAndWait
        {
            let countOnMain = Player.uuCountObjects(context: mainMoc)
            XCTAssertEqual(countOnMain, 0)
        }
        
        let context = UUCoreData.workerThreadContext()!
        
        context.performAndWait
        {
            let p = Player.uuCreate(context: context)
            p.identifier = 2
            p.name = "test background moc"
            
            mainMoc.performAndWait
            {
                let countOnMain = Player.uuCountObjects(context: mainMoc)
                XCTAssertEqual(countOnMain, 0)
            }
            
            _ = context.uuSubmitChanges()
            
            let countOnMain = Player.uuCountObjects(context: mainMoc)
            XCTAssertEqual(countOnMain, 1)
            
        }
        
    }
    
}
