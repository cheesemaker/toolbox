//
//  UUColor.swift
//  Useful Utilities - Extensions for UIColor
//
//  Created by Ryan DeVore on 10/29/2016
//
//	License:
//  You are free to use this code for whatever purposes you desire.
//  The only requirement is that you smile everytime you use it.
//
//  Contact: @ryandevore or ryan@silverpine.com

extension UIColor
{
    // Creates a UIColor object from a hex string in the form of
    //
    // RRGGBB or RRGGBBAA
    //
    static func uuColorFromHex(_ color: String) -> UIColor
    {
        var rgba : [CGFloat] = [0, 0, 0, 1]
        
        let len = color.lengthOfBytes(using: .utf8)
        if (len == 6 || len == 8)
        {
            var i = 0
            while (i < len)
            {
                let subStr = color.uuSubString(from: i, length: 2)
                
                let scanner = Scanner(string: subStr)
                
                var hex : UInt32 = 0
                if (scanner.scanHexInt32(&hex))
                {
                    rgba[i/2] = (CGFloat(hex) / 255.0)
                }
                
                i = i + 2
            }
        }
        
        let c = UIColor(red: rgba[0], green: rgba[1], blue: rgba[2], alpha: rgba[3])
        return c
    }
    
    // Calculates the midpoint value of each color component between two colors
    static func uuCalculateMidColor(startColor: UIColor, endColor: UIColor) -> UIColor
    {
        var startColors : [CGFloat] = [0, 0, 0, 0]
        startColor.getRed(&startColors[0], green: &startColors[1], blue: &startColors[2], alpha: &startColors[3])
        
        var endColors : [CGFloat] = [0, 0, 0, 0]
        endColor.getRed(&endColors[0], green: &endColors[1], blue: &endColors[2], alpha: &endColors[3])
        
        var midColors : [CGFloat] = [0, 0, 0, 0]
        
        var i = 0
        while (i < midColors.count)
        {
            midColors[i] = (startColors[i] + endColors[i]) / 2.0
            i = i + 1
        }
        
        let midColor = UIColor.init(red: midColors[0], green: midColors[1], blue: midColors[2], alpha: midColors[3])
        return midColor
    }
}
