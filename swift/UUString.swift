//
//  UUString.swift
//  Useful Utilities - Extensions for String
//
//  Created by Ryan DeVore on 10/29/2016
//
//	License:
//  You are free to use this code for whatever purposes you desire.
//  The only requirement is that you smile everytime you use it.
//
//  Contact: @ryandevore or ryan@silverpine.com
//

extension String
{
    // Access a sub string based on integer start index and integer length. 
    // 
    // Returns an empty string if arguments result in out of bounds ranges.
    //
    func uuSubString(from: Int, length: Int) -> String
    {
        if (from >= 0 && length > 0)
        {
            let start = self.index(self.startIndex, offsetBy: from, limitedBy: self.endIndex)
            let end = self.index(self.startIndex, offsetBy: (from + length), limitedBy: self.endIndex)
            if (start != nil && end != nil)
            {
                let range = start! ..< end!
                return self.substring(with: range)
            }
        }
        
        return ""
    }
}
