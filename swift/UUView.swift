//  UUView
//  Useful Utilities - Helpful methods for UIView
//
//  Created by Ryan DeVore on 01/29/2017
//
//	License:
//  You are free to use this code for whatever purposes you desire.
//  The only requirement is that you smile everytime you use it.
//
//  Contact: @ryandevore or ryan@silverpine.com
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

}
