//
//  UUOpenALSoundManager.h
//  Useful Utilities - OpenAL wrapper
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//
//  Contact: @cheesemaker or jon@threejacks.com

#import <Foundation/Foundation.h>
#
@interface UUOpenALSoundClip : NSObject 
	- (void) playSound:(float)volume;
@end

@interface UUOpenALSoundManager : NSObject

// Static Interface
+ (UUOpenALSoundManager*) sharedSoundManager;

// Instance Interface
- (bool) isOtherMusicPlaying;
- (void) disableOtherMusicPlaying;
- (UUOpenALSoundClip*) soundClipFromResource:(NSString*)file Ext:(NSString*)ext;

@end
