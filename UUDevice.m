//
//  UUDevice.m
//		Apple has announced it will stop accepting Apps that use the old UIDevice uniqueIdentifier aka UDID. This is a drop in replacement.
//		On iOS 6.0.1 and greater, it will use the new identifierForVendor but for previous OS versions it will create a unique identifier
//		and persist it using user defaults and the Pasteboard which will allow it to survive App deletions, reboots and OS upgrades.
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//
//	Questions/comments/complaints:
//		contact: @cheesemaker or jon@threejacks.com


#import "UUDevice.h"

#if __has_feature(objc_arc)
	#define UU_RELEASE(x)		(void)(0)
	#define UU_RETAIN(x)		x
	#define UU_AUTORELEASE(x)	x
	#define UU_BLOCK_RELEASE(x) (void)(0)
	#define UU_BLOCK_COPY(x)    [x copy]
	#define UU_NATIVE_CAST(x)	(__bridge x)
#else
	#define UU_RELEASE(x)		[x release]
	#define UU_RETAIN(x)		[x retain]
	#define UU_AUTORELEASE(x)	[(x) autorelease]
	#define UU_BLOCK_RELEASE(x) Block_release(x)
	#define UU_BLOCK_COPY(x)    Block_copy(x)
	#define UU_NATIVE_CAST(x)	(x)
#endif


@implementation UIDevice (UUDevice)

#define UU_UIDEVICE_UNIQUE_IDENTIFIER @"UU::UIDevice::UniqueUserIdentifier"

+(NSString*) uuUniqueUserIdentifierFromPasteBoard
{
	UIPasteboard* pasteBoard = [UIPasteboard pasteboardWithName:UU_UIDEVICE_UNIQUE_IDENTIFIER create:NO];
	id item = [pasteBoard dataForPasteboardType:UU_UIDEVICE_UNIQUE_IDENTIFIER];
	if(item)
		return [NSString stringWithString:[NSKeyedUnarchiver unarchiveObjectWithData:item]];

	return nil;
}

+(void) uuSaveUniqueUserIdentifierToPasteBoard:(NSString*)uniqueID
{
	UIPasteboard* pasteBoard = [UIPasteboard pasteboardWithName:UU_UIDEVICE_UNIQUE_IDENTIFIER create:YES];
	[pasteBoard setPersistent:YES];
	[pasteBoard setData:[NSKeyedArchiver archivedDataWithRootObject:uniqueID] forPasteboardType:UU_UIDEVICE_UNIQUE_IDENTIFIER];
}

+ (void) uuSaveUniqueUserIdentifierToUserDefaults:(NSString*)uniqueID
{
	[[NSUserDefaults standardUserDefaults] setObject:uniqueID forKey:UU_UIDEVICE_UNIQUE_IDENTIFIER];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSString*)uuUniqueUserIdentifierFromUserDefaults
{
	return [[NSUserDefaults standardUserDefaults] stringForKey:UU_UIDEVICE_UNIQUE_IDENTIFIER];
}

+ (NSString*) uuGenerateUniqueIdentifier
{
	CFUUIDRef uuid = CFUUIDCreate(NULL);
	NSString* uniqueID = UU_NATIVE_CAST(NSString*)CFUUIDCreateString(NULL, uuid);
	CFRelease(uuid);

	return UU_AUTORELEASE(uniqueID);
}

- (NSString*) uuUniqueIdentifierOS5
{
	NSString* uniqueID = nil;

	NSString* uniqueUserDefaults = [UIDevice uuUniqueUserIdentifierFromUserDefaults];
	NSString* uniquePasteBoardDefaults = [UIDevice uuUniqueUserIdentifierFromPasteBoard];

	//If either of them are valid, pick one, otherwise generate a new one...
	if (uniqueUserDefaults)
		uniqueID = uniqueUserDefaults;
	else if (uniquePasteBoardDefaults)
		uniqueID = uniquePasteBoardDefaults;
	else
		uniqueID = [UIDevice uuGenerateUniqueIdentifier];

	//If user defaults doesn't exist, update it...
	if (!uniqueUserDefaults)
		[UIDevice uuSaveUniqueUserIdentifierToUserDefaults:uniqueID];

	//If pasteboard doesn't exist, update it...
	if (!uniquePasteBoardDefaults)
		[UIDevice uuSaveUniqueUserIdentifierToPasteBoard:uniqueID];

	//Special case. If user defaults got restored from iCloud and somehow a pasteboard value existed, overwrite pasteboard with user defaults since user defaults existed first
	if (uniqueUserDefaults && uniquePasteBoardDefaults && (![uniqueUserDefaults isEqualToString:uniquePasteBoardDefaults]))
		[UIDevice uuSaveUniqueUserIdentifierToPasteBoard:uniqueUserDefaults];

	return uniqueID;
}

- (NSString*) uuUniqueIdentifier
{
	UIDevice* device = [UIDevice currentDevice];

	// Work-around for: http://www.openradar.me/13555259
	static bool isBuggyVersion = false;
	static bool isBuggyVersionInitialized = false;
	if (!isBuggyVersionInitialized)
	{
		static NSString* buggyVersion = @"6.0";
		isBuggyVersionInitialized = true;
		isBuggyVersion = [[device systemVersion] compare:buggyVersion options:NSNumericSearch] == NSOrderedSame;
	}
	if (isBuggyVersion)
		return [device uuUniqueIdentifierOS5];
	// End of work-around

	if ([device respondsToSelector:@selector(identifierForVendor)])
	{
		NSUUID* uuid = [device identifierForVendor];
		if (uuid)
		{
			NSString* identifier = [uuid UUIDString];
			if (identifier)
				return identifier;
		}
	}
	
	return [device uuUniqueIdentifierOS5];
}

@end
