//
//  RSQuote+Ext.swift
//  UUSwift
//
//	License:
//  You are free to use this code for whatever purposes you desire.
//  The only requirement is that you smile everytime you use it.
//

import UIKit
import CoreData

extension RSQuote : UUObjectFactory
{
    static func uuObjectFromDictionary(dictionary : [AnyHashable:Any], context: Any?) -> Self?
    {
        return uuObjectFromDictionaryInternal(dictionary: dictionary, context: context)
    }
    
    private static func uuObjectFromDictionaryInternal<T>(dictionary : [AnyHashable:Any], context: Any?) -> T?
    {
        var obj : T? = nil
        
        if (context != nil && context is NSManagedObjectContext)
        {
            let moc = context as! NSManagedObjectContext
            moc.performAndWait
                {
                    let predicate = primaryKeyPredicate(dictionary: dictionary)
                    if (predicate != nil)
                    {
                        let o = uuFetchOrCreate(predicate: predicate!, context: moc)
                        o.fillFromDictionary(dictionary)
                        obj = o as? T
                    }
            }
        }
        
        return obj
    }
    
    private static func primaryKeyPredicate(dictionary: [AnyHashable:Any]) -> NSPredicate?
    {
        let primaryKeyValue = dictionary["identifier"] as? Int
        if (primaryKeyValue != nil)
        {
            return NSPredicate(format: "identifier = %@", NSNumber(value: primaryKeyValue!))
        }
        else
        {
            return nil
        }
    }
    
    private func fillFromDictionary(_ dictionary: [AnyHashable:Any])
    {
        let df = DateFormatter.uuCachedFormatter(UUDate.Formats.rfc3339)
        
        quote = dictionary["quote"] as? String
        identifier = Int64(dictionary["identifier"] as! Int)
        downloadedAt = df.date(from: dictionary["downloadedAt"] as! String)! as Date
        
        print("parsed: \(self)")
    }
    
    override public var description: String
    {
        return "\(toDictionary().uuToJsonString())"
    }
    
    public func toDictionary() -> [String:Any]
    {
        var json : [String:Any] = [:]
        
        json["id"] = identifier
        json["quote"] = quote
        json["downloadedAt"] = (downloadedAt as Date?)?.uuRfc3339String()
        json["displayedAt"] = (displayedAt as Date?)?.uuRfc3339String()
        json["displayCount"] = displayCount
        
        return json
    }
    
    static func randomQuote(_ context: NSManagedObjectContext) -> Self?
    {
        return randomQuoteInternal(context)
    }
    
    private static func randomQuoteInternal<T>(_ context: NSManagedObjectContext) -> T?
    {
        let predicate = NSPredicate(format: "displayCount = 0")
        
        let count = uuCountObjects(predicate: predicate, context: context)
        let index = arc4random_uniform(UInt32(count))
        
        let results = uuFetchObjects(predicate: predicate, offset: Int(index), limit: 1, context: context)
        if (results.count > 0)
        {
            return results[0] as? T
        }
        else
        {
            return nil
        }
    }
}
