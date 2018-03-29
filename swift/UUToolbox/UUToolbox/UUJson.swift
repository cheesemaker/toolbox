//
//  UUJson.swift
//  Useful Utilities - JSON Extensions for a variety of objects
//
//    License:
//  You are free to use this code for whatever purposes you desire.
//  The only requirement is that you smile everytime you use it.
//

import Foundation

public extension NSObject
{
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

public extension Dictionary
{
    public func uuToJsonString() -> String
    {
        return (self as NSObject).uuToJsonString()
    }
    
    public func uuToJson() -> Data?
    {
        return (self as NSObject).uuToJson()
    }
}

public extension Array
{
    public func uuToJsonString() -> String
    {
        return (self as NSObject).uuToJsonString()
    }
    
    public func uuToJson() -> Data?
    {
        return (self as NSObject).uuToJson()
    }
}
