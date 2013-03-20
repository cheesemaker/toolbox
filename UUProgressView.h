//
//  UUProgressView.h
//
//  Created by Jonathan on 3/19/13.
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//
//  Contact: @cheesemaker or jon@threejacks.com

#import <UIKit/UIKit.h>

@interface UUProgressView : UIView

- (void) show:(BOOL)animated;
- (void) hide:(BOOL)animated;
- (void) updateMessage:(NSString*)message;

+ (UUProgressView*) globalProgressView;

@end
