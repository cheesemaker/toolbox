//
//  UUDevice.h
//		Apple has announced it will stop accepting Apps that use the old UIDevice uniqueIdentifier aka UDID. This is a drop in replacement.
//		On iOS 6.0.1 and greater, it will use the new identifierForVendor but for previous OS versions it will create a unique identifier
//		and persist it using user defaults and the Pasteboard which will allow it to survive App deletions, reboots and OS upgrades.
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//
//	Questions/comments/complaints:
//		contact: @cheesemaker or jon@threejacks.com

#import <UIKit/UIKit.h>

@interface UIDevice(UUDevice)
	- (NSString*) uuUniqueIdentifier;
@end
