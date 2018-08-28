//
//  ImmersiveMigrationManager.h
//  ImmersiveMigrationManager
//
//  Created by Roman Ganzha on 6/22/18.
//  Copyright © 2018 Sample code. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ImmersiveMigrationManager : NSObject

- (instancetype)initWithSourceMOM:(NSManagedObjectModel *)source withSourceURL:(NSURL *)sourceMOMURL andDestinationMOM:(NSManagedObjectModel *)destination storeType:(NSString *)storeType;

@property (nonatomic, strong) NSURL *destinationModelStorePath;
@property (nonatomic, strong) NSURL *sourceModelStorePath;
@property (nonatomic, strong) NSString *storeType;

@property (nonatomic, strong) NSManagedObjectModel *sourceManagedObjectModel;
@property (nonatomic, strong) NSManagedObjectModel *destinationManagedObjectModel;

@property (nonatomic, strong) NSManagedObjectContext *sourceQueueContext;
@property (nonatomic, strong) NSManagedObjectContext *destinationQueueContext;

@property (nonatomic, strong) NSPersistentStoreCoordinator *sourcePersistentStoreCoordinator;
@property (nonatomic, strong) NSPersistentStoreCoordinator *destinationPersistentStoreCoordinator;

- (BOOL)starmMigration;

@end
