//
//  ImmersiveMigrationManager.m
//  ImmersiveMigrationManager
//
//  Created by Roman Ganzha on 6/22/18.
//  Copyright © 2018 Sample code. All rights reserved.
//

#import "ImmersiveMigrationManager.h"
#import "NSManagedObjectContext+Additions.h"
#import "NSManagedObjectModel+Util.h"
#import "NSFileManager+Storage.h"
#import <malloc/malloc.h>

@interface ImmersiveMigrationManager ()

//@property (nonatomic, strong) NSURL *newModelStoreURL;

@property (nonatomic, strong) NSDictionary *defaultSettings;
@end

@implementation ImmersiveMigrationManager

#pragma mark - Init

- (instancetype)initWithSourceMOM:(NSManagedObjectModel *)source withSourceURL:(NSURL *)sourceMOMURL andDestinationMOM:(NSManagedObjectModel *)destination storeType:(NSString *)storeType{
    self = [super init];
    if (self) {
        self.storeType = storeType;
        self.sourceModelStorePath = sourceMOMURL;
        
        self.destinationManagedObjectModel = destination;
        self.sourceManagedObjectModel = source;

    }
    return self;
}

- (void)setSourceManagedObjectModel:(NSManagedObjectModel *)managedObjectModel {
    _sourceManagedObjectModel = managedObjectModel;
    
    self.sourcePersistentStoreCoordinator = [self setUpPersistentStoreCoordinatorWithManagedObjectModel:self.sourceManagedObjectModel andStoreURL:self.sourceModelStorePath];
    
    self.sourceQueueContext = [self setUpMainQueueContextWithPersistentStoreCoordinator:self.sourcePersistentStoreCoordinator];
}


- (void)setDestinationManagedObjectModel:(NSManagedObjectModel *)managedObjectModel {
    _destinationManagedObjectModel = managedObjectModel;
    
    NSString *srcStoreExtension = [[self.sourceModelStorePath path] pathExtension];
    NSString *srcStorePath = [[self.sourceModelStorePath path] stringByDeletingPathExtension];
    
    NSString *newStorePath = [NSString stringWithFormat:@"%@.new.%@", srcStorePath, srcStoreExtension];
    
    self.destinationModelStorePath = [NSURL fileURLWithPath:newStorePath isDirectory:NO];
    if ([[NSFileManager defaultManager] fileExistsAtPath:newStorePath]) {
//        [[NSFileManager defaultManager] removeItemAtPath:newStorePath error:nil];
    }
    
    self.destinationPersistentStoreCoordinator = [self setUpPersistentStoreCoordinatorWithManagedObjectModel:self.destinationManagedObjectModel andStoreURL:self.destinationModelStorePath];
    
    self.destinationQueueContext = [self setUpMainQueueContextWithPersistentStoreCoordinator:self.destinationPersistentStoreCoordinator];
}

- (NSURL *)applicationDocumentsDirectory
{
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSURL *url = [NSURL fileURLWithPath:path];
    //    NSURL *storeURL = [NSURL fileURLWithPath: isDirectory:NO];
    
    
    return url;
}

- (NSPersistentStoreCoordinator *)setUpPersistentStoreCoordinatorWithManagedObjectModel:(NSManagedObjectModel *)managedObjectModel andStoreURL:(NSURL *)storeURL {
    
    NSPersistentStoreCoordinator *persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];
    
    NSMutableDictionary *option = [NSMutableDictionary dictionary];
    [option setValue:@YES forKey:NSMigratePersistentStoresAutomaticallyOption];
    [option setValue:@YES forKey:NSInferMappingModelAutomaticallyOption];
    [option setValue:@{@"journal_mode":@"DELETE"} forKey:NSSQLitePragmasOption];
    
    NSError *error = nil;
    NSLog(@"%@", storeURL);
    if (![persistentStoreCoordinator addPersistentStoreWithType:self.storeType
                                                   configuration:nil
                                                             URL:storeURL
                                                         options:option
                                                           error:&error]) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = @"There was an error creating or loading the application's saved data.";
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];

#ifdef DEBUG
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
#endif
    }
    return persistentStoreCoordinator;
}

- (NSManagedObjectContext *)setUpMainQueueContextWithPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    NSManagedObjectContext *managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator;

    return managedObjectContext;
}

#pragma mark - Publick

//- (BOOL)migrationFromOffset:(NSInteger)offset {
//
//}

- (BOOL)starmMigration {
    
    NSArray<NSEntityDescription *> *entitiesDescription = [self.sourceManagedObjectModel entities];
    
    
    NSLog(@"%@", entitiesDescription);
    
    
    for (NSEntityDescription *entityDescription in entitiesDescription) {
        
        @autoreleasepool {
            
            NSArray <NSManagedObject *>*entities = [self.sourceQueueContext fetchEntityForName:entityDescription.name withPredicate:nil andSortDescriptors:nil];
            for (NSManagedObject *entity in entities) {
                
                id object = [self createDestinationInstancesForSourceInstance:entity isRelationship:NO withCompletion:^{
                    
                }];
                if (object == [NSNull null]) {
                    
#warning some Error should be here
                    
                    return NO;
                }
                
                
                object = nil;
            }
            entities = nil;
        }
    }
    
    _destinationQueueContext = nil;
    _sourceQueueContext = nil;
    _sourceManagedObjectModel = nil;
    _destinationManagedObjectModel = nil;
    _sourcePersistentStoreCoordinator = nil;
    _destinationPersistentStoreCoordinator = nil;
    
    [[NSFileManager defaultManager] moveItemAtPath:[self.destinationModelStorePath path] toPath:[self.sourceModelStorePath path] error:nil];
    
    return YES;
}

- (NSManagedObject *)createDestinationInstancesForSourceInstance:(NSManagedObject *)sourceInstance isRelationship:(BOOL)relationship withCompletion:(void(^)(void))completion {
    
    NSMutableArray *sourceKeys = [sourceInstance.entity.propertiesByName.allKeys mutableCopy];
    NSDictionary *sourceValues = [sourceInstance dictionaryWithValuesForKeys:sourceKeys];
    
    NSManagedObject *destinationInstance = [NSEntityDescription insertNewObjectForEntityForName:sourceInstance.entity.name
                                                                         inManagedObjectContext:[self destinationQueueContext]];
    
    NSArray *destinationKeys = destinationInstance.entity.propertiesByName.allKeys;
    
    @autoreleasepool {
        
        for (NSString *key in destinationKeys) {
            id value = nil;
            if ([key isEqualToString:@"thumbnail"]) {
                value = [self imageNameFromImageData:[sourceValues valueForKey:key] fileType:SLFileTypeThumbnail];
            } else if ([key isEqualToString:@"photo"]) {
                value = [self imageNameFromImageData:[sourceValues valueForKey:key] fileType:SLFileTypeOriginalImage];
            } else {
                value = [sourceValues valueForKey:key];
            }
            // Avoid NULL values
            if ([value isKindOfClass:[NSManagedObject class]]) {
                if (relationship == NO) {
                    NSManagedObject *relationshipInstance = [self createDestinationInstancesForSourceInstance:value isRelationship:YES withCompletion:^{
                        [destinationInstance setValue:relationshipInstance forKey:key];
                    }];
                }
            } else {
                if (value && ![value isEqual:[NSNull null]]) {
                    [destinationInstance setValue:value forKey:key];
                } else {
                    value = self.defaultSettings[key];
                    if (value && ![value isEqual:[NSNull null]]) {
                        [destinationInstance setValue:value forKey:key];
                    }
                }
            }
        }
    }
    
    sourceInstance = nil;
    return destinationInstance;
}

- (NSString *)imageNameFromImageData:(NSData *)imageData {
    return [self imageNameFromImageData:imageData fileType:SLFileTypeThumbnailTemp];
}

- (NSString *)imageNameFromImageData:(NSData *)imageData fileType:(SLFileType)type {
    NSLog(@"preparation to resave tumbnail image");
    return [NSFileManager saveImageOfType:type toStorage:imageData];
}

- (NSDictionary *)defaultSettings {
    if (_defaultSettings) {
        return _defaultSettings;
    }
    
    _defaultSettings = @{
                         @"onGpsInfo": @(YES),
                         @"onBearing": @(YES),
                         @"onLatLon": @(YES),
                         @"onAltitude": @(YES),
                         @"onAltitudeMetric": @(NO),
                         @"onMetadata": @(YES),
                         @"timeFormat": @(YES),
                         @"askDescriptions": @(YES),
                         @"onDescriptions": @(YES),
                         @"watermark": @"Your Watermark - See Settings",
                         @"degMod": @(0),
                         @"onQuality": @(0),
                         @"flashMode": @(0),
                         @"onBootomTextColor": @(0),
                         @"onFontSize": @(10),
                         @"onCrossHair": @(YES),
                         @"onTrueNorth": @(YES),
                         @"gaugeType": @(kCompasModeDegrees),
                         @"onSelectedCoordinate": @(NO),
                         @"onShowCompass": @(YES),
                         @"autoSaveOrigin": @(YES),
                         @"autoSaveGPS": @(YES),
                         @"notifyMe": @(YES),
                         @"showGPSIcons": @(YES),
                         @"onDateTime": @(YES),
                         @"onPhotoDetailsEmailing": @(YES),
                         @"onPhotosEmailing": @(YES),
                         @"onKMLEmailing": @(NO),
                         @"onKMZEmailing": @(NO),
                         @"onCSVEmailing": @(NO),
                         @"onPhotosExporting": @(YES),
                         @"onKMLExporting": @(NO),
                         @"onKMZExporting": @(NO),
                         @"onCSVExporting": @(NO),
                         @"photoSize": [[SLDeviceSpecification sharedObject] currentCameraResolution].stringValue,
                         @"onLockCamera": @(NO),
                         @"onFontSize": @(10),
                         @"onSingleMapEmailing": @(NO),
                         @"onMultiMapEmailing": @(NO),
                         @"onSingleMapExporting": @(NO),
                         @"onMultiMapExporting": @(NO)
                         };
    return _defaultSettings;
}

@end
