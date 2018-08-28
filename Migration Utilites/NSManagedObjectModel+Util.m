//  NSManagedObjectModel+Util.m
//  ImmersiveMigrationManager
//
//  Created by Roman Ganzha on 5/23/18.
//  Copyright © 2018 Samle code. All rights reserved.
//

#import "NSManagedObjectModel+Util.h"

const NSInteger kInvalidModelVersionNumber = -1;

@implementation NSManagedObjectModel (Util)
- (NSInteger)_VersionNumber {
    NSString *modelVersionIdentifier = [self.versionIdentifiers anyObject];
    
    return modelVersionIdentifier?[modelVersionIdentifier integerValue]:kInvalidModelVersionNumber;
}

- (BOOL)_isMigrationNeededWithStoreType:(NSString *)storeType atPath:(NSString *)storePath {
    NSError *error = nil;
    BOOL pscCompatibile = NO;
    NSDictionary *sourceMetadata;
    NSURL *storeUrl;
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:storePath]){
        pscCompatibile = YES;
    } else {
        storeUrl = [NSURL fileURLWithPath:storePath];

        sourceMetadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:NSSQLiteStoreType URL:storeUrl options:@{} error:&error];
        pscCompatibile = [self isConfiguration:nil compatibleWithStoreMetadata:sourceMetadata];
    }

    return !pscCompatibile;
}
@end
