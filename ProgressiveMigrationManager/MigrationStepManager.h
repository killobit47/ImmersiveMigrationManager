//  MigrationStepManager.h
//  ImmersiveMigrationManager
//
//  Created by Roman Ganzha on 5/23/18.
//  Copyright © 2018 Sample code. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

typedef NS_ENUM(NSUInteger, MigrationStepType) {
    MigrationStepTypeLightWeight = 1,
    MigrationStepTypeHeavyWeight,
    MigrationStepTypeImmersiveWeight
};

@class MigrationStep;

@interface MigrationStepManager : NSObject

- (void)addOneStep:(MigrationStep *)step;
- (void)enumerateStepsUsingBlock:(void (^)(MigrationStep *step, NSUInteger idx, BOOL *stop))block;

@end

@interface MigrationStep : NSObject

@property (nonatomic, assign) MigrationStepType migrationType;
@property (nonatomic, strong) NSManagedObjectModel *srcModel;
@property (nonatomic, strong) NSManagedObjectModel *desModel;
@property (nonatomic, strong) NSMappingModel *mappingModel;

+ (MigrationStep *)stepOfImmersiveMigration:(NSManagedObjectModel *)srcModel desModel:(NSManagedObjectModel *)desModel;

+ (MigrationStep *)stepOfLightWeightWithSrcModel:(NSManagedObjectModel *)srcModel desModel:(NSManagedObjectModel *)desModel;

+ (MigrationStep *)stepOfHeavyWeightWithSrcModel:(NSManagedObjectModel *)srcModel desModel:(NSManagedObjectModel *)desModel mappingModel:(NSMappingModel *)mappingModel;



@end
