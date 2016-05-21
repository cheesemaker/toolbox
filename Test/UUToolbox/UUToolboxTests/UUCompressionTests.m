//
//  UUDateTests.m
//  UUFrameworkTest
//
//  Created by Ryan DeVore on 7/1/14.
//
//

#import <XCTest/XCTest.h>
#import "UUCompression.h"
#import "UURandom.h"
#import "UUString.h"
#import "UUDictionary.h"
#import "XCTestCase+UUTestExtensions.h"

@interface UUCompressionTests : XCTestCase

@end

@implementation UUCompressionTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (NSArray*) allAlgorithms
{
    return
    @[
        @(UUCompressionAlgorithmRaw),
        @(UUCompressionAlgorithmZlib),
        @(UUCompressionAlgorithmGZip)
    ];
}

- (NSArray*) allCompressionLevels
{
    return
    @[
        @(UUCompressionLevelNone),
        @(UUCompressionLevelFastest),
        @(UUCompressionLevelBest)
    ];
}

- (void)testStringCompression
{
    NSArray* inputs =
    @[
        @"",
        @"The quick brown fox jumps over the lazy dog.",
        @"Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.",
      ];
    
    NSArray* algos = [self allAlgorithms];
    NSArray* levels = [self allCompressionLevels];
    
    for (NSString* input in inputs)
    {
        for (NSNumber* alg in algos)
        {
            for (NSNumber* level in levels)
            {
                [self doStringCompressTest:input alg:alg level:level];
            }
        }
    }
}

- (void)testRandomByteCompression
{
    int runs = 100;
    
    for (int i = 0; i < runs; i++)
    {
        uint32_t min = [UURandom uuRandomUInt32BetweenLow:0 high:100];
        uint32_t max = min + [UURandom uuRandomUInt32BetweenLow:0 high:100];
        
        NSArray* algos = [self allAlgorithms];
        NSArray* levels = [self allCompressionLevels];
        
        for (NSNumber* alg in algos)
        {
            for (NSNumber* level in levels)
            {
                [self doRandomByteCompressTest:min max:max alg:alg level:level];
            }
        }
    }
}

- (void)testLargeByteCompression
{
    int runs = 10;
    
    for (int i = 0; i < runs; i++)
    {
        uint32_t min = [UURandom uuRandomUInt32BetweenLow:10000 high:20000];
        uint32_t max = min + [UURandom uuRandomUInt32BetweenLow:0 high:100];
        
        NSArray* algos = [self allAlgorithms];
        NSArray* levels = [self allCompressionLevels];
        
        for (NSNumber* alg in algos)
        {
            for (NSNumber* level in levels)
            {
                [self doRandomByteCompressTest:min max:max alg:alg level:level];
            }
        }
    }
}

- (void) testRandomJsonStrings
{
    int runs = 10;
    
    for (int i = 0; i < runs; i++)
    {
        NSArray* algos = [self allAlgorithms];
        NSArray* levels = [self allCompressionLevels];
        
        NSString* input = [UURandom uuMakeRandomJsonString:3 childMax:10];
        
        for (NSNumber* alg in algos)
        {
            for (NSNumber* level in levels)
            {
                [self doStringCompressTest:input alg:alg level:level];
            }
        }
    }
}

- (void) testRandomJsonObjectStrings
{
    int runs = 1;
    
    for (int i = 0; i < runs; i++)
    {
        NSArray* algos = [self allAlgorithms];
        NSArray* levels = [self allCompressionLevels];
        
        NSMutableArray* ma = [UURandom uuMakeRandomFakeObjectList:5 length:40];
        NSDictionary* d = @{@"data" : ma};
        NSString* input = [d toJsonString:NSJSONWritingPrettyPrinted encoding:NSUTF8StringEncoding];
        
        for (NSNumber* alg in algos)
        {
            for (NSNumber* level in levels)
            {
                [self doStringCompressTest:input alg:alg level:level];
            }
        }
    }
}

- (void) doStringCompressTest:(NSString*)input alg:(NSNumber*)alg level:(NSNumber*)level
{
    XCTAssertNotNil(input, @"Expect string input to be not nil! Invalid test setup");
    
    NSStringEncoding encoding = NSUTF8StringEncoding;
    
    NSData* data;
    NSData* compressed;
    NSData* decompressed;
    NSString* decoded;
    
    data = [input dataUsingEncoding:encoding];
    
    UUCompressionAlgorithm algorithm = (UUCompressionAlgorithm)alg.intValue;
    UUCompressionLevel compressionLevel = (UUCompressionLevel)level.intValue;
    compressed = [data uuCompress:algorithm level:compressionLevel];
    XCTAssertNotNil(compressed, @"Expect uuCompress to return not nil for non nil inputs for algorithm %@, level %@.", alg, level);
    decompressed = [compressed uuDecompress];
    
    XCTAssertNotNil(decompressed, @"Expect uuDecrompress to return not nil for non nil inputs for algorithm: %@, level %@.", alg, level);
    XCTAssertEqualObjects(data, decompressed, @"Expect decompressed data to be the same as input data for algorithm: %@, level %@.", alg, level);
    
    decoded = [[NSString alloc] initWithData:decompressed encoding:encoding];
    XCTAssertEqualObjects(input, decoded, @"Expect decoded string to be same as input for algorithm: %@, level %@.", alg, level);
    //NSLog(@"Algorithm: %@, Decoded: %@", alg, decoded);
}

- (void) doRandomByteCompressTest:(uint32_t)min max:(uint32_t)max alg:(NSNumber*)alg level:(NSNumber*)level
{
    NSData* data;
    NSData* compressed;
    NSData* decompressed;
    
    uint32_t size = [UURandom uuRandomUInt32BetweenLow:min high:max];
    data = [UURandom uuRandomBytes:(NSUInteger)size];
    
    UUCompressionAlgorithm algorithm = (UUCompressionAlgorithm)alg.intValue;
    UUCompressionLevel compressionLevel = (UUCompressionLevel)level.intValue;
    compressed = [data uuCompress:algorithm level:compressionLevel];
    XCTAssertNotNil(compressed, @"Expect uuCompress to return not nil for non nil inputs for algorithm %@, level %@.", alg, level);
    decompressed = [compressed uuDecompress];
    
    XCTAssertNotNil(decompressed, @"Expect uuDecrompress to return not nil for non nil inputs for algorithm: %@, level %@.", alg, level);
    XCTAssertEqualObjects(data, decompressed, @"Expect decompressed data to be the same as input data for algorithm: %@, level %@.", alg, level);
}

- (void) testWhenCompressedIsSuperTiny
{
    // This will test where the compressed size is much much smaller than the payload size, which stresses
    // the decompress code to where it must do multiple loops process the data.
    
    NSMutableString* str = [NSMutableString string];
    for (int i = 0; i < 10000; i++)
    {
        [str appendFormat:@"%c", '0'];
    }
    
    NSArray* algos = [self allAlgorithms];
    NSArray* levels = [self allCompressionLevels];
    
    NSString* input = str;
    
    for (NSNumber* alg in algos)
    {
        for (NSNumber* level in levels)
        {
            [self doStringCompressTest:input alg:alg level:level];
        }
    }
}

- (void) testDecompresssBadInput
{
    NSData* input = [NSData data];
    NSData* decompressed = [input uuDecompress];
    
}

@end
