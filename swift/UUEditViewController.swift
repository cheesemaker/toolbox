//
//  UUEditViewController
//  Useful Utilities - Subclass of UIViewController that handles automatically
//  some common editing tasks
//
//	License:
//  You are free to use this code for whatever purposes you desire.
//  The only requirement is that you smile everytime you use it.
//
//  UUEditViewController has two main functions:
//
//  1) Handles taps to the root view and ends editing
//  2) Handles keyboard show/hide notifications and moves the view frame to
//     place the edit field right above the keyboard

import UIKit

class UUEditViewController : UIViewController
{
    var currentEditFieldFrame: CGRect? = nil
    var spaceToKeybaord : CGFloat = 10
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleBackgroundTap)))
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        registerNotificationHandlers()
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        clearNotificationHandlers()
    }
    
    func referenceViewForEditField(_ textField: UITextField) -> UIView
    {
        return textField
    }
    
    func registerNotificationHandlers()
    {
        NotificationCenter.default.addObserver(forName: Notification.Name.UIKeyboardWillShow, object: nil, queue: nil, using: handleKeyboardWillShowNotification)
        NotificationCenter.default.addObserver(forName: Notification.Name.UIKeyboardWillHide, object: nil, queue: nil, using: handleKeyboardWillHideNotification)
    }
    
    func clearNotificationHandlers()
    {
        NotificationCenter.default.removeObserver(self, name: Notification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func handleBackgroundTap()
    {
        view.endEditing(true)
    }
    
    func handleKeyboardWillShowNotification(_ notification: Notification)
    {
        let keyboardFrame = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? CGRect
        
        if (keyboardFrame != nil && currentEditFieldFrame != nil)
        {
            let keyboardTop = keyboardFrame!.origin.y
            let fieldBottom = currentEditFieldFrame!.origin.y + currentEditFieldFrame!.size.height
            
            if (keyboardTop < fieldBottom)
            {
                let keyboardAdjust = fieldBottom - keyboardTop + spaceToKeybaord
                
                var f = view.frame
                f.origin.y = -keyboardAdjust
                
                UIView.animate(withDuration: 0.5, animations:
                    {
                        self.view.frame = f
                })
            }
        }
    }
    
    func handleKeyboardWillHideNotification(_ notification: Notification)
    {
        var f = view.frame
        f.origin.y = 0
        
        UIView.animate(withDuration: 0.5, animations:
        {
            self.view.frame = f
        })
    }
}

extension UUEditViewController : UITextFieldDelegate
{
    func textFieldDidBeginEditing(_ textField: UITextField)
    {
        currentEditFieldFrame = referenceViewForEditField(textField).frame
    }
    
    func textFieldDidEndEditing(_ textField: UITextField)
    {
        currentEditFieldFrame = nil
    }
}
