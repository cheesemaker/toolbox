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

//Show a simple one button alert
+ (void) uuShowAlertWithTitle:(NSString*)alertTitle
                      message:(NSString*)alertMessage
                  buttonTitle:(NSString*)buttonTitle
            completionHandler:(void (^)(NSInteger buttonIndex))completionHandler;

//Variadic constructor for N number of buttons
- (instancetype) initWithTitle:(NSString *)title
                       message:(NSString *)message
             completionHandler:(void (^)(NSInteger buttonIndex))completionHandler
                  buttonTitles:(NSString *)defaultButtonTitle, ...;

//Convenience functions
+ (instancetype) uuOKCancelAlert:(NSString *)title message:(NSString *)message completionHandler:(void (^)(NSInteger buttonIndex))completionHandler;
+ (instancetype) uuOneButtonAlert:(NSString *)title message:(NSString *)message button:(NSString*)button completionHandler:(void (^)(NSInteger buttonIndex))completionHandler;
+ (instancetype) uuTwoButtonAlert:(NSString *)title message:(NSString *)message buttonOne:(NSString*)buttonOne buttonTwo:(NSString*)buttonTwo completionHandler:(void (^)(NSInteger buttonIndex))completionHandler;

+ (void) uuShowOKCancelAlert:(NSString *)title message:(NSString *)message completionHandler:(void (^)(NSInteger buttonIndex))completionHandler;
+ (void) uuShowOneButtonAlert:(NSString *)title message:(NSString *)message button:(NSString*)button completionHandler:(void (^)(NSInteger buttonIndex))completionHandler;
+ (void) uuShowTwoButtonAlert:(NSString *)title message:(NSString *)message buttonOne:(NSString*)buttonOne buttonTwo:(NSString*)buttonTwo completionHandler:(void (^)(NSInteger buttonIndex))completionHandler;

@end
