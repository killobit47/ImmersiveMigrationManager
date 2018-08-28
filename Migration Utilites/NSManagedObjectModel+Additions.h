//
//  NSManagedObjectModel+Additions.h
//  ImmersiveMigrationManager
//
//  Created by Roman Ganzha on 5/25/18.
//  Copyright © 2018 Samle code. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObjectModel (Additions)

+ (NSArray *)allModelPaths;
- (NSString *)modelName;

@end
