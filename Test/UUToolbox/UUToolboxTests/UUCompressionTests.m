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

- (void)testStringCompression
{
    NSArray* inputs =
    @[
        @"",
        @"The quick brown fox jumps over the lazy dog.",
        @"Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.",
      ];
    
    NSArray* algos =
    @[
        @(UUCompressionAlgorithmRaw),
        @(UUCompressionAlgorithmZlib),
        @(UUCompressionAlgorithmGZip)
    ];
    
    for (NSString* input in inputs)
    {
        for (NSNumber* alg in algos)
        {
            [self doStringCompressTest:input alg:alg];
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
        
        NSArray* algos =
        @[
          @(UUCompressionAlgorithmRaw),
          @(UUCompressionAlgorithmZlib),
          @(UUCompressionAlgorithmGZip)
          ];
        
        for (NSNumber* alg in algos)
        {
            [self doRandomByteCompressTest:min max:max alg:alg];
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
        
        NSArray* algos =
        @[
          @(UUCompressionAlgorithmRaw),
          @(UUCompressionAlgorithmZlib),
          @(UUCompressionAlgorithmGZip)
          ];
        
        for (NSNumber* alg in algos)
        {
            [self doRandomByteCompressTest:min max:max alg:alg];
        }
    }
}

- (void) doStringCompressTest:(NSString*)input alg:(NSNumber*)alg
{
    NSStringEncoding encoding = NSUTF8StringEncoding;
    
    NSData* data;
    NSData* compressed;
    NSData* decompressed;
    NSString* decoded;
    
    data = [input dataUsingEncoding:encoding];
    
    UUCompressionAlgorithm algorithm = (UUCompressionAlgorithm)alg.intValue;
    compressed = [data uuCompress:algorithm];
    XCTAssertNotNil(compressed, @"Expect uuCompress to return not nil for non nil inputs for algorithm %@.", alg);
    decompressed = [compressed uuDecompress];
    
    XCTAssertNotNil(decompressed, @"Expect uuDecrompress to return not nil for non nil inputs for algorithm: %@.", alg);
    XCTAssertEqualObjects(data, decompressed, @"Expect decompressed data to be the same as input data for algorithm: %@.", alg);
    
    decoded = [[NSString alloc] initWithData:decompressed encoding:encoding];
    XCTAssertEqualObjects(input, decoded, @"Expect decoded string to be same as input for algorithm: %@.", alg);
    NSLog(@"Algorithm: %@, Decoded: %@", alg, decoded);
}

- (void) doRandomByteCompressTest:(uint32_t)min max:(uint32_t)max alg:(NSNumber*)alg
{
    NSData* data;
    NSData* compressed;
    NSData* decompressed;
    
    uint32_t size = [UURandom uuRandomUInt32BetweenLow:min high:max];
    data = [UURandom uuRandomBytes:(NSUInteger)size];
    
    UUCompressionAlgorithm algorithm = (UUCompressionAlgorithm)alg.intValue;
    compressed = [data uuCompress:algorithm];
    XCTAssertNotNil(compressed, @"Expect uuCompress to return not nil for non nil inputs for algorithm %@.", alg);
    decompressed = [compressed uuDecompress];
    
    XCTAssertNotNil(decompressed, @"Expect uuDecrompress to return not nil for non nil inputs for algorithm: %@.", alg);
    XCTAssertEqualObjects(data, decompressed, @"Expect decompressed data to be the same as input data for algorithm: %@.", alg);
}

@end
