//
//  UUCompression.m
//  Useful Utilities - Compression extensions
//
//	Smile License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//
//  Contact: @cheesemaker or jon@threejacks.com

#import "UUCompression.h"
#import <zlib.h>

#define UUDebugLog(fmt, ...)

// Uncomment to emit debug logging
//#define UUDebugLog(fmt, ...) NSLog(fmt, ##__VA_ARGS__)

#define UU_RAW_ENCODING_WINDOW_BITS         (-MAX_WBITS)
#define UU_ZLIB_ENCODING_WINDOW_BITS        (MAX_WBITS )
#define UU_GZIP_ENCODING_WINDOW_BITS        (MAX_WBITS + 16) // see deflateInit2 header docs for explanation of magic 16
#define UU_AUTOMATIC_DECODING_WINDOW_BITS   (MAX_WBITS + 32) // see inflateInit2 header docs for explanation of magic 32

NSString* UUZlibErrorCodeToString(int errorCode);
NSString* UUZlibFormatErrorCodeString(int errorCode);

#define UULogZlibMethodCall(method, returnCode) UUDebugLog(@"%@ returned %@", method, UUZlibFormatErrorCodeString(returnCode))
#define UULogZlibZStream(zs) \
    UUDebugLog(@"\n z_stream.avail_in  = %@" \
                "\n z_stream.avail_out = %@" \
                "\n z_stream.total_in  = %@" \
                "\n z_stream.total_out = %@", \
                @(zs.avail_in), @(zs.avail_out), @(zs.total_in), @(zs.total_out));

@implementation NSData (UUDataCompression)

- (NSData*) uuCompress:(UUCompressionAlgorithm)algorithm level:(UUCompressionLevel)level
{
    NSMutableData* compressedResult = nil;
    
    z_stream zs;
    memset(&zs, 0, sizeof(zs));
    zs.zalloc = Z_NULL;
    zs.zfree = Z_NULL;
    zs.opaque = Z_NULL;
    zs.next_in = (Bytef*)[self bytes];
    zs.avail_in = (uInt)self.length;

    int returnCode;
    
    int method = Z_DEFLATED;
    int windowBits = [[self class] uuEncodingBitsForAlgorithm:algorithm];
    int memLevel = 8; // default
    int strategy = Z_DEFAULT_STRATEGY;
    
    returnCode = deflateInit2(&zs, level, method, windowBits, memLevel, strategy);
    UULogZlibMethodCall(@"deflateInit2", returnCode);
    
    if (returnCode == Z_OK)
    {
        uLong compressedSize = deflateBound(&zs, self.length);
        UUDebugLog(@"Compressed size will be: %lu", compressedSize);
        compressedResult = [NSMutableData dataWithLength:compressedSize];
        zs.next_out = (Bytef*)[compressedResult mutableBytes];
        zs.avail_out = (uInt)compressedSize;
        
        returnCode = deflate(&zs, Z_FINISH);
        UULogZlibMethodCall(@"deflate", returnCode);
        UULogZlibZStream(zs);

        if (returnCode == Z_STREAM_END)
        {
            compressedResult.length = zs.total_out;
            returnCode = deflateEnd(&zs);
            UULogZlibMethodCall(@"deflateEnd", returnCode);
        }
    }
    
    return [compressedResult copy];
}

- (NSData*) uuDecompress
{
    NSData* decompressed = [self uuDecompress:UU_AUTOMATIC_DECODING_WINDOW_BITS];
    if (!decompressed)
    {
        decompressed = [self uuDecompress:UU_RAW_ENCODING_WINDOW_BITS];
    }
    
    return decompressed;
}

- (NSData*) uuDecompress:(int)windowBitSize
{
    if (self.length == 0)
        return nil;
    
    NSMutableData* decompressedResult = nil;
    
    z_stream zs;
    memset(&zs, 0, sizeof(zs));
    zs.zalloc = Z_NULL;
    zs.zfree = Z_NULL;
    zs.opaque = Z_NULL;
    zs.next_in = (Bytef*)[self bytes];
    zs.avail_in = (uInt)self.length;
    
    int returnCode;
    
    UULogZlibZStream(zs);
    returnCode = inflateInit2(&zs, windowBitSize);
    UULogZlibMethodCall(@"inflateInit2", returnCode);
    UULogZlibZStream(zs);
    
    if (returnCode == Z_OK)
    {
        // Start with same buffer size as input data.
        decompressedResult = [NSMutableData dataWithLength:self.length];
        zs.next_out = (Bytef*)[decompressedResult mutableBytes];
        zs.avail_out = (uInt)decompressedResult.length;
        UULogZlibZStream(zs);
        
        while (returnCode == Z_OK)
        {
            returnCode = inflate(&zs, Z_FINISH);
            UULogZlibMethodCall(@"inflate", returnCode);
            UULogZlibZStream(zs);
            
            if (returnCode == Z_DATA_ERROR)
            {
                return nil;
            }
            
            if (returnCode == Z_BUF_ERROR && zs.avail_out == 0)
            {
                [decompressedResult increaseLengthBy:self.length];
                zs.avail_out = (uInt)(decompressedResult.length - zs.total_out);
                zs.next_out = (Bytef*)[decompressedResult mutableBytes] + zs.total_out;
                UULogZlibZStream(zs);
                returnCode = Z_OK; // keep looping
            }
        }
        
        if (returnCode == Z_STREAM_END)
        {
            decompressedResult.length = zs.total_out;
            returnCode = inflateEnd(&zs);
            UULogZlibMethodCall(@"inflateEnd", returnCode);
        }
        
    }
    
    return [decompressedResult copy];
}

#pragma mark - Private

+ (int) uuEncodingBitsForAlgorithm:(UUCompressionAlgorithm)algorithm
{
    switch (algorithm)
    {
        case UUCompressionAlgorithmZlib:
            return UU_ZLIB_ENCODING_WINDOW_BITS;
            
        case UUCompressionAlgorithmGZip:
            return UU_GZIP_ENCODING_WINDOW_BITS;
            
        case UUCompressionAlgorithmRaw:
        default:
            return UU_RAW_ENCODING_WINDOW_BITS;
    }
}



@end

NSString* UUZlibFormatErrorCodeString(int errorCode)
{
    return [NSString stringWithFormat:@"%d (%@)", errorCode, UUZlibErrorCodeToString(errorCode)];
}

NSString* UUZlibErrorCodeToString(int errorCode)
{
    switch (errorCode)
    {
        case Z_OK:
            return @"Z_OK";
            
        case Z_STREAM_END:
            return @"Z_STREAM_END";
            
        case Z_NEED_DICT:
            return @"Z_NEED_DICT";
            
        case Z_ERRNO:
            return @"Z_ERRNO";
            
        case Z_STREAM_ERROR:
            return @"Z_STREAM_ERROR";
            
        case Z_DATA_ERROR:
            return @"Z_DATA_ERROR";
            
        case Z_MEM_ERROR:
            return @"Z_MEM_ERROR";
            
        case Z_BUF_ERROR:
            return @"Z_BUF_ERROR";
            
        case Z_VERSION_ERROR:
            return @"Z_VERSION_ERROR";
            
        default:
            return @"Unknown";
    }
}

