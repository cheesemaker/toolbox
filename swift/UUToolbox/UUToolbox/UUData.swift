//
//  UUData.swift
//  Useful Utilities - Extensions for Data
//
//	License:
//  You are free to use this code for whatever purposes you desire.
//  The only requirement is that you smile everytime you use it.
//

import Foundation

public extension Data
{
    // Return hex string representation of data
    //
    public func uuToHexString() -> String
    {
        let sb : NSMutableString = NSMutableString()
        
        if (self.count > 0)
        {
            for index in 0...(self.count - 1)
            {
                sb.appendFormat("%02X", self[index])
            }
        }
        
        return sb as String
    }
    
    // Return JSON object of the data
    //
    public func uuToJson() -> Any?
    {
        do
        {
            return try JSONSerialization.jsonObject(with: self, options: [])
        }
        catch (let err)
        {
            UUDebugLog("Error deserializing JSON: %@", String(describing: err))
        }
        
        return nil
    }
    
    // Returns JSON string representation of the data
    //
    public func uuToJsonString() -> String
    {
        let json = uuToJson()
        return String(format: "%@", (json as? CVarArg) ?? "")
    }
}
