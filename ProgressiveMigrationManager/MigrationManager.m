//  MigrationManager.m
//  ImmersiveMigrationManager
//
//  Created by Roman Ganzha on 5/23/18.
//  Copyright © 2018 Sample code. All rights reserved.
//

#import "MigrationManager.h"
#import "MigrationStepManager.h"
#import "MigrationError.h"
#import "NSManagedObjectModel+Util.h"
#import "NSFileManager+Storage.h"
#import "ImmersiveMigrationManager.h"

@interface MigrationManager() <MigrateDelegate>

@property (nonatomic, strong) NSArray *allDataModelPaths;
@property (nonatomic, strong, readwrite) NSManagedObjectModel *migrationSrcModel;
@property (nonatomic, strong) NSBundle *bundle;

@end

@implementation MigrationManager

+ (instancetype)sharedManager {
    
    static dispatch_once_t onceToken;
    static MigrationManager *manager;
    dispatch_once(&onceToken, ^{
        manager = [[MigrationManager alloc] init];
        manager.delegate = manager;
    });
    
    return manager;
}

- (BOOL)migrateStoreAtUrl:(NSURL *)srcStoreUrl
                storeType:(NSString *)storeType
              targetModel:(NSManagedObjectModel *)targetModel
                    error:(NSError **)error {
    
    [NSFileManager deleteTempDirectory:error];
    
    if (!self.delegate) {
        NSLog(@"%@ need a delegate to perform  migration!", NSStringFromClass([self class]));
        return NO;
    }
    
    self.bundle = [NSBundle bundleForClass:[self class]];
    
    // preprocess the migration steps to minimum count; consecutive lightweight steps will be merged into one step
    MigrationStepManager *stepManager = [[MigrationStepManager alloc] init];
    BOOL isMigrateStepsGenerated = [self generateMigrateStepsWithManager:stepManager forStoreAtUrl:srcStoreUrl storeType:storeType targetMode:targetModel error:error];
    if (!isMigrateStepsGenerated) {
        NSLog(@"%@ generate migrate steps failed!", NSStringFromClass([self class]));
        return NO;
    }
    
    NSLog(@"%@", stepManager);
    
    __block BOOL isMigrateOk = YES;
    // start to migrate step by step
    
        [stepManager enumerateStepsUsingBlock:^(MigrationStep *step, NSUInteger idx, BOOL *stop){
            @autoreleasepool {
                if(![self migrateOneStep:step forStoreAtUrl:srcStoreUrl storeType:storeType error:error]) {
                    isMigrateOk = NO;
                    *stop = YES;
                }
            }
        }];
    
    [NSFileManager moveFromTempDirectory:error];
    
    return isMigrateOk;
}

#pragma mark - Migrate details(private methods)

- (BOOL)generateMigrateStepsWithManager:(MigrationStepManager *)stepManager
                          forStoreAtUrl:(NSURL *)srcStoreUrl
                              storeType:(NSString *)storeType
                             targetMode:(NSManagedObjectModel *)targetModel
                                  error:(NSError **)error {
    // find the data model file according to the source store file
    NSDictionary *srcMetaData = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:storeType URL:srcStoreUrl options:@{} error:error];
    if (!srcMetaData) {
        *error = [MigrationError errorWithCode:PMErrorSrcStoreMetaDataNotFound];
        return NO;
    }
    NSManagedObjectModel *srcModel = [NSManagedObjectModel mergedModelFromBundles:self.bundle ? @[self.bundle] : nil
                                                                 forStoreMetadata:srcMetaData];
    self.migrationSrcModel = srcModel;
    if (!srcModel) {
        *error = [MigrationError errorWithCode:PMErrorSrcStoreDataModelNotFound];
        return NO;
    }
    
    // starts from the src data model, found the next data model and record one migration step info repeatly, until the target data model is reached
    NSManagedObjectModel *nextModel;
    while (1) {
        // check if current model equals to the targe model by delegate method
        
        if ([self modelA:srcModel defaultEqualsToModelB:targetModel]) {
            break;
        }
        NSURL *nextModelPath = [NSURL URLWithString:@""];
        NSMappingModel *mappingModel = nil;
        [self getDestinationModel:&nextModel
                     mappingModel:&mappingModel
                        modelName:&nextModelPath
                   forSourceModel:srcModel
                       modelPaths:self.allDataModelPaths];
        
        NSLog(@"Next model %@", nextModelPath);
        // find the next data model by delegate method
        if (!nextModel) {
            *error = [MigrationError errorWithCode:PMErrorNextDataModelNotFound];
            return NO;
        }
        
        // check if one mapping model exists
        if ([srcModel _VersionNumber] >= 1 && [srcModel _VersionNumber] <= 18) {
        
            [stepManager addOneStep:[MigrationStep stepOfImmersiveMigration:srcModel desModel:nextModel]];
            
        } else if (mappingModel) {
            // mapping model is found, thus we create one heavy migration step
            [stepManager addOneStep:[MigrationStep stepOfHeavyWeightWithSrcModel:srcModel desModel:nextModel mappingModel:mappingModel]];
        } else {
            // mapping model is not found, thus we create one light migration step
            // the stepManager will automatically merge consecutive light migration steps
            [stepManager addOneStep:[MigrationStep stepOfLightWeightWithSrcModel:srcModel desModel:nextModel]];
        }
        srcModel = nextModel;
    }
    
    return YES;
}

- (BOOL)migrateOneStep:(MigrationStep *)oneStep forStoreAtUrl:(NSURL *)srcStoreUrl storeType:(NSString *)storeType error:(NSError **)error {
    
    switch (oneStep.migrationType) {
        case MigrationStepTypeHeavyWeight:
            return [self heavyweightMigrationURL:srcStoreUrl srcModel:oneStep.srcModel desModel:oneStep.desModel mappingModel:oneStep.mappingModel storeType:storeType error:error];

            break;
        case MigrationStepTypeImmersiveWeight: {
            ImmersiveMigrationManager *immersiveMigrationManager = [[ImmersiveMigrationManager alloc] initWithSourceMOM:oneStep.srcModel withSourceURL:srcStoreUrl andDestinationMOM:oneStep.desModel storeType:storeType];

            return [immersiveMigrationManager starmMigration];
            
        }
            break;
        case MigrationStepTypeLightWeight:
            return [self lightweightMigrationURL:srcStoreUrl toModel:oneStep.desModel type:storeType error:error];

            break;
        default:
            NSLog(@"migrate one step, type error %@", oneStep);
            return NO;

            break;
    }
    return YES;
}

- (BOOL)lightweightMigrationURL:(NSURL *)sourceStoreURL toModel:(NSManagedObjectModel *)destinationModel type:(NSString *)type error:(NSError **)error {
    NSDictionary *storeOptions = @{NSMigratePersistentStoresAutomaticallyOption: @YES,
                                   NSInferMappingModelAutomaticallyOption: @YES,
                                   NSSQLitePragmasOption: @{@"journal_mode" : @"WAL"}
                                   };
    
    NSPersistentStoreCoordinator *storeCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:destinationModel];
    __block NSPersistentStore *persistentStore = nil;
    [storeCoordinator performBlockAndWait:^{
         persistentStore = [storeCoordinator addPersistentStoreWithType:type configuration:nil URL:sourceStoreURL options:storeOptions error:error];
    }];
    
    if (persistentStore == nil) {
        *error = [MigrationError errorWithCode:PMErrorLigthWeightMigrationFail];
    }
    
    return (persistentStore != nil);
}

- (BOOL)heavyweightMigrationURL:(NSURL *)sourceStoreURL srcModel:(NSManagedObjectModel *)srcModel desModel:(NSManagedObjectModel *)desModel mappingModel:(NSMappingModel *)mappingModel storeType:(NSString *)type error:(NSError **)error {
    
    @autoreleasepool {
        NSMigrationManager *migrateManager = [[NSMigrationManager alloc]
                                              initWithSourceModel:srcModel
                                              destinationModel:desModel];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        [migrateManager addObserver:self
                  forKeyPath:@"migrationProgress"
                     options:NSKeyValueObservingOptionNew
                     context:nil];
        
        NSString *srcStoreExtension = [[sourceStoreURL path] pathExtension];
        NSString *srcStorePath = [[sourceStoreURL path] stringByDeletingPathExtension];
        
        // create two file path for storing new db file and backup old db file
        NSString *newStorePath = [NSString stringWithFormat:@"%@.new.%@", srcStorePath, srcStoreExtension];
        NSURL *newStoreURL = [NSURL fileURLWithPath:newStorePath];
        if ([fileManager fileExistsAtPath:newStorePath]) {
            [fileManager removeItemAtPath:newStorePath error:nil];
        }
        NSString *backupStorePath = [NSString stringWithFormat:@"%@.backup.%@", srcStorePath, srcStoreExtension];
        if ([fileManager fileExistsAtPath:backupStorePath]) {
            [fileManager removeItemAtPath:backupStorePath error:nil];
        }
        @autoreleasepool {

        // do the heavy migraion
            if (![migrateManager migrateStoreFromURL:sourceStoreURL
                                                type:type
                                             options:@{
                                                                                        NSInferMappingModelAutomaticallyOption: @YES,
                                                                                        NSSQLitePragmasOption: @{@"journal_mode": @"WAL"}}
                                    withMappingModel:mappingModel
                                    toDestinationURL:newStoreURL
                                     destinationType:type
                                  destinationOptions:nil
                                               error:error]) {
                [migrateManager removeObserver:self
                             forKeyPath:@"migrationProgress"];
                return NO;
            }
            
        }
        [migrateManager removeObserver:self
                            forKeyPath:@"migrationProgress"];
        // backup origin db file
        if (![fileManager moveItemAtPath:[sourceStoreURL path] toPath:backupStorePath error:nil]) {
            *error = [MigrationError errorWithCode:PMErrorHeavyWeightMigrationBackupOriginStoreFail];
            return NO;
        }
        
        // replace the origin db file with the new db file ,if fail, restore the origin db file from the backup
        if (![fileManager moveItemAtPath:newStorePath toPath:[sourceStoreURL path] error:nil]) {
            [fileManager moveItemAtPath:backupStorePath toPath:[sourceStoreURL path] error:nil];
            *error = [MigrationError errorWithCode:PMErrorHeavyWeightMigrationCopyNewStoreFail];
            return NO;
        }
        
        // delete temp file
        [fileManager removeItemAtPath:newStorePath error:nil];
        [fileManager removeItemAtPath:backupStorePath error:nil];
        
        return YES;
    }
}

- (void)getDestinationModel:(NSManagedObjectModel **)destinationModel
               mappingModel:(NSMappingModel **)mappingModel
                  modelName:(NSURL **)modelStorePath
             forSourceModel:(NSManagedObjectModel *)sourceModel
                      modelPaths:(NSArray *)modelPaths {

    NSManagedObjectModel *model = nil;
    NSMappingModel *mapping = nil;
    NSString *modelPath = nil;
    for (modelPath in modelPaths) {
        model = [[NSManagedObjectModel alloc] initWithContentsOfURL:[NSURL fileURLWithPath:modelPath]];
        
        if (![self modelA:model equalsToModelB:sourceModel]) {
            
            mapping = [NSMappingModel mappingModelFromBundles:@[[NSBundle mainBundle]]
                                               forSourceModel:sourceModel
                                             destinationModel:model];
            //If we found a mapping model then proceed
            if (mapping) {
                break;
            }
        } else {
            NSLog(@"Source model name %@", modelPath.lastPathComponent.stringByDeletingPathExtension);
        }
    }
    //We have tested every model, if nil here we failed
    if (mapping) {
        *destinationModel = model;
        *mappingModel = mapping;
        *modelStorePath = [NSURL fileURLWithPath:modelPath];
    }
}

#pragma mark - The manager self is the default MigrateDelegate

- (BOOL)modelA:(NSManagedObjectModel *)modelA equalsToModelB:(NSManagedObjectModel *)modelB {
    NSInteger modelAVersionNumber = [modelA _VersionNumber];
    NSInteger modelBVersionNumber = [modelB _VersionNumber];
    
    if (modelAVersionNumber == kInvalidModelVersionNumber || modelBVersionNumber == kInvalidModelVersionNumber) {
        return NO;
    } else {
        return (modelAVersionNumber == modelBVersionNumber);
    }
}

#pragma mark - Helpers

- (NSArray *)allDataModelPaths {
    if (!_allDataModelPaths) {
        NSMutableArray *modelPaths = [NSMutableArray array];
        NSBundle *bundle = self.bundle ?: [NSBundle mainBundle];
        NSArray *momdArray = [bundle pathsForResourcesOfType:@"momd" inDirectory:nil];
        for (NSString *momdPath in momdArray) {
            NSString *resourceSubpath = [momdPath lastPathComponent];
            NSArray *array = [bundle pathsForResourcesOfType:@"mom" inDirectory:resourceSubpath];
            [modelPaths addObjectsFromArray:array];
        }
        
        NSArray* otherModels = [bundle pathsForResourcesOfType:@"mom" inDirectory:nil];
        [modelPaths addObjectsFromArray:otherModels];
        
        _allDataModelPaths = [modelPaths copy];
    }
    
    return _allDataModelPaths;
}

- (BOOL)modelA:(NSManagedObjectModel *)modelA defaultEqualsToModelB:(NSManagedObjectModel *)modelB {
    return [[modelA entityVersionHashesByName] isEqualToDictionary:[modelB entityVersionHashesByName]];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if ([keyPath isEqualToString:@"migrationProgress"]) {
        NSLog(@"progress: %f", [object migrationProgress]);
        if ([self.delegate respondsToSelector:@selector(migrationManager:migrationProgress:)]) {
            [self.delegate migrationManager:self migrationProgress:[(NSMigrationManager *)object migrationProgress]];
        }
    } else {
        [super observeValueForKeyPath:keyPath
                             ofObject:object
                               change:change
                              context:context];
    }
}

@end
