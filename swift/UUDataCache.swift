//  UUDataCache
//  Useful Utilities - UUDataCache is a lightweight facade for caching data.
//
//
//	License:
//  You are free to use this code for whatever purposes you desire.
//  The only requirement is that you smile everytime you use it.
//

import Foundation
import CoreData

// UUDataCacheProtocol defines a lightweight interface for caching of data
// along with a meta data dictionary about each blob of data.
public protocol UUDataCacheProtocol
{
    func data(for key: String) -> Data?
    func set(data: Data, for key: String)
    
    func metaData(for key: String) -> [String:Any]
    func set(metaData: [String:Any], for key: String)
    
    func doesDataExist(for key: String) -> Bool
    func isDataExpired(for key: String) -> Bool
    
    func removeData(for key: String)
    
    func clearCache()
    func purgeExpiredData()
    
    var dataExpirationInterval : TimeInterval { get set }
    
    func listKeys() -> [String]
}

// Default implementation of UUDataCacheProtocol.  Data objects are persisted
// in an NSCache backed by raw data files.
//
// Meta Data is persisted with CoreData
public class UUDataCache : NSObject, UUDataCacheProtocol
{
    ////////////////////////////////////////////////////////////////////////////
    // Constants
    ////////////////////////////////////////////////////////////////////////////
    public struct Constants
    {
        public static let defaultContentExpirationLength : TimeInterval = (60 * 60 * 24 * 30) // 30 days
    }
    
    public struct MetaDataKeys
    {
        public static let timestamp = "timestamp"
    }
    
    ////////////////////////////////////////////////////////////////////////////
    // Class Data Memebers
    ////////////////////////////////////////////////////////////////////////////
    public static let shared = UUDataCache()
    
    ////////////////////////////////////////////////////////////////////////////
    // Instance Data Memebers
    ////////////////////////////////////////////////////////////////////////////
    public var contentExpirationLength : TimeInterval = Constants.defaultContentExpirationLength
    
    private var cacheFolder : String = ""
    
    private var dataCache = NSCache<NSString, NSData>()
    
    ////////////////////////////////////////////////////////////////////////////
    // Initialization
    ////////////////////////////////////////////////////////////////////////////
    required public init(cacheLocation : String = UUDataCache.defaultCacheFolder(),
                         contentExpiration: TimeInterval = Constants.defaultContentExpirationLength)
    {
        super.init()
        
        cacheFolder = cacheLocation
        contentExpirationLength = contentExpiration
        UUDataCache.createFolderIfNeeded(cacheFolder)
    }
    
    ////////////////////////////////////////////////////////////////////////////
    // UUDataCacheProtocol Implementation
    ////////////////////////////////////////////////////////////////////////////
    public func data(for key: String) -> Data?
    {
        removeIfExpired(for: key)
        
        let cached = loadFromCache(for: key)
        if (cached != nil)
        {
            return cached
        }
        
        let data = loadFromDisk(for: key)
        
        return data
    }
    
    public func set(data: Data, for key: String)
    {
        saveToDisk(data: data, for: key)
        saveToCache(data: data, for: key)
        
        var md = metaData(for: key)
        md[MetaDataKeys.timestamp] = Date()
        set(metaData: md, for: key)
    }
    
    public func metaData(for key: String) -> [String:Any]
    {
        return UUDataCacheDb.shared.metaData(for: key)
    }
    
    public func set(metaData: [String:Any], for key: String)
    {
        UUDataCacheDb.shared.setMetaData(metaData, for: key)
    }
    
    public func doesDataExist(for key: String) -> Bool
    {
        let pathUrl = diskCacheURL(for: key)
        return FileManager.default.fileExists(atPath:pathUrl.path)
    }
    
    public func isDataExpired(for key: String) -> Bool
    {
        let md = metaData(for: key)
        let timestamp = md[MetaDataKeys.timestamp] as? Date
        if (timestamp != nil)
        {
            let elapsed = Date().timeIntervalSince(timestamp!)
            return (elapsed > contentExpirationLength)
        }
        
        return false
    }
    
    public func removeData(for key: String)
    {
        UUDataCacheDb.shared.clearMetaData(for: key)
        dataCache.removeObject(forKey: key as NSString)
        removeFile(for: key)
    }
    
    public func clearCache()
    {
        let fm = FileManager.default
        
        do
        {
            try fm.removeItem(atPath: cacheFolder)
        }
        catch (let err)
        {
            UUDebugLog("Error creating cache path: %@", String(describing: err))
        }
        
        UUDataCache.createFolderIfNeeded(cacheFolder)
        
        UUDataCacheDb.shared.clearAllMetaData()
        
        dataCache.removeAllObjects()
    }
    
    public func purgeExpiredData()
    {
        let keys : [String] = listKeys()
        
        for key in keys
        {
            removeIfExpired(for: key)
        }
    }
    
    public func listKeys() -> [String]
    {
        var contents : [String] = []
        
        do
        {
            contents = try FileManager.default.contentsOfDirectory(atPath: cacheFolder)
        }
        catch (let err)
        {
            UUDebugLog("Error fetching contents of directory: %@", String(describing: err))
        }
        
        return contents
    }
    
    public var dataExpirationInterval : TimeInterval
    {
        get
        {
            return contentExpirationLength
        }
        
        set
        {
            contentExpirationLength = newValue
        }
    }
    
    ////////////////////////////////////////////////////////////////////////////
    // Private Implementation
    ////////////////////////////////////////////////////////////////////////////
    public static func defaultCacheFolder() -> String
    {
        let cachePath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).last!
        let path = (cachePath as NSString).appendingPathComponent("UUDataCache")
        return path
    }
    
    private static func createFolderIfNeeded(_ folder: String)
    {
        let fm = FileManager.default
        if (!fm.fileExists(atPath: folder))
        {
            do
            {
                try fm.createDirectory(atPath: folder, withIntermediateDirectories: true, attributes: nil)
            }
            catch (let err)
            {
                UUDebugLog("Error creating folder: %@", String(describing: err))
            }
        }
    }
    
    private func sanitizeKey(_ key: String) -> String
    {
        let split = key.components(separatedBy: CharacterSet.alphanumerics.inverted)
        let joined = split.joined(separator: "-")
        return joined
    }
    
    private func diskCacheURL(for key: String) -> URL
    {
        let safeFileName = sanitizeKey(key)
        let path = (cacheFolder as NSString).appendingPathComponent(safeFileName)
        let pathUrl = URL(fileURLWithPath: path)
        return pathUrl
    }
    
    private func removeIfExpired(for key: String)
    {
        if (isDataExpired(for: key))
        {
            removeData(for: key)
        }
    }
    
    private func loadFromDisk(for key: String) -> Data?
    {
        var data : Data? = nil
        
        let pathUrl = diskCacheURL(for: key)
        
        do
        {
            data = try Data(contentsOf: pathUrl)
        }
        catch (let err)
        {
            UUDebugLog("Error loading data: %@", String(describing: err))
        }
        
        return data
    }
    
    private func loadFromCache(for key: String) -> Data?
    {
        return dataCache.object(forKey: key as NSString) as Data?
    }
    
    private func removeFile(for key: String)
    {
        let pathUrl = diskCacheURL(for: key)
        
        do
        {
            try FileManager.default.removeItem(at: pathUrl)
        }
        catch (let err)
        {
            UUDebugLog("Error removing file: %@", String(describing: err))
        }
    }
    
    private func saveToDisk(data: Data, for key: String)
    {
        let pathUrl = diskCacheURL(for: key)
        
        do
        {
            try data.write(to: pathUrl, options: .atomic)
        }
        catch (let err)
        {
            UUDebugLog("Error saving data: %@", String(describing: err))
        }
    }
    
    private func saveToCache(data: Data, for key: String)
    {
        dataCache.setObject(data as NSData, forKey: key as NSString)
    }
}


private class UUDataCacheDb : NSObject
{
    static let shared = UUDataCacheDb()
    
    private var coreDataStack : UUCoreData!
    private let storeUrl : URL = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library").appendingPathComponent("UUDataCacheMetaDataDb.sqlite")
    private let storeModel : NSManagedObjectModel = UUDataCacheDb.objectModel()
    
    required public override init()
    {
        super.init()
        
        coreDataStack = UUCoreData(url: storeUrl, model: storeModel)
    }
    
    
    private class func objectModel() -> NSManagedObjectModel
    {
        let model = NSManagedObjectModel()
        
        let entity = NSEntityDescription()
        entity.name = "UUDataCacheMetaData"
        entity.managedObjectClassName = "UUDataCacheMetaData"
        
        var properties : [NSAttributeDescription] = []
        
        var attr = NSAttributeDescription()
        attr.name = "name"
        attr.attributeType = .stringAttributeType
        attr.isOptional = false
        attr.isIndexed = true
        properties.append(attr)
        
        attr = NSAttributeDescription()
        attr.name = "timestamp"
        attr.attributeType = .dateAttributeType
        attr.isOptional = false
        attr.isIndexed = true
        properties.append(attr)
        
        attr = NSAttributeDescription()
        attr.name = "metaData"
        attr.attributeType = .transformableAttributeType
        attr.isOptional = false
        attr.isIndexed = true
        properties.append(attr)
        
        entity.properties = properties
        
        model.entities = [entity]
     
        return model
    }
    
    public func metaData(for key: String) -> [String:Any]
    {
        var md : [String:Any]? = nil
        
        let ctx = coreDataStack.mainThreadContext!
        ctx.performAndWait
        {
            let obj = self.underlyingMetaData(for: key)
            md = obj.metaData as? [String:Any]
        }
        
        if (md == nil)
        {
            md = [:]
        }
        
        return md!
    }
    
    public func setMetaData(_ metaData: [String:Any], for key: String)
    {
        let ctx = coreDataStack.mainThreadContext!
        ctx.performAndWait
        {
            let obj = self.underlyingMetaData(for: key)
            obj.timestamp = Date()
            obj.metaData = metaData as NSDictionary
            _ = ctx.uuSubmitChanges()
        }
    }
    
    public func clearMetaData(for key: String)
    {
        let ctx = coreDataStack.mainThreadContext!
        ctx.performAndWait
        {
            let predicate = NSPredicate(format: "name = %@", key)
            UUDataCacheMetaData.uuDeleteObjects(predicate: predicate, context: ctx)
        }
    }
    
    public func clearAllMetaData()
    {
        let ctx = coreDataStack.mainThreadContext!
        ctx.performAndWait
        {
            ctx.uuDeleteAllObjects()
            _ = ctx.uuSubmitChanges()
        }
    }
    
    private func underlyingMetaData(for key: String) -> UUDataCacheMetaData
    {
        var obj : UUDataCacheMetaData? = nil
        
        let ctx = coreDataStack.mainThreadContext!
        ctx.performAndWait
        {
            let predicate = NSPredicate(format: "name = %@", key)
            obj = UUDataCacheMetaData.uuFetchSingleObject(predicate: predicate, context: ctx)
            if (obj == nil)
            {
                obj = UUDataCacheMetaData.uuCreate(context: ctx)
                obj!.name = key
                obj!.timestamp = Date()
                obj!.metaData = NSDictionary()
                _ = ctx.uuSubmitChanges()
            }
        }
        
        return obj!
    }
}

public class UUDataCacheMetaData : NSManagedObject
{
    @NSManaged var name : String?
    @NSManaged var timestamp : Date?
    @NSManaged var metaData : NSDictionary?
}
