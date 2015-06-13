//
//  UUCompression.h
//  Useful Utilities - Compression extensions
//
//	Smile License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//
//  Contact: @cheesemaker or jon@threejacks.com

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, UUCompressionAlgorithm)
{
    UUCompressionAlgorithmRaw,
    UUCompressionAlgorithmZlib,
    UUCompressionAlgorithmGZip,
};

typedef NS_ENUM(NSUInteger, UUCompressionLevel)
{
    UUCompressionLevelNone      = 0,
    UUCompressionLevelFastest   = 1,
    UUCompressionLevelBest      = 9,
};

///////////////////////////////////////////////////////////////////////////////////////////////////////////
// Data Compression
@interface NSData (UUDataCompression)

// Performs an in-memory compression of the data using the algorithm specified.
- (NSData*) uuCompress:(UUCompressionAlgorithm)algorithm level:(UUCompressionLevel)level;

// Performs an automatic decompression of the data using automatic algorithm detection.
- (NSData*) uuDecompress;

@end
