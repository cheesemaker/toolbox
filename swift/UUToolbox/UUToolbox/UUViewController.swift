//
//  UUViewController.swift
//  Useful Utilities - Extensions for UIViewController
//
//    License:
//  You are free to use this code for whatever purposes you desire.
//  The only requirement is that you smile everytime you use it.
//

import UIKit

public extension UIViewController
{
    public func uuFindControllerOfType(_ clazz : AnyClass) -> UIViewController?
    {
        var foundVc : UIViewController? = nil
        
        var navController : UINavigationController? = (self as? UINavigationController)
        if (navController == nil)
        {
            navController = self.navigationController
        }
        
        if (navController != nil)
        {
            for vc in navController!.viewControllers
            {
                if (object_getClass(vc) == clazz)
                {
                    foundVc = vc
                    break
                }
            }
        }
        
        return foundVc
    }
    
    public func uuPopToControllerOfType(_ clazz : AnyClass, animated : Bool = true) -> Bool
    {
        let vcToPopTo = uuFindControllerOfType(clazz)
        
        let didFindController = (vcToPopTo != nil)
        
        if (didFindController)
        {
            navigationController?.popToViewController(vcToPopTo!, animated: animated)
        }
        
        return didFindController
    }
}
