//
//  UUCameraView.m
//  Useful Utilities - UUCameraView custom camera drop in view
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//
//  Contact: @cheesemaker or jon@threejacks.com


#import "UUCameraView.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <CoreVideo/CoreVideo.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h> 
#import <objc/message.h>


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

//If you want to provide your own logging mechanism, define UUDebugLog in your .pch
#ifndef UUDebugLog
	#ifdef DEBUG
		#define UUDebugLog(fmt, ...) NSLog(fmt, ##__VA_ARGS__)
	#else
		#define UUDebugLog(fmt, ...)
	#endif
#endif

@interface UUCameraView()
@property (nonatomic, retain)	AVCaptureSession* captureSession;
@property (nonatomic, retain)	AVCaptureVideoPreviewLayer* previewLayer;
@property (nonatomic, retain)	AVCaptureConnection* connection;
@property (nonatomic, retain)	AVCaptureDevice* device;
@property (nonatomic, retain)	AVCaptureStillImageOutput* stillOutput;
@property (assign)				CATransform3D transform;
@property (nonatomic, assign)	CGFloat cameraZoomValue;
@end

@implementation UUCameraView

- (id) initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	if (self)
	{
		self.zoomValue = 1.0;
		self.captureSession = UU_AUTORELEASE([[AVCaptureSession alloc] init]);

		NSString* setting = AVCaptureSessionPresetPhoto;
		self.captureSession.sessionPreset = setting;
		self.previewLayer = UU_AUTORELEASE([[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession]);
		[self.previewLayer setBackgroundColor:[[UIColor blackColor] CGColor]];
		[self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
		[self.previewLayer setFrame:self.frame];
		[self.layer addSublayer:self.previewLayer];
		self.transform = CATransform3DIdentity;
	
		[self setupSession:false];	
	}
	
	return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
	{
		self.zoomValue = 1.0;
		self.captureSession = UU_AUTORELEASE([[AVCaptureSession alloc] init]);
		NSString* setting = AVCaptureSessionPresetPhoto;
		self.captureSession.sessionPreset = setting;
		self.previewLayer = UU_AUTORELEASE([[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession]);
		[self.previewLayer setBackgroundColor:[[UIColor blackColor] CGColor]];
		[self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
		[self.previewLayer setFrame:frame];
		[self.layer addSublayer:self.previewLayer];
		self.transform = CATransform3DIdentity;
	
		[self setupSession:false];
    }
    return self;
}

- (void) startSession
{
	[self.captureSession startRunning];
}

- (void) stopSession
{
	[self.captureSession stopRunning];
}

- (void) setCameraFrame:(CGRect)frame
{
	self.previewLayer.frame = frame;
}

- (void) setCameraOrientation:(UIInterfaceOrientation)orientation;
{	
	if (orientation == UIDeviceOrientationPortrait)
		self.connection.videoOrientation = AVCaptureVideoOrientationPortrait;
	if (orientation == UIDeviceOrientationPortraitUpsideDown)
		self.connection.videoOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
	if (orientation == UIDeviceOrientationLandscapeLeft)
		self.connection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
	if (orientation == UIDeviceOrientationLandscapeRight)
		self.connection.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
}

// Delegate routine that is called when a sample buffer was written
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
	if (sampleBuffer)
	{
		CFRetain(sampleBuffer); //This gets CFRelease'd in processImage...
		[self processImage:[NSValue valueWithPointer:sampleBuffer]];
		//[NSThread detachNewThreadSelector:@selector(processImage:) toTarget:self withObject:[NSValue valueWithPointer:sampleBuffer]];
	}
	else
	{
		UUDebugLog(@"captureOutput called with no sample buffer");
	}
	
	[self.captureSession startRunning];
}

- (AVCaptureDevice *)createDevice:(bool)frontFacing  
{  
	if (!frontFacing)
		return [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
		
	//  look at all the video devices and get the first one that's on the front  
	NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];  
	for (AVCaptureDevice* aDevice in videoDevices)  
	{  
		if (aDevice.position == AVCaptureDevicePositionFront)
			return aDevice;
	}  

	return [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
}  

- (void) setupSession:(bool)frontFacing
{
	//Create the device...
	NSError *error = nil;
	self.device = [self createDevice:frontFacing];
	[self.device lockForConfiguration:&error];
	if ([self.device isFlashModeSupported:AVCaptureFlashModeAuto])
		self.device.flashMode = AVCaptureFlashModeAuto;
	[self.device unlockForConfiguration];
	
	//Hook an input up to the device...
	AVCaptureDeviceInput* input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:&error];
	if (input)
	{
		[self.captureSession addInput:input];

		//Create the still image output...
		self.stillOutput = UU_AUTORELEASE([[AVCaptureStillImageOutput alloc] init]);

		//Add the outputs to the capture session...
		[self.captureSession addOutput:self.stillOutput];
	
		//Configure our connection...
		self.connection = [self.stillOutput connectionWithMediaType:AVMediaTypeVideo];
		//self.connection.videoMaxFrameDuration= CMTimeMake(1, 10); //kCMTimeZero
		self.connection.videoOrientation = AVCaptureVideoOrientationPortrait;
	}
}


/*
- (UIImage *) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer
{
    // Get a CMSampleBuffer's Core Video image buffer for the media data
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer); 
    CVPixelBufferLockBaseAddress(imageBuffer, 0); 

    // Get the number of bytes per row for the pixel buffer
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer); 

    // Get the number of bytes per row for the pixel buffer
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer); 
    size_t width = CVPixelBufferGetWidth(imageBuffer); 
    size_t height = CVPixelBufferGetHeight(imageBuffer); 

	int x = 0;
	int y = 0;
	int scaledWidth = width / self.cameraZoomValue;
	int scaledHeight = height / self.cameraZoomValue;
	x += (width - scaledWidth) / 2;
	y += (height - scaledHeight) / 2;
	baseAddress += (y * bytesPerRow) + (4 * x);

    // Create a device-dependent RGB color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB(); 
    CGContextRef context = CGBitmapContextCreate(baseAddress, scaledWidth, scaledHeight, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
	
	CGImageRef quartzImage = CGBitmapContextCreateImage(context); 
	CVPixelBufferUnlockBaseAddress(imageBuffer,0);

	// Free up the context and color space
    CGContextRelease(context); 
    CGColorSpaceRelease(colorSpace);

    // Create an image object from the Quartz image
    UIImage *image = [UIImage imageWithCGImage:quartzImage scale:1.0 orientation:UIImageOrientationRight];
    CGImageRelease(quartzImage);
	return image;
}
*/

- (void) processImage:(NSValue*)sampleBuffer
{
	CMSampleBufferRef buffer = [sampleBuffer pointerValue];
	NSData* jpegData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:buffer];

	if (self.delegate && [self.delegate respondsToSelector:@selector(photoReady:)])
		[self.delegate performSelectorOnMainThread:@selector(photoReady:) withObject:jpegData waitUntilDone:YES];

	CFRelease(buffer);
}

- (void) setZoomValue:(CGFloat)zoom
{
	self.cameraZoomValue = zoom;
	self.transform = CATransform3DMakeScale(self.cameraZoomValue, self.cameraZoomValue, 1.0);
	self.layer.transform = self.transform;
}

- (void) setFocusPoint:(CGPoint)focalPoint
{
	NSError* error;
	if ([self.device isFocusPointOfInterestSupported] && [self.device lockForConfiguration:&error])
	{
		self.device.focusPointOfInterest = focalPoint;

		if ([self.device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus])
			self.device.focusMode = AVCaptureFocusModeContinuousAutoFocus;

		[self.device unlockForConfiguration];
	}
	
	if ([self.device isExposurePointOfInterestSupported] && [self.device lockForConfiguration:&error])
	{
		self.device.exposurePointOfInterest = focalPoint;
		if ([self.device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure])
			self.device.exposureMode = AVCaptureExposureModeContinuousAutoExposure;

		[self.device unlockForConfiguration];		
	}
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Torch
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (bool) torchOn
{
	bool on = false;
	NSError* error;
	if ([self.device hasTorch] && [self.device lockForConfiguration:&error])
	{
		on = (self.device.torchMode == AVCaptureTorchModeOn);
		[self.device unlockForConfiguration];
	}
	
	return on;
}

- (void) setTorchOn:(bool)torchActive
{
	NSError* error;
	if ([self.device hasTorch] && [self.device lockForConfiguration:&error])
	{
		if (torchActive)
		{
			self.device.torchMode = AVCaptureTorchModeOn;
		}
		else
		{
			self.device.torchMode = AVCaptureTorchModeOff;
		}
		[self.device unlockForConfiguration];
	}
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Flash
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (int) flashMode
{
	AVCaptureFlashMode flashMode = AVCaptureFlashModeOff;
	NSError* error;
	if ([self.device isFlashAvailable] && [self.device lockForConfiguration:&error])
	{
		flashMode = self.device.flashMode;
		[self.device unlockForConfiguration];
	}
	
	if (flashMode == AVCaptureFlashModeAuto)
		return kUUFlashAuto;
	if (flashMode == AVCaptureFlashModeOn)
		return kUUFlashOn;
	
	return kUUFlashOff;
}

- (void) setFlashMode:(int)inFlashMode
{
	NSError* error;
	if ([self.device isFlashAvailable] && [self.device lockForConfiguration:&error])
	{
		AVCaptureFlashMode flashMode = AVCaptureFlashModeOff;
		if (inFlashMode == kUUFlashAuto)
			flashMode = AVCaptureFlashModeAuto;
		else if (inFlashMode == kUUFlashOn)
			flashMode = AVCaptureFlashModeOn;
			
		if ([self.device isFlashModeSupported:flashMode])
			self.device.flashMode = flashMode;
		
		[self.device unlockForConfiguration];
	}
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Toggling front/back camera
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (void) setToFrontFacingCamera
{
	if (self.device.position == AVCaptureDevicePositionFront)
		return;

	AVCaptureDevicePosition desiredPosition = AVCaptureDevicePositionFront;
	
	for (AVCaptureDevice* aDevice in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) 
	{
		if ([aDevice position] == desiredPosition)
		{
			[[self.previewLayer session] beginConfiguration];
			AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:aDevice error:nil];
			for (AVCaptureInput *oldInput in [[self.previewLayer session] inputs])
			{
				[[self.previewLayer session] removeInput:oldInput];
			}
			self.device = aDevice;
			[[self.previewLayer session] addInput:input];
			[[self.previewLayer session] commitConfiguration];
			break;
		}
	}
}

- (void) setToBackFacingCamera
{
	if (self.device.position == AVCaptureDevicePositionBack)
		return;

	AVCaptureDevicePosition desiredPosition = AVCaptureDevicePositionBack;
	
	for (AVCaptureDevice* aDevice in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) 
	{
		if ([aDevice position] == desiredPosition)
		{
			[[self.previewLayer session] beginConfiguration];
			AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:aDevice error:nil];
			for (AVCaptureInput *oldInput in [[self.previewLayer session] inputs])
			{
				[[self.previewLayer session] removeInput:oldInput];
			}
			self.device = aDevice;
			[[self.previewLayer session] addInput:input];
			[[self.previewLayer session] commitConfiguration];
			break;
		}
	}
}

- (void) takePicture
{
	[self.stillOutput captureStillImageAsynchronouslyFromConnection:self.connection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error)
	{
		[self.captureSession stopRunning];

		if (!error)
		{
			[self captureOutput:self.stillOutput didOutputSampleBuffer:imageDataSampleBuffer fromConnection:self.connection];
		}
		else
		{
			UUDebugLog(@"Received error from capture = %@", [error localizedDescription]);
		}
	}];
}


@end
