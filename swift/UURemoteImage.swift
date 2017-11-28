//
//  UURemoteImage.swift
//  Useful Utilities - An extension to Useful Utilities
//  UURemoteData that exposes the cached data as UIImage objects
//
//	License:
//  You are free to use this code for whatever purposes you desire.
//  The only requirement is that you smile everytime you use it.
//
//  NOTE: This class depends on the following toolbox classes:
//
//  UUHttpSession
//  UUDataCache
//  UURemoteData
//

import UIKit

public protocol UURemoteImageProtocol
{
    func image(for key: String, skipDownload: Bool) -> UIImage?
    func isDownloadPending(for key: String) -> Bool
    
    func metaData(for key: String) -> [String:Any]
    func set(metaData: [String:Any], for key: String)
    
    func imageSize(for key: String) -> CGSize?
}

public class UURemoteImage: NSObject, UURemoteImageProtocol
{
    public struct MetaData
    {
        public static let ImageSize = "ImageSize"
    }
    
    public static let shared = UURemoteImage()
    
    ////////////////////////////////////////////////////////////////////////////
    // UURemoteImageProtocol Implementation
    ////////////////////////////////////////////////////////////////////////////
    
    public func image(for key: String, skipDownload: Bool = false) -> UIImage?
    {
        let url = URL(string: key)
        if (url == nil)
        {
            return nil
        }
        
        let cached = UUDataCache.shared.data(for: key)
        if (cached != nil)
        {
            return UIImage(data: cached!)
        }
        
        var data : Data? = nil
        
        if (skipDownload)
        {
            data = UUDataCache.shared.data(for: key)
        }
        else
        {
            data = UURemoteData.shared.data(for: key)
        }
        
        if (data != nil)
        {
            let img = UIImage(data: data!)
            if (img != nil)
            {
                var md = metaData(for: key)
                md[MetaData.ImageSize] = img!.size
                set(metaData: md, for: key)
                
                return img
            }
        }
        
        return nil
    }
    
    public func isDownloadPending(for key: String) -> Bool
    {
        return UURemoteData.shared.isDownloadPending(for: key)
    }
    
    public func metaData(for key: String) -> [String:Any]
    {
        return UURemoteData.shared.metaData(for: key)
    }
    
    public func set(metaData: [String:Any], for key: String)
    {
        UURemoteData.shared.set(metaData: metaData, for: key)
    }
    
    public func imageSize(for key: String) -> CGSize?
    {
        let md = UURemoteData.shared.metaData(for: key)
        return md[MetaData.ImageSize] as? CGSize
    }
    
    ////////////////////////////////////////////////////////////////////////////
    // Private methods
    ////////////////////////////////////////////////////////////////////////////
    
}
