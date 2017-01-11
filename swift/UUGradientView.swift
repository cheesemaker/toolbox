//
//  UUGradientView.swift
//  Useful Utilities - Simple UIView subclass to draw a gradient background color
//
//  Created by Ryan DeVore on 10/29/2016
//
//	License:
//  You are free to use this code for whatever purposes you desire.
//  The only requirement is that you smile everytime you use it.
//
//  Contact: @ryandevore or ryan@silverpine.com
//

import UIKit

public enum UUGradientDirection : Int
{
    case horizontal
    case vertical
}

// This class is a simple UIView subclass that draws a gradient background using
// two colors.
//
//
@IBDesignable public class UUGradientView : UIView
{
    @IBInspectable public var startColor : UIColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        {
        didSet
        {
            self.setNeedsDisplay()
        }
    }
    
    @IBInspectable public var endColor : UIColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
        {
        didSet
        {
            self.setNeedsDisplay()
        }
    }
    
    @IBInspectable public var midPoint : Float = 0.5
        {
        didSet
        {
            self.setNeedsDisplay()
        }
    }
    
    public var direction : UUGradientDirection = .horizontal
    {
        didSet
        {
            self.setNeedsDisplay()
        }
    }
    
    public var transparentClipRect : CGRect = CGRect.zero
    {
        didSet
        {
            self.setNeedsDisplay()
            self.isOpaque = false
        }
    }
    
    @IBInspectable public var directionAdapter : Int
    {
        get
        {
            return self.direction.rawValue
        }
        
        set( val)
        {
            self.direction = UUGradientDirection(rawValue: val) ?? .horizontal
        }
    }
    
    override required public init(frame: CGRect)
    {
        super.init(frame: frame)
    }
    
    required public init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
    }
    
    override public func draw(_ rect: CGRect)
    {
        let context = UIGraphicsGetCurrentContext()!
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        let midColor = UIColor.uuCalculateMidColor(startColor: self.startColor, endColor: self.endColor)
        
        let colors : [CGColor] = [ self.startColor.cgColor, midColor.cgColor, self.endColor.cgColor ]
        let locations : [CGFloat] = [ 0.0, CGFloat(self.midPoint), 1.0 ]
        
        let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: locations)!
        
        var startPoint = CGPoint(x: rect.minX, y: rect.midY)
        var endPoint = CGPoint(x: rect.maxX, y: rect.midY)
        
        if (self.direction == .vertical)
        {
            startPoint = CGPoint(x: rect.midX, y: rect.minY)
            endPoint = CGPoint(x: rect.midX, y: rect.maxY)
        }
        
        context.saveGState()
        context.addRect(rect)
        context.clip()
        context.drawLinearGradient(gradient, start: startPoint, end: endPoint, options: CGGradientDrawingOptions(rawValue: 0))
        
        context.restoreGState()
        
        context.clear(transparentClipRect)
    }
}
