//
//  UUDevice.m
//  Useful Utilities - UIDevice extensions
//
//  Created by Jonathan on 1/27/13.
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//

#import "UUDevice.h"

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
	NSString* uniqueID = (NSString*)CFUUIDCreateString(NULL, uuid);
	CFRelease(uuid);

	return [uniqueID autorelease];
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
