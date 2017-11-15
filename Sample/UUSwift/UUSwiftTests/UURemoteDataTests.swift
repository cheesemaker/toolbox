//
//  UURemoteDataTests.swift
//  UURemoteDataTests
//
//	License:
//  You are free to use this code for whatever purposes you desire.
//  The only requirement is that you smile everytime you use it.
//

import XCTest
@testable import UUSwift

class UURemoteDataTests: XCTestCase
{
    static var isFirstTest : Bool = true
    
    private static let testUrl : String = "http://publicdomainarchive.com/?ddownload=47473"

    override func setUp()
    {
        super.setUp()
        
        if (UURemoteDataTests.isFirstTest)
        {
            UUDataCache.shared.clearCache()
            UURemoteDataTests.isFirstTest = false
            UUDataCache.shared.contentExpirationLength = 30 * 24 * 60 * 60
        }
    }
    
    override func tearDown()
    {
        super.tearDown()
    }
    
    func test_0000_FetchNoLocal()
    {
        let key = UURemoteDataTests.testUrl
        
        expectation(forNotification: NSNotification.Name(rawValue: UURemoteData.Notifications.DataDownloaded.rawValue), object: nil)
        { (notification: Notification) -> Bool in
            
            let md = UURemoteData.shared.metaData(for: key)
            XCTAssertNotNil(md)
            
            let data = UURemoteData.shared.data(for: key)
            XCTAssertNotNil(data)
            
            let nKey = notification.uuRemoteDataPath
            XCTAssertNotNil(nKey)
  
            let nErr = notification.uuRemoteDataError
            XCTAssertNil(nErr)
            
            return true
        }
        
        var data = UURemoteData.shared.data(for: key)
        XCTAssertNil(data)
        
        waitForExpectations(timeout: .infinity)
        { (err : Error?) in
            
            if (err != nil)
            {
                XCTFail("failed waiting for expectations, error: \(err!)")
            }
        }
 

        let md = UURemoteData.shared.metaData(for: key)
        data = UURemoteData.shared.data(for: key)
        XCTAssertNotNil(data)
        XCTAssertNotNil(md)
    }
    
    func test_0001_FetchFromBadUrl()
    {
        expectation(forNotification: NSNotification.Name(rawValue: UURemoteData.Notifications.DataDownloadFailed.rawValue), object: nil)
        
        let key = "http://this.is.a.fake.url/non_existent.jpg"
        
        let data = UURemoteData.shared.data(for: key)
        XCTAssertNil(data)
        
        waitForExpectations(timeout: .infinity)
        { (err : Error?) in
            
            if (err != nil)
            {
                XCTFail("failed waiting for expectations, error: \(err!)")
            }
        }
    }
    
    func test_0002_FetchExisting()
    {
        let key = UURemoteDataTests.testUrl
        
        let data = UURemoteData.shared.data(for: key)
        XCTAssertNotNil(data)
    }
    
    
}
