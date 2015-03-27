//
//  UUCoreData.h
//  Useful Utilities - CoreData helpers
//
//	License:
//  You are free to use this code for whatever purposes you desire. The only requirement is that you smile everytime you use it.
//
//  Contact: @cheesemaker or jon@threejacks.com
//

#import "UUCoreData.h"

//If you want to provide your own logging mechanism, define UUDebugLog in your .pch
#ifndef UUDebugLog
#ifdef DEBUG
#define UUDebugLog(fmt, ...) NSLog(fmt, ##__VA_ARGS__)
#else
#define UUDebugLog(fmt, ...)
#endif
#endif

#pragma mark - NSError Private Extensions
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// UUCoreData

@interface NSError (UUCoreData)

- (void) uuLogDetailedErrors;

@end

#pragma mark - UUCoreData
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// UUCOreData

@interface UUCoreData ()

@property (nonatomic, strong) NSPersistentStoreCoordinator* storeCoordinator;
@property (nonatomic, strong) NSManagedObjectContext* mainThreadContext;

@end

@implementation UUCoreData

+ (void) configureWithStoreUrl:(NSURL*)storeUrl modelDefinitionBundle:(NSBundle*)bundle
{
    [[self sharedInstance] configureWithStoreUrl:storeUrl modelDefinitionBundle:bundle];
}

+ (instancetype) sharedInstance
{
    static id theSharedObject = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once (&onceToken, ^
    {
        theSharedObject = [[[self class] alloc] init];
    });
    
    return theSharedObject;
}

- (void) configureWithStoreUrl:(NSURL*)storeUrl modelDefinitionBundle:(NSBundle*)bundle
{
    if (!bundle)
    {
        bundle = [NSBundle mainBundle];
    }
    
    NSManagedObjectModel* managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:@[bundle]];
    
    NSError* error;
    
    NSDictionary* options =
    @{
      NSMigratePersistentStoresAutomaticallyOption : @(YES),
      NSInferMappingModelAutomaticallyOption : @(YES)
      };
    
    self.storeCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];
    if (![self.storeCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:options error:&error])
    {
        UUDebugLog(@"Cannot Setup Core Data!");
        UUDebugLog(@"Error: %@", [error description]);
        exit(-1);
    }
    
    self.mainThreadContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [self.mainThreadContext setPersistentStoreCoordinator:self.storeCoordinator];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(otherContextDidSave:) name:NSManagedObjectContextDidSaveNotification object:nil];
}

+ (NSManagedObjectContext*) mainThreadContext
{
    return [[self sharedInstance] mainThreadContext];
}

- (void)otherContextDidSave:(NSNotification *)didSaveNotification
{
    NSManagedObjectContext* context = (NSManagedObjectContext *)didSaveNotification.object;
    
    NSManagedObjectContext* destContext = self.mainThreadContext;
    if (context != destContext && context.persistentStoreCoordinator == self.mainThreadContext.persistentStoreCoordinator)
    {
        [destContext performBlock:^
         {
             UUDebugLog(@"Merging changes from background context");
             [destContext mergeChangesFromContextDidSaveNotification:didSaveNotification];
         }];
    }
}

+ (NSManagedObjectContext*) workerThreadContext
{
    NSPersistentStoreCoordinator* coordinator = [[self sharedInstance] storeCoordinator];
    NSManagedObjectContext* context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [context setPersistentStoreCoordinator:coordinator];
    return context;
}

@end

#pragma mark - NSManagedObjectContext Extensions
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// NSManagedObjectContext extensions

@implementation NSManagedObjectContext (UUCoreData)

- (BOOL) uuSubmitChanges
{
    __block BOOL result = NO;
    
    if ([self hasChanges])
    {
        [self performBlockAndWait:^
        {
            NSError* error = nil;
            result = [self save:&error];
            
            if (!result)
            {
                [error uuLogDetailedErrors];
            }
        }];
    }
    
    return result;
}

+ (NSArray*) uuConvertObjects:(NSArray*)objects toContext:(NSManagedObjectContext*)context
{
    NSMutableArray* convertedObjects = nil;
    
    if (objects)
    {
        convertedObjects = [NSMutableArray arrayWithCapacity:objects.count];
        
        for (NSManagedObject* obj in objects)
        {
            NSManagedObject* converted = [self uuConvertObject:obj toContext:context];
            [convertedObjects addObject:converted];
        }
    }
    
    return [convertedObjects copy];
}

+ (id) uuConvertObject:(id)object toContext:(NSManagedObjectContext*)context
{
    id converted = object;
    
    if (object)
    {
        if ([object isKindOfClass:[NSManagedObject class]])
        {
            NSManagedObject* managedObj = (NSManagedObject*)object;
            converted = [context objectWithID:managedObj.objectID];
        }
        else if ([object isKindOfClass:[NSArray class]])
        {
            NSMutableArray* convertedObjects = [NSMutableArray array];
            
            NSArray* arrayOfObjects = (NSArray*)object;
            
            for (id obj in arrayOfObjects)
            {
                if ([obj isKindOfClass:[NSManagedObject class]])
                {
                    NSManagedObject* managedObj = (NSManagedObject*)obj;
                    NSManagedObject* converted = [context objectWithID:managedObj.objectID];
                    if (converted)
                    {
                        [convertedObjects addObject:converted];
                    }
                }
            }
            
            converted = [convertedObjects copy];
        }
    }
    
    return converted;
}

@end

#pragma mark - NSManagedObject Extensions
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// NSManagedObject extensions

@implementation NSManagedObject (UUCoreData)

+ (NSString*) uuEntityName
{
    return NSStringFromClass([self class]);
}

+ (NSFetchRequest*) uuFetchRequestInContext:(NSManagedObjectContext*)context
                                  predicate:(NSPredicate*)predicate
                            sortDescriptors:(NSArray*)sortDescriptors
                                      limit:(NSNumber*)limit
{
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    fetchRequest.entity = [NSEntityDescription entityForName:[self uuEntityName] inManagedObjectContext:context];
    fetchRequest.sortDescriptors = sortDescriptors;
    fetchRequest.predicate = predicate;
    
    if (limit != nil)
    {
        [fetchRequest setFetchLimit:[limit unsignedIntegerValue]];
    }
    
    return fetchRequest;
}

+ (NSArray*) uuFetchObjectsWithPredicate:(NSPredicate*)predicate
                                 context:(NSManagedObjectContext*)context
{
    return [self uuFetchObjectsWithPredicate:predicate sortDescriptors:nil limit:nil context:context];
}

+ (NSArray*) uuFetchObjectsWithPredicate:(NSPredicate*)predicate
                         sortDescriptors:(NSArray*)sortDescriptors
                                   limit:(NSNumber*)limit
                                 context:(NSManagedObjectContext*)context
{
    NSFetchRequest* fetchRequest = [self uuFetchRequestInContext:context predicate:predicate sortDescriptors:sortDescriptors limit:limit];
    
    __block NSArray* fetchResults = nil;
    
    [context performBlockAndWait:^
    {
        NSError* err = nil;
        fetchResults = [context executeFetchRequest:fetchRequest error:&err];
        if (err)
        {
            [err uuLogDetailedErrors];
        }
    }];
    
    
    return fetchResults;
}

+ (instancetype) uuFetchSingleObjectWithPredicate:(NSPredicate*)predicate
                                          context:(NSManagedObjectContext*)context
{
    return [self uuFetchSingleObjectWithPredicate:predicate sortDescriptors:nil context:context];
}

+ (instancetype) uuFetchSingleObjectWithPredicate:(NSPredicate*)predicate
                                  sortDescriptors:(NSArray*)sortDescriptors
                                          context:(NSManagedObjectContext*)context
{
    NSArray* list = [self uuFetchObjectsWithPredicate:predicate sortDescriptors:sortDescriptors limit:@(1) context:context];
    if (list && list.count > 0)
    {
        return list[0];
    }
    else
    {
        return nil;
    }
}

+ (instancetype) uuFetchOrCreateSingleEntityWithPredicate:(NSPredicate *)predicate context:(NSManagedObjectContext *)context
{
    NSManagedObject* obj = [self uuFetchSingleObjectWithPredicate:predicate context:context];
    
    if (!obj)
    {
        obj = [NSEntityDescription insertNewObjectForEntityForName:[self uuEntityName] inManagedObjectContext:context];
    }
    
    return obj;
}

+ (void) uuDeleteObjectsWithPredicate:(NSPredicate*)predicate
                              context:(NSManagedObjectContext*)context
{
    NSArray* list = [self uuFetchObjectsWithPredicate:predicate context:context];
    for (NSManagedObject* obj in list)
    {
        [context deleteObject:obj];
    }
}

+ (NSUInteger) uuCountObjectsWithPredicate:(NSPredicate*)predicate
                                   context:(NSManagedObjectContext*)context
{
    NSFetchRequest* fetchRequest = [self uuFetchRequestInContext:context predicate:predicate sortDescriptors:nil limit:nil];
    __block NSUInteger count = 0;
    
    [context performBlockAndWait:^
    {
        NSError* err = nil;
        count = [context countForFetchRequest:fetchRequest error:&err];
        if (err)
        {
            [err uuLogDetailedErrors];
        }
    }];
    
    return count;
}

@end



#pragma mark - NSError Extensions
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// NSError extensions

@implementation NSError (UUCoreData)

- (void) uuLogDetailedErrors
{
    NSError* error = self;
    
    UUDebugLog(@"ERROR: %@", [error localizedDescription]);
    NSArray* detailedErrors = [[error userInfo] objectForKey:NSDetailedErrorsKey];
    if (detailedErrors != nil && [detailedErrors count] > 0)
    {
        for (NSError* de in detailedErrors)
        {
            UUDebugLog(@"  DetailedError: %@", [de userInfo]);
        }
    }
    else
    {
        UUDebugLog(@"  %@", [error userInfo]);
    }
}

@end