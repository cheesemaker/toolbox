//
//  UUData.swift
//  Useful Utilities - Extensions for Data
//
//  Created by Ryan DeVore on 10/29/2016
//
//	License:
//  You are free to use this code for whatever purposes you desire.
//  The only requirement is that you smile everytime you use it.
//
//  Contact: @ryandevore or ryan@silverpine.com
//

import Foundation

extension Data
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
}

/*
- (NSString*) uuToHexString
    {
        NSMutableString* sb = [NSMutableString string];
        
        const char* rawData = [self bytes];
        int count = (int)self.length;
        for (int i = 0; i < count; i++)
        {
            [sb appendFormat:@"%02X", (UInt8)rawData[i]];
        }
        
        return sb;
}*/
