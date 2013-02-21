//
//  UUAlert.h
//  Useful Utilities - UIAlertView extensions
//
//  Copyright (c) 2011 Three Jacks Software, Inc. All rights reserved.
//
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//
//  Contact: @cheesemaker or jon@threejacks.com

#import <UIKit/UIKit.h>

@interface UIAlertView (UUFramework)

+ (void) showAlertWithTitle:(NSString *)alertTitle 
                    message:(NSString *)alertMessage 
                   delegate:(id <UIAlertViewDelegate>)delegate;

+ (void) showAlertWithTitle:(NSString *)alertTitle 
                    message:(NSString *)alertMessage 
                  completionHandler:(void (^)(NSInteger buttonIndex))completionHandler;

- (id)initWithTitle:(NSString *)title message:(NSString *)message completionHandler:(void (^)(NSInteger buttonIndex))completionHandler buttonTitles:(NSString *)defaultButtonTitle, ...;

+ (id)okCancelAlert:(NSString *)title message:(NSString *)message completionHandler:(void (^)(NSInteger buttonIndex))completionHandler;
+ (id)oneButtonAlert:(NSString *)title message:(NSString *)message button:(NSString*)button completionHandler:(void (^)(NSInteger buttonIndex))completionHandler;
+ (id)twoButtonAlert:(NSString *)title message:(NSString *)message buttonOne:(NSString*)buttonOne buttonTwo:(NSString*)buttonTwo completionHandler:(void (^)(NSInteger buttonIndex))completionHandler;

@end
