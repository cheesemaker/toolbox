//
//  UUActionSheet.h
//  Useful Utilities - UIActionSheet extensions
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//
//  Contact: @cheesemaker or jon@threejacks.com


#import <UIKit/UIKit.h>

typedef void (^UUActionSheetDelegateBlock)(UIActionSheet* sheet, NSInteger buttonIndex);

@interface UIActionSheet (UUFramework)

// Variable list custructor for an N button Action Sheet
- (instancetype) initWithTitle:(NSString*)title
                    completion:(UUActionSheetDelegateBlock)completion
                  cancelButton:(NSString*)cancelButton
             destructiveButton:(NSString*)destructiveButton
                  otherButtons:(NSString*)otherButtons, ... NS_REQUIRES_NIL_TERMINATION;

// Convenience method
+ (instancetype) uuTwoButtonSheet:(NSString*)title
                     cancelButton:(NSString*)cancelButton
                destructiveButton:(NSString*)destructiveButton
                       completion:(UUActionSheetDelegateBlock)completion;


@end
