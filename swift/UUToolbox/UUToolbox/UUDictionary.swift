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
        var val = self[key] as? NSNumber
        
        if (val == nil)
        {
            if let str = uuSafeGetString(key)
            {
                let nf = NumberFormatter()
                nf.numberStyle = .decimal
                val = nf.number(from: str)
            }
        }
        
        return val
    }
    
    public func uuSafeGetBool(_ key: Key) -> Bool?
    {
        guard let num = uuSafeGetNumber(key) else
        {
            return nil
        }
        
        return num.boolValue
    }
    
    public func uuSafeGetInt(_ key: Key) -> Int?
    {
        guard let num = uuSafeGetNumber(key) else
        {
            return nil
        }
        
        return num.intValue
    }
    
    public func uuSafeGetUInt8(_ key: Key) -> UInt8?
    {
        guard let num = uuSafeGetNumber(key) else
        {
            return nil
        }
        
        return num.uint8Value
    }
    
    public func uuSafeGetUInt16(_ key: Key) -> UInt16?
    {
        guard let num = uuSafeGetNumber(key) else
        {
            return nil
        }
        
        return num.uint16Value
    }
    
    public func uuSafeGetUInt32(_ key: Key) -> UInt32?
    {
        guard let num = uuSafeGetNumber(key) else
        {
            return nil
        }
        
        return num.uint32Value
    }
    
    public func uuSafeGetUInt64(_ key: Key) -> UInt64?
    {
        guard let num = uuSafeGetNumber(key) else
        {
            return nil
        }
        
        return num.uint64Value
    }
    
    public func uuSafeGetInt8(_ key: Key) -> Int8?
    {
        guard let num = uuSafeGetNumber(key) else
        {
            return nil
        }
        
        return num.int8Value
    }
    
    public func uuSafeGetInt16(_ key: Key) -> Int16?
    {
        guard let num = uuSafeGetNumber(key) else
        {
            return nil
        }
        
        return num.int16Value
    }
    
    public func uuSafeGetInt32(_ key: Key) -> Int32?
    {
        guard let num = uuSafeGetNumber(key) else
        {
            return nil
        }
        
        return num.int32Value
    }
    
    public func uuSafeGetInt64(_ key: Key) -> Int64?
    {
        guard let num = uuSafeGetNumber(key) else
        {
            return nil
        }
        
        return num.int64Value
    }
    
    public func uuSafeGetFloat(_ key: Key) -> Float?
    {
        guard let num = uuSafeGetNumber(key) else
        {
            return nil
        }
        
        return num.floatValue
    }
    
    public func uuSafeGetDouble(_ key: Key) -> Double?
    {
        guard let num = uuSafeGetNumber(key) else
        {
            return nil
        }
        
        return num.doubleValue
    }
    
    public func uuSafeGetDictionary(_ key: Key) -> [AnyHashable:Any]?
    {
        return self[key] as? [AnyHashable:Any]
    }
    
    public func uuSafeGetObject<T: UUDictionaryConvertible>(type: T.Type, key: Key, context: Any? = nil) -> UUDictionaryConvertible?
    {
        guard let d = uuSafeGetDictionary(key) else
        {
            return nil
        }
        
        return T.create(from: d, context: context)
    }
    
    public func uuSafeGetDictionaryArray(_ key: Key) -> [[AnyHashable:Any]]?
    {
        return self[key] as? [[AnyHashable:Any]]
    }
    
    public func uuSafeGetObjectArray<T: UUDictionaryConvertible>(type: T.Type, key: Key, context: Any? = nil) -> [UUDictionaryConvertible]?
    {
        guard let array = uuSafeGetDictionaryArray(key) else
        {
            return nil
        }
        
        var list: [T] = []
        for d in array
        {
            list.append(T.create(from: d, context: context))
        }
        
        return list
    }
}

public protocol UUDictionaryConvertible
{
    init()
    
    func fill(from dictionary: [AnyHashable:Any], context: Any?)
    func toDictionary() -> [AnyHashable:Any]
}

public extension UUDictionaryConvertible
{
    public static func create(from dictionary : [AnyHashable:Any], context: Any?) -> Self
    {
        let obj = self.init()
        obj.fill(from: dictionary, context: context)
        return obj
    }
}
