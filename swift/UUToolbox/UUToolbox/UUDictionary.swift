//
//  UUDictionary.swift
//  Useful Utilities - Extensions for Dictionary
//
//	License:
//  You are free to use this code for whatever purposes you desire.
//  The only requirement is that you smile everytime you use it.
//

import Foundation

public extension Dictionary
{
    public func uuBuildQueryString() -> String
    {
        let sb : NSMutableString = NSMutableString()
        
        for key in keys
        {
            var prefix = "&"
            if ((sb as String).count == 0)
            {
                prefix = "?"
            }
            
            let rawVal = self[key]
            var val : String? = nil
            
            if (rawVal is String)
            {
                val = rawVal as? String
            }
            else if (rawVal is NSNumber)
            {
                val = (rawVal as? NSNumber)?.stringValue
            }
            
            if (key is String && val != nil)
            {
                let formattedKey = (key as! String).uuUrlEncoded()
                let formattedVal = val!.uuUrlEncoded()
                
                sb.appendFormat("%@%@=%@", prefix, formattedKey, formattedVal)
            }
            
        }
        
        return sb as String!
    }
    
    public func uuSafeGetDate(_ key: Key, formatter: DateFormatter) -> Date?
    {
        guard let stringVal = self[key] as? String else
        {
            return nil
        }
        
        return formatter.date(from: stringVal)
    }
    
    public func uuSafeGetString(_ key: Key) -> String?
    {
        return self[key] as? String
    }
    
    public func uuSafeGetNumber(_ key: Key) -> NSNumber?
    {
        return self[key] as? NSNumber
    }
    
    public func uuSafeGetBool(_ key: Key) -> Bool?
    {
        return self[key] as? Bool
    }
    
    public func uuSafeGetInt(_ key: Key) -> Int?
    {
        return self[key] as? Int
    }
    
    public func uuSafeGetUInt8(_ key: Key) -> UInt8?
    {
        return self[key] as? UInt8
    }
    
    public func uuSafeGetUInt16(_ key: Key) -> UInt16?
    {
        return self[key] as? UInt16
    }
    
    public func uuSafeGetUInt32(_ key: Key) -> UInt32?
    {
        return self[key] as? UInt32
    }
    
    public func uuSafeGetUInt64(_ key: Key) -> UInt64?
    {
        return self[key] as? UInt64
    }
    
    public func uuSafeGetInt8(_ key: Key) -> Int8?
    {
        return self[key] as? Int8
    }
    
    public func uuSafeGetInt16(_ key: Key) -> Int16?
    {
        return self[key] as? Int16
    }
    
    public func uuSafeGetInt32(_ key: Key) -> Int8?
    {
        return self[key] as? Int8
    }
    
    public func uuSafeGetInt64(_ key: Key) -> Int64?
    {
        return self[key] as? Int64
    }
    
    public func uuSafeGetFloat(_ key: Key) -> Float?
    {
        return self[key] as? Float
    }
    
    public func uuSafeGetDouble(_ key: Key) -> Double?
    {
        return self[key] as? Double
    }
}
