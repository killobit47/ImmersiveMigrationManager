//  MigrateManager.h
//  ImmersiveMigrationManager
//
//  Created by Roman Ganzha on 5/23/18.
//  Copyright © 2018 Sample code. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MigrateDelegate;

@interface MigrationManager : NSObject

@property (nonatomic, weak) id <MigrateDelegate> delegate;
@property (nonatomic, strong, readonly) NSManagedObjectModel *migrationSrcModel;

+ (instancetype)sharedManager;

- (BOOL)migrateStoreAtUrl:(NSURL *)srcStoreUrl
                storeType:(NSString *)storeType
              targetModel:(NSManagedObjectModel *)targetModel
                    error:(NSError **)error;

@end

@protocol MigrateDelegate <NSObject>

@optional

- (void)migrationManager:(MigrationManager *)migrationManager migrationProgress:(float)migrationProgress;

@end
