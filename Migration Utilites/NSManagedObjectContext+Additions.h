//
//  NSManagedObjectContext+Additions.h
//  ImmersiveMigrationManager
//
//  Created by Roman Ganzha on 5/25/16.
//  Copyright © 2016 Samle code. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObjectContext (Additions)

- (void)saveWithCompletionBlock:(void (^)(NSError *error))completionBlock;
- (void)saveContext;
- (NSManagedObject *)insertNewObjectForEntityForName:(NSString *)name;
- (NSArray *)fetchEntityForName:(NSString *)entityName withPredicate:(NSPredicate *)predicate andSortDescriptors:(NSArray <NSSortDescriptor *>*)sortDescriptors;

@end
