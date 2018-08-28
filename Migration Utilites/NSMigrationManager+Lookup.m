//
//  NSMigrationManager+Lookup.m
//  ImmersiveMigrationManager
//
//  Created by Roman Ganzha on 5/24/18.
//  Copyright © 2018 Samle code. All rights reserved.
//

#import "NSMigrationManager+Lookup.h"

@implementation NSMigrationManager (Lookup)

- (NSMutableDictionary *)lookupWithKey:(NSString *)lookupKey {
    NSMutableDictionary *userInfo = (NSMutableDictionary *)self.userInfo;
    // Check if we've already created a userInfo dictionary
    if (!userInfo) {
        userInfo = [@{} mutableCopy];
        self.userInfo = userInfo;
    }

    NSMutableDictionary *lookup = [userInfo valueForKey:lookupKey];
    if (!lookup) {
        lookup = [@{} mutableCopy];
        [userInfo setValue:lookup forKey:lookupKey];
    }
    return lookup;
}

@end
