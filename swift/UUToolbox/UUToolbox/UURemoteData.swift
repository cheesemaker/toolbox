//
//  UURemoteData.swift
//  Useful Utilities - An extension to Useful Utilities 
//  UUDataCache that fetches data from a remote source
//
//	License:
//  You are free to use this code for whatever purposes you desire.
//  The only requirement is that you smile everytime you use it.
//
//
//  UURemoteData provides a centralized place where application components can 
//  request data that may come from a remote source.  It utilizes existing 
//  UUDataCache functionality to locally store files for later fetching.  It 
//  will intelligently handle multiple requests for the same image so that 
//  extraneous network requests are not needed.
//
//  NOTE: This class depends on the following toolbox classes:
//
//  UUHttpSession
//  UUDataCache
//

import Foundation

public protocol UURemoteDataProtocol
{
    func data(for key: String) -> Data?
    func isDownloadPending(for key: String) -> Bool

    func metaData(for key: String) -> [String:Any]
    func set(metaData: [String:Any], for key: String)
}

public class UURemoteData: NSObject, UURemoteDataProtocol
{
    public struct Notifications
    {
        public static let DataDownloaded = Notification.Name("UUDataDownloadedNotification")
        public static let DataDownloadFailed = Notification.Name("UUDataDownloadFailedNotification")
    }
    
    public struct MetaData
    {
        public static let MimeType = "MimeType"
        public static let DownloadTimestamp = "DownloadTimestamp"
    }
    
    public struct NotificationKeys
    {
        public static let RemotePath = "UUDataRemotePathKey"
        public static let Error = "UURemoteDataErrorKey"
    }
    
    public static let shared = UURemoteData()
    
    private var pendingDownloads : [String:UUHttpRequest] = [:]
    private var responseHandlers : [String: Any] = [:]

    
    ////////////////////////////////////////////////////////////////////////////
    // UURemoteDataProtocol Implementation
    ////////////////////////////////////////////////////////////////////////////
    public func data(for key: String) -> Data?
    {
        let url = URL(string: key)
        if (url == nil)
        {
            return nil
        }
        
        let data = UUDataCache.shared.data(for: key)
        if (data != nil)
        {
            return data
        }
        
        let pendingDownload = pendingDownloads[key]
        if (pendingDownload != nil)
        {
            // An active UUHttpSession means a request is currently fetching the resource, so
            // no need to re-fetch
            UUDebugLog("Download pending for \(key)")
            return nil
        }
        
        let request = UUHttpRequest.getRequest(key, [:])
        request.processMimeTypes  = false
        
        let client = UUHttpSession.executeRequest(request)
        { (response: UUHttpResponse) in
            
            self.handleDownloadResponse(response, key)
        }
        
        pendingDownloads[key] = client
        return nil
    }
    
    public func isDownloadPending(for key: String) -> Bool
    {
        return (pendingDownloads[key] != nil)
    }
    
    public func metaData(for key: String) -> [String:Any]
    {
        return UUDataCache.shared.metaData(for: key)
    }
    
    public func set(metaData: [String:Any], for key: String)
    {
        UUDataCache.shared.set(metaData: metaData, for: key)
    }
    
    ////////////////////////////////////////////////////////////////////////////
    // Private Implementation
    ////////////////////////////////////////////////////////////////////////////
    private func handleDownloadResponse(_ response: UUHttpResponse, _ key: String)
    {
        var md : [String:Any] = [:]
        md[UURemoteData.NotificationKeys.RemotePath] = key
        
        if (response.httpError == nil && response.rawResponse != nil)
        {
            let responseData = response.rawResponse!
            
            UUDataCache.shared.set(data: responseData, for: key)
            updateMetaDataFromResponse(response, for: key)
            
            DispatchQueue.main.async
            {
                NotificationCenter.default.post(name: Notifications.DataDownloaded, object: nil, userInfo: md)
            }
        }
        else
        {
            UUDebugLog("Remote download failed!\n\nPath: %@\nStatusCode: %d\nError: %@\n", key, String(describing: response.httpResponse?.statusCode), String(describing: response.httpError))

            md[NotificationKeys.Error] = response.httpError
            
            DispatchQueue.main.async
            {
                NotificationCenter.default.post(name: Notifications.DataDownloadFailed, object: nil, userInfo: md)
            }
        }
        
        pendingDownloads.removeValue(forKey: key)
    }
    
    private func updateMetaDataFromResponse(_ response: UUHttpResponse, for key: String)
    {
        var md = UUDataCache.shared.metaData(for: key)
        md[MetaData.MimeType] = response.httpResponse!.mimeType!
        md[MetaData.DownloadTimestamp] = Date()
        
        UUDataCache.shared.set(metaData: md, for: key)
    }
    
    public func save(data: Data, key: String)
    {
        UUDataCache.shared.set(data: data, for: key)
        
        var md = UUDataCache.shared.metaData(for: key)
        md[MetaData.MimeType] = "raw"
        md[MetaData.DownloadTimestamp] = Date()
        md[UURemoteData.NotificationKeys.RemotePath] = key
        
        UUDataCache.shared.set(metaData: md, for: key)
        
        DispatchQueue.main.async
        {
            NotificationCenter.default.post(name: Notifications.DataDownloaded, object: nil, userInfo: md)
        }
    }
}

public extension Notification
{
    public var uuRemoteDataPath : String?
    {
        return userInfo?[UURemoteData.NotificationKeys.RemotePath] as? String
    }
    
    public var uuRemoteDataError : Error?
    {
        return userInfo?[UURemoteData.NotificationKeys.Error] as? Error
    }
}
