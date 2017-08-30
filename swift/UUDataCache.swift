//  UUDataCache
//  Useful Utilities - UUDataCache for commonly fetched data from URL's
//
//	License:
//  You are free to use this code for whatever purposes you desire.
//  The only requirement is that you smile everytime you use it.
//

import UIKit

public class UUDataCache: NSObject
{
    public static let shared = UUDataCache()
    
    public var contentExpirationLength : TimeInterval = (60 * 60 * 24 * 30) //30 days
    
    public func fileNameForUrl(url: URL) -> String
    {
        let absolutePath = url.absoluteString as NSString
        let split = absolutePath.components(separatedBy: CharacterSet.alphanumerics.inverted)
        let joined = split.joined(separator: "-")
        return joined
    }
    
    public func cachePath(url: URL) -> URL
    {
        let fullCachePath = cacheLocation().appendingPathComponent(fileNameForUrl(url: url))
        return fullCachePath
    }
    
    public func dataForUrl(url: URL) -> Data?
    {
        var data : Data? = nil
        
        if (!isCacheExpired(url: url))
        {
            let path = cachePath(url: url)
            
            do
            {
                data = try Data(contentsOf: path)
            }
            catch (let err)
            {
                UUDebugLog("Error reading data: %@", String(describing: err))
            }
        }
        
        return data
    }
    
    public func isCacheExpired(url: URL) -> Bool
    {
        let cachedDate : Date? = UserDefaults.standard.object(forKey: userPrefsKey(url: url)) as? Date
        if (cachedDate != nil)
        {
            let elapsed = -cachedDate!.timeIntervalSinceNow
            return (elapsed > contentExpirationLength)
        }
        
        return false
    }
    
    public func cacheData(data: Data, url: URL)
    {
        let path = cachePath(url: url)
        
        do
        {
            try data.write(to: path, options: .atomic )
        }
        catch (let err)
        {
            UUDebugLog("Error writing data: %@", String(describing: err))
        }
        
        let now = Date()
        UserDefaults.standard.set(now, forKey: userPrefsKey(url: url))
        UserDefaults.standard.synchronize()
    }
    
    private func userPrefsKey(url: URL) -> String
    {
        let path = cachePath(url: url)
        return path.absoluteString
    }
    
    public func clearCache(url: URL)
    {
        let path = cachePath(url: url)
        
        let fm = FileManager.default
        
        do
        {
            try fm.removeItem(at: path)
        }
        catch (let err)
        {
            UUDebugLog("Error clearing cache for url \(path): %@", String(describing: err))
        }
    }
    
    public func clearCacheContents()
    {
        let cacheLoc = cacheLocation()
        
        let fm = FileManager.default
        
        do
        {
            try fm.removeItem(at: cacheLoc)
            
            // Recreate cache folder
            _ = cacheLocation()
        }
        catch (let err)
        {
            UUDebugLog("Error creating cache path: %@", String(describing: err))
        }
    }
    
    public func purgeExpiredContent()
    {
        let cacheLoc = cacheLocation()
        
        let fm = FileManager.default
        
        var contents : [String] = []
        
        do
        {
            contents = try fm.contentsOfDirectory(atPath: cacheLoc.path)
        }
        catch (let err)
        {
            UUDebugLog("Error fetching contents of directory: %@", String(describing: err))
        }
        
        for item in contents
        {
            let url = URL(string: item)
            if (url != nil)
            {
                if (isCacheExpired(url: url!))
                {
                    clearCache(url: url!)
                }
            }
        }
    }
    
    public func doesCachedFileExist(url: URL) -> Bool
    {
        let path = cachePath(url: url)
        
        let fm = FileManager.default
        return fm.fileExists(atPath: path.path)
    }
    
    public func cacheLocation() -> URL
    {
        let cachePath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).last!
        
        var pathUrl = URL(fileURLWithPath: cachePath)
        pathUrl = pathUrl.appendingPathComponent("UUDataCache")
        
        let fm = FileManager.default
        if (!fm.fileExists(atPath: pathUrl.path))
        {
            do
            {
                try fm.createDirectory(atPath: pathUrl.path, withIntermediateDirectories: true, attributes: nil)
            }
            catch (let err)
            {
                UUDebugLog("Error creating cache path: %@", String(describing: err))
            }
        }
        
        return pathUrl
    }
}

