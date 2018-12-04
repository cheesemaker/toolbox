//
//  UURandom.swift
//  Useful Utilities - Handy helpers for generating random numbers and picking
//  random elements
//
//    License:
//  You are free to use this code for whatever purposes you desire.
//  The only requirement is that you smile everytime you use it.
//

import Foundation

public class UURandom
{
    public static func randomUInt32() -> UInt32
    {
        return arc4random()
    }
    
    public static func randomUInt32(low: UInt32, high: UInt32) -> UInt32
    {
        var l = low
        var h = high
        if (low > high)
        {
            let tmp = l
            l = h
            h = tmp
        }
        
        let range = h - l + 1
        let rand = arc4random_uniform(range)
        return (l + rand)
    }
    
    public static func randomBool() -> Bool
    {
        return randomUInt32() % 2 == 0
    }
    
    public static func randomBytes(length: Int) -> Data
    {
        guard let buffer = NSMutableData(length: length) else
        {
            return Data()
        }
        
        let result = SecRandomCopyBytes(kSecRandomDefault, length, buffer.mutableBytes)
        if (result != 0)
        {
            return Data()
        }
        
        return buffer as Data
    }
    
    public static func randomUInt8() -> UInt8
    {
        let bytes = randomBytes(length: 1)
        let byteArray = [UInt8](bytes)
        return byteArray[0]
    }
}
