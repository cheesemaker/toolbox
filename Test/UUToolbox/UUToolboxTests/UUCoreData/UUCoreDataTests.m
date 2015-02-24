//
//  UUCoreDataTests.m
//  UUToolbox
//
//  Created by Ryan DeVore on 2/22/15.
//  Copyright (c) 2015 Silver Pine. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "UUCoreData.h"
#import "UUPlayer.h"
#import "UUPlayer+Extensions.h"
#import "XCTestCase+UUTestExtensions.h"

@interface UUCoreDataTests : XCTestCase

@end

@implementation UUCoreDataTests

- (NSString*) databasePath
{
    NSString* path = [[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"UUCoreDataTests.db"];
    return path;
}

- (void) deleteDatabase
{
    NSFileManager* fm = [NSFileManager defaultManager];
    NSString* path = [self databasePath];
    NSError* err = nil;
    [fm removeItemAtPath:path error:&err];
    if (err)
    {
        NSLog(@"Error deleting test database! Err: %@", err);
    }
}

- (void) setupDatabase
{
    NSBundle* modelBundle = [NSBundle bundleForClass:[self class]];
    NSString* path = [self databasePath];
    NSURL* storeURL = [NSURL fileURLWithPath:path];
    [UUCoreData configureWithStoreUrl:storeURL modelDefinitionBundle:modelBundle];
    
    NSManagedObjectContext* context = [UUCoreData mainThreadContext];
    [UUPlayer addPlayer:@"Troy" last:@"Aikman" team:@"Dallas Cowboys" position:@"QB" number:@(8) context:context];
    [UUPlayer addPlayer:@"Emmitt" last:@"Smith" team:@"Dallas Cowboys" position:@"RB" number:@(22) context:context];
    [UUPlayer addPlayer:@"Michael" last:@"Irvin" team:@"Dallas Cowboys" position:@"WR" number:@(88) context:context];
    [context uuSubmitChanges];
}

- (void)setUp
{
    [super setUp];
    
    [self deleteDatabase];
    [self setupDatabase];
}

- (void)tearDown
{
    [self deleteDatabase];
    
    [super tearDown];
}

- (void) testFetchFromMainThread
{
    BOOL isMainThread = [NSThread isMainThread];
    NSManagedObjectContext* context = [UUCoreData workerThreadContext];
    NSArray* results = [UUPlayer uuFetchObjectsWithPredicate:nil context:context];
    XCTAssertEqual(results.count, 3, "Expect 3 objects in players table");
}

- (void) testFetchFromWorkerThread
{
    UUBeginAsyncTest();
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
    {
        BOOL isMainThread = [NSThread isMainThread];
        NSManagedObjectContext* context = [UUCoreData workerThreadContext];
        NSArray* results = [UUPlayer uuFetchObjectsWithPredicate:nil context:context];
        XCTAssertEqual(results.count, 3, "Expect 3 objects in players table");
        
        UUEndAsyncTest();
    });
    
    UUWaitForAsyncTest();
}

- (void) testCrossThreadInsert
{
    NSManagedObjectContext* context = [UUCoreData mainThreadContext];
    [UUPlayer addPlayer:@"Tony" last:@"Romo" team:@"Dallas Cowboys" position:@"QB" number:@(9) context:context];
    
    UUBeginAsyncTest();
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
    //dispatch_async(dispatch_get_main_queue(), ^
    {
        [context uuSubmitChanges];
       
       UUEndAsyncTest();
    });
    
    UUWaitForAsyncTest();
    
    NSArray* results = [UUPlayer uuFetchObjectsWithPredicate:nil context:context];
    XCTAssertEqual(results.count, 4, "Expect 4 objects in players table");
    
}

/*
- (void)testExample {
    // This is an example of a functional test case.
    XCTAssert(YES, @"Pass");
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}*/

@end
