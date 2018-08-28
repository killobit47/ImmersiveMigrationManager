//
//  NSManagedObjectContext+Additions.m
//  ImmersiveMigrationManager
//
//  Created by Roman Ganzha on 5/25/18.
//  Copyright © 2016 Samle code. All rights reserved.
//

#import "NSManagedObjectContext+Additions.h"

@implementation NSManagedObjectContext (Additions)

- (void)saveWithCompletionBlock:(void (^)(NSError *error))completionBlock {
    __strong __block NSManagedObjectContext *strongSelf = self;
    
    [self performBlock:^{
        
        NSError *error = nil;
        if (self != nil && [self hasChanges])
            [self save:&error];
        if (error) {
            NSLog(@"%@", error);
            if (completionBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionBlock(error);
                });
            }
        } else {
            if (self.parentContext) {
                [self.parentContext saveWithCompletionBlock:completionBlock];
            } else {
                if (completionBlock) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completionBlock(nil);
                    });
                }
            }
        }
        strongSelf = nil;
    }];
}

- (NSManagedObject *)insertNewObjectForEntityForName:(NSString *)name {
    
    return [NSEntityDescription insertNewObjectForEntityForName:name inManagedObjectContext:self];
    
}

- (NSArray *)fetchEntityForName:(NSString *)entityName withPredicate:(NSPredicate *)predicate andSortDescriptors:(NSArray <NSSortDescriptor *>*)sortDescriptors {
    @autoreleasepool {
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        [fetchRequest setFetchLimit:5];
        NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:self];
        [fetchRequest setEntity:entity];
        
        if (predicate != nil) {
            [fetchRequest setPredicate:predicate];
        }
        
        if (sortDescriptors != nil) {
            [fetchRequest setSortDescriptors:sortDescriptors];
        }
        
        NSError *error = nil;
        NSArray *fetchedObjects = [self executeFetchRequest:fetchRequest error:&error];
        if (fetchedObjects == nil) {
            NSLog(@"ERROR: %@", error);
        }
        return fetchedObjects;
    }
}

- (void)saveContext {
    [self saveWithCompletionBlock:^(NSError *error) {}];
}

@end
