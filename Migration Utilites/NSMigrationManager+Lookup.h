//
//  NSMigrationManager+Lookup.h
//  ImmersiveMigrationManager
//
//  Created by Roman Ganzha on 5/24/18.
//  Copyright © 2018 Samle code. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSMigrationManager (Lookup)

- (NSMutableDictionary *)lookupWithKey:(NSString *)lookupKey;

@end
