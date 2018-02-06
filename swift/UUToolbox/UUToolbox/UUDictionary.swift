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
    
    
    public func uuToJsonString() -> String
    {
        let jsonData : Data? = uuToJson()
        var jsonStr : String? = nil
        
        if (jsonData != nil)
        {
            jsonStr = String.init(data: jsonData!, encoding: .utf8)
        }
        
        if (jsonStr == nil)
        {
            jsonStr = ""
        }
        
        return jsonStr!
    }
    
    public func uuToJson() -> Data?
    {
        var data : Data? = nil
        
        do
        {
            data = try JSONSerialization.data(withJSONObject: self, options: [])
        }
        catch
        {
            data = nil
        }
        
        
        return data
    }
}
