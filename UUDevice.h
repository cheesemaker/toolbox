//
//  UUDevice.h
//  Useful Utilities - UIDevice extensions
//	Use this as a drop in replacement for the deprecated uniqueIdentifier
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//
//  Contact: @cheesemaker or jon@threejacks.com


#import <Foundation/Foundation.h>

@interface UIDevice(UUDevice)
	- (NSString*) uuUniqueIdentifier;
@end
