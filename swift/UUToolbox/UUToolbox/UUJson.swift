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
    public func uuToJsonString(_ prettyPrinted: Bool = false) -> String
    {
        let jsonData : Data? = uuToJson(prettyPrinted)
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
    
    public func uuToJson(_ prettyPrinted: Bool = false) -> Data?
    {
        var data : Data? = nil
        
        do
        {
            let writingOptions: JSONSerialization.WritingOptions = prettyPrinted ? [ JSONSerialization.WritingOptions.prettyPrinted ]  : []
            
            data = try JSONSerialization.data(withJSONObject: self, options: writingOptions)
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
    public func uuToJsonString(_ prettyPrinted: Bool = false) -> String
    {
        return (self as NSObject).uuToJsonString(prettyPrinted)
    }
    
    public func uuToJson(_ prettyPrinted: Bool = false) -> Data?
    {
        return (self as NSObject).uuToJson(prettyPrinted)
    }
}

public extension Array
{
    public func uuToJsonString(_ prettyPrinted: Bool = false) -> String
    {
        return (self as NSObject).uuToJsonString(prettyPrinted)
    }
    
    public func uuToJson(_ prettyPrinted: Bool = false) -> Data?
    {
        return (self as NSObject).uuToJson(prettyPrinted)
    }
}
