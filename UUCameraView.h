//
//  UUCameraView.h
//  Useful Utilities - UUCameraView custom camera drop in view
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//
//  Contact: @cheesemaker or jon@threejacks.com

#import <UIKit/UIKit.h>

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

#define kUUFlashOff		0
#define kUUFlashOn		1
#define kUUFlashAuto	2

@protocol UUCameraDelegate
@optional
	- (void) photoReady:(NSDate*)imageData;
@end

@interface UUCameraView : UIView<AVCaptureVideoDataOutputSampleBufferDelegate>

- (void) startSession;
- (void) stopSession;

- (void) setFocusPoint:(CGPoint)focalPoint;

- (void) setZoomValue:(CGFloat)zoom;

- (void) setToBackFacingCamera;
- (void) setToFrontFacingCamera;

- (void) takePicture;

- (void) setCameraFrame:(CGRect)frame;
- (void) setCameraOrientation:(UIInterfaceOrientation)orientation;

@property (assign) bool torchOn;
@property (assign) int	flashMode;

@property (nonatomic, assign) NSObject<UUCameraDelegate>* delegate;

@end