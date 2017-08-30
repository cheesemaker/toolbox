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
    
    let testUrl = URL(string: "http://hack.for.test/data/file.dat")!
    
    override func setUp()
    {
        super.setUp()
        
        if (UUDataCacheTests.isFirstTest)
        {
            UUDataCache.shared.clearCacheContents()
            UUDataCacheTests.isFirstTest = false
        }
    }
    
    override func tearDown()
    {
        super.tearDown()
    }
    
    func test_0000_CacheLocNeverNil()
    {
        let cacheLoc = UUDataCache.shared.cacheLocation()
        print("cacheLocation: \(cacheLoc)")
        XCTAssertNotNil(cacheLoc)
    }
    
    func test_0001_ReturnNilBeforeCached()
    {
        let url = testUrl
        let data = UUDataCache.shared.dataForUrl(url: url)
        XCTAssertNil(data)
    }
    
    func test_0002_CacheSomeDataAndRetrieveIt()
    {
        let url = testUrl
        let data : Data = Data(bytes: [0, 1, 2, 3, 4, 5, 6, 7, 8])
        
        var exists = UUDataCache.shared.doesCachedFileExist(url: url)
        XCTAssertFalse(exists)
        
        UUDataCache.shared.cacheData(data: data, url: url)
        
        exists = UUDataCache.shared.doesCachedFileExist(url: url)
        XCTAssertTrue(exists)
        
        do
        {
            let list = try FileManager.default.contentsOfDirectory(atPath: UUDataCache.shared.cacheLocation().path)
            
            let lookupCheck = UUDataCache.shared.fileNameForUrl(url: url)
            XCTAssertTrue(list.contains(lookupCheck))
            
        }
        catch (let err)
        {
            UUDebugLog("Error writing data: %@", String(describing: err))
        }
        
        let check = UUDataCache.shared.dataForUrl(url: url)
        XCTAssertNotNil(check)
        XCTAssertEqual(data, check!)
    }
    
    func test_0003_DeleteFile()
    {
        let url = testUrl
        
        var exists = UUDataCache.shared.doesCachedFileExist(url: url)
        XCTAssertTrue(exists)
        
        UUDataCache.shared.clearCache(url: url)
        
        let check = UUDataCache.shared.dataForUrl(url: url)
        XCTAssertNil(check)
        
        exists = UUDataCache.shared.doesCachedFileExist(url: url)
        XCTAssertFalse(exists)
    }
    
    func test_0004_ModifyFile()
    {
        let url = testUrl
        
        let data : Data = Data(bytes: [0, 1, 2, 3, 4, 5, 6, 7, 8])
        
        UUDataCache.shared.cacheData(data: data, url: url)
        
        var check = UUDataCache.shared.dataForUrl(url: url)
        XCTAssertNotNil(check)
        XCTAssertEqual(data, check!)
        
        let modifiedData : Data = Data(bytes: [0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F])
        
        UUDataCache.shared.cacheData(data: modifiedData, url: url)
        
        check = UUDataCache.shared.dataForUrl(url: url)
        XCTAssertNotNil(check)
        XCTAssertEqual(modifiedData, check!)
    }
    
    func test_0005_PurgeExpiredContent_NotExpired()
    {
        let url = testUrl
        
        let data : Data = Data(bytes: [0, 1, 2, 3, 4, 5, 6, 7, 8])
        
        UUDataCache.shared.cacheData(data: data, url: url)
        
        var check = UUDataCache.shared.dataForUrl(url: url)
        XCTAssertNotNil(check)
        XCTAssertEqual(data, check!)
        
        UUDataCache.shared.purgeExpiredContent()
        
        check = UUDataCache.shared.dataForUrl(url: url)
        XCTAssertNotNil(check)
        XCTAssertEqual(data, check!)
    }
    
    func test_0006_PurgeExpiredContent_Expired()
    {
        let url = testUrl
        
        let data : Data = Data(bytes: [0, 1, 2, 3, 4, 5, 6, 7, 8])
        
        UUDataCache.shared.cacheData(data: data, url: url)
        
        var check = UUDataCache.shared.dataForUrl(url: url)
        XCTAssertNotNil(check)
        XCTAssertEqual(data, check!)
        
        UUDataCache.shared.contentExpirationLength = 0
        
        UUDataCache.shared.purgeExpiredContent()
        
        check = UUDataCache.shared.dataForUrl(url: url)
        XCTAssertNil(check)
    }
    
    
}
