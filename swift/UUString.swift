//
//  UUString.swift
//  Useful Utilities - Extensions for String
//
//	License:
//  You are free to use this code for whatever purposes you desire.
//  The only requirement is that you smile everytime you use it.
//

import Foundation

extension String
{
    // Access a sub string based on integer start index and integer length.
    //
    // If the end index is out of bounds, will return as many characters as
    // available up to the end of the string.
    //
    // Out of bounds indices are clamped to fit within range of the string.
    //
    public func uuSubString(_ from: Int, _ length: Int) -> String
    {
        var adjustedFrom = from
        if (adjustedFrom < 0)
        {
            adjustedFrom = 0
        }
        
        var adjustedLength = length
        if (adjustedLength > self.characters.count)
        {
            adjustedLength = self.characters.count
        }
        
        let start = self.index(self.startIndex, offsetBy: adjustedFrom, limitedBy: self.endIndex)
        var end = self.index(self.startIndex, offsetBy: (adjustedFrom + adjustedLength), limitedBy: self.endIndex)
        if (end == nil)
        {
            end = self.endIndex
        }
        
        if (start != nil && end != nil)
        {
            let range = start! ..< end!
            return self.substring(with: range)
        }
        
        return ""
    }
    
    // Returns the first N characters of the string
    public func uuFirstNChars(_ count: Int) -> String
    {
        return uuSubString(0, count)
    }
    
    // Returns the last N characters of the string
    public func uuLastNChars(_ count: Int) -> String
    {
        return uuSubString(characters.count - count, count)
    }
    
    private static let kUrlEncodingChars = "!*'();:@&=+$,/?%#[] "
    private static let kUrlEncodingCharSet = CharacterSet.init(charactersIn: kUrlEncodingChars).inverted
    
    // Percent encodes the following characters:
    //
    // !*'();:@&=+$,/?%#[]
    //
    public func uuUrlEncoded() -> String
    {
        var encoded : String? = addingPercentEncoding(withAllowedCharacters: String.kUrlEncodingCharSet)
        if (encoded == nil)
        {
            encoded = self
        }
        
        return encoded!
    }
    
    // Trim whitespace from beginning and end of string
    public func uuTrimWhitespace() -> String
    {
        return trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    
    // Parses this string as a decimal number
    public func uuAsDecimalNumber() -> NSNumber?
    {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return f.number(from: self)
    }
}
