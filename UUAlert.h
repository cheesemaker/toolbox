//
//  UUAlert.h
//  Useful Utilities - UIAlertView extensions
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//
//  Contact: @cheesemaker or jon@threejacks.com

#import <UIKit/UIKit.h>

@interface UIAlertView (UUFramework)

+ (void) uuShowAlertWithTitle:(NSString *)alertTitle
                    message:(NSString *)alertMessage
					completionHandler:(void (^)(NSInteger buttonIndex))completionHandler;

- (id)initWithTitle:(NSString *)title message:(NSString *)message completionHandler:(void (^)(NSInteger buttonIndex))completionHandler buttonTitles:(NSString *)defaultButtonTitle, ...;

+ (id)uuOkCancelAlert:(NSString *)title message:(NSString *)message completionHandler:(void (^)(NSInteger buttonIndex))completionHandler;
+ (id)uuOneButtonAlert:(NSString *)title message:(NSString *)message button:(NSString*)button completionHandler:(void (^)(NSInteger buttonIndex))completionHandler;
+ (id)uuTwoButtonAlert:(NSString *)title message:(NSString *)message cancelButton:(NSString*)cancelButton otherButton:(NSString*)otherButton completionHandler:(void (^)(NSInteger buttonIndex))completionHandler;

@end
