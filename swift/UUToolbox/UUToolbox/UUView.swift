//  UUView
//  Useful Utilities - Helpful methods for UIView
//
//	License:
//  You are free to use this code for whatever purposes you desire.
//  The only requirement is that you smile everytime you use it.
//

import UIKit

extension UIView
{
    static let blurEffectViewTag : Int = 90210
    
    public func uuAddBlurEffectView()
    {
        uuRemoveBlurEffectView()
        
        let effect = UIBlurEffect(style: .light)
        let effectView = UIVisualEffectView.init(effect: effect)
        
        effectView.frame = self.bounds
        effectView.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]
        effectView.tag = UIView.blurEffectViewTag
        insertSubview(effectView, at: 0)
    }
    
    public func uuRemoveBlurEffectView()
    {
        self.superview?.viewWithTag(UIView.blurEffectViewTag)?.removeFromSuperview()
    }

	@IBInspectable public var uuCornerRadius: CGFloat
    {
		get
        {
			return layer.cornerRadius
		}
        
		set
        {
			layer.cornerRadius = newValue
			layer.masksToBounds = newValue > 0
		}
	}
	
	@IBInspectable public var uuBorderWidth: CGFloat
    {
		get
        {
			return layer.borderWidth
		}
        
		set
        {
			layer.borderWidth = newValue
		}
	}
	
	@IBInspectable public var uuBorderColor: UIColor?
    {
		get
        {
			let color = UIColor(cgColor: layer.borderColor!)
			return color
		}
        
		set
        {
			layer.borderColor = newValue?.cgColor
		}
	}
	
	@IBInspectable public var uuShadowRadius: CGFloat
    {
		get
        {
			return layer.shadowRadius
		}
        
		set
        {
			layer.shadowColor = UIColor.black.cgColor
			layer.shadowOffset = CGSize(width: 0, height: 2)
			layer.shadowOpacity = 0.35
			layer.shadowRadius = newValue
		}
	}
}
