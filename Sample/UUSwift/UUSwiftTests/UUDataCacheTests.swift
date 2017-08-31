//
//  UUDataCacheTests.swift
//  UUDataCacheTests
//
//	License:
//  You are free to use this code for whatever purposes you desire.
//  The only requirement is that you smile everytime you use it.
//

import XCTest
@testable import UUSwift

class UUDataCacheTests: XCTestCase
{
    static var isFirstTest : Bool = true
    
    var cacheToTest : UUDataCacheProtocol = UUDataCache.shared
    
    let testKey = "http://hack.for.test/data/file.dat"
    
    override func setUp()
    {
        super.setUp()
        
        if (UUDataCacheTests.isFirstTest)
        {
            cacheToTest.clearCache()
            UUDataCacheTests.isFirstTest = false
        }
    }
    
    override func tearDown()
    {
        super.tearDown()
    }
    
    func test_0000_KeysEmpty()
    {
        let list = cacheToTest.listKeys()
        XCTAssertEqual(list.count, 0)
    }
    
    func test_0001_ReturnNilBeforeCached()
    {
        let data = cacheToTest.data(for: testKey)
        XCTAssertNil(data)
    }
    
    func test_0002_CacheSomeDataAndRetrieveIt()
    {
        let key = testKey
        let data : Data = Data(bytes: [0, 1, 2, 3, 4, 5, 6, 7, 8])
        
        var exists = cacheToTest.doesDataExist(for: key)
        XCTAssertFalse(exists)
        
        cacheToTest.set(data: data, for: key)
        
        exists = cacheToTest.doesDataExist(for: key)
        XCTAssertTrue(exists)
        
        /*
        do
        {
            let list = try FileManager.default.contentsOfDirectory(atPath: UUDataCache.shared.cacheLocation().path)
            
            let lookupCheck = UUDataCache.shared.fileNameForUrl(url: url)
            XCTAssertTrue(list.contains(lookupCheck))
            
        }
        catch (let err)
        {
            UUDebugLog("Error writing data: %@", String(describing: err))
        }*/
        
        let check = cacheToTest.data(for: key)
        XCTAssertNotNil(check)
        XCTAssertEqual(data, check!)
    }
    
    func test_0003_DeleteFile()
    {
        let key = testKey
        
        var exists = cacheToTest.doesDataExist(for: key)
        XCTAssertTrue(exists)
        
        cacheToTest.removeData(for: key)
        
        let check = cacheToTest.data(for: key)
        XCTAssertNil(check)
        
        exists = cacheToTest.doesDataExist(for: key)
        XCTAssertFalse(exists)
    }
    
    func test_0004_ModifyFile()
    {
        let key = testKey
        
        let data : Data = Data(bytes: [0, 1, 2, 3, 4, 5, 6, 7, 8])
        
        cacheToTest.set(data: data, for: key)
        
        var check = cacheToTest.data(for: key)
        XCTAssertNotNil(check)
        XCTAssertEqual(data, check!)
        
        let modifiedData : Data = Data(bytes: [0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F])
        
        cacheToTest.set(data: modifiedData, for: key)
        
        check = cacheToTest.data(for: key)
        XCTAssertNotNil(check)
        XCTAssertEqual(modifiedData, check!)
    }
    
    func test_0005_PurgeExpiredContent_NotExpired()
    {
        let key = testKey
        
        let data : Data = Data(bytes: [0, 1, 2, 3, 4, 5, 6, 7, 8])
        
        cacheToTest.set(data: data, for: key)
        
        var check = cacheToTest.data(for: key)
        XCTAssertNotNil(check)
        XCTAssertEqual(data, check!)
        
        cacheToTest.purgeExpiredData()
        
        check = cacheToTest.data(for: key)
        XCTAssertNotNil(check)
        XCTAssertEqual(data, check!)
    }
    
    func test_0006_PurgeExpiredContent_Expired()
    {
        let key = testKey
        
        let data : Data = Data(bytes: [0, 1, 2, 3, 4, 5, 6, 7, 8])
        
        cacheToTest.set(data: data, for: key)
        
        var check = cacheToTest.data(for: key)
        XCTAssertNotNil(check)
        XCTAssertEqual(data, check!)
        
        cacheToTest.dataExpirationInterval = 0
        
        cacheToTest.purgeExpiredData()
        
        check = cacheToTest.data(for: key)
        XCTAssertNil(check)
    }
    
    
}
