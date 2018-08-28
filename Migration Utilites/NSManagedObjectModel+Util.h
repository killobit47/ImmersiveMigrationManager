//  NSManagedObjectModel+Util.h
//  ImmersiveMigrationManager
//
//  Created by Roman Ganzha on 5/23/18.
//  Copyright © 2018 Samle code. All rights reserved.
//

#import <CoreData/CoreData.h>

extern const  NSInteger kInvalidModelVersionNumber;

@interface NSManagedObjectModel (Util)
- (NSInteger)_VersionNumber;
- (BOOL)_isMigrationNeededWithStoreType:(NSString *)storeType atPath:(NSString *)storePath;
@end
