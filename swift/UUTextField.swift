//
//  UUTextField
//  Useful Utilities - Simple UITextField subclass to support a few IBDesignable additions
//
//  Created by Ryan DeVore on 01/27/2017
//
//	License:
//  You are free to use this code for whatever purposes you desire.
//  The only requirement is that you smile everytime you use it.
//
//  Contact: @ryandevore or ryan@silverpine.com
//

import UIKit

@IBDesignable class UUTextField: UITextField
{
    @IBInspectable public var leftPadding : CGFloat = 0
    {
        didSet
        {
            self.setNeedsDisplay()
        }
    }
    
    @IBInspectable public var rightPadding : CGFloat = 0
    {
        didSet
        {
            self.setNeedsDisplay()
        }
    }
    
    @IBInspectable public var topPadding : CGFloat = 0
    {
        didSet
        {
            self.setNeedsDisplay()
        }
    }
    
    @IBInspectable public var bottomPadding : CGFloat = 0
    {
        didSet
        {
            self.setNeedsDisplay()
        }
    }
    
    private var paddingRect : UIEdgeInsets
    {
        return UIEdgeInsets(top: topPadding, left: leftPadding, bottom: bottomPadding, right: rightPadding)
    }
    
    override func textRect(forBounds bounds: CGRect) -> CGRect
    {
        return UIEdgeInsetsInsetRect(bounds, paddingRect)
    }
    
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect
    {
        return UIEdgeInsetsInsetRect(bounds, paddingRect)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect
    {
        return UIEdgeInsetsInsetRect(bounds, paddingRect)
    }
}
