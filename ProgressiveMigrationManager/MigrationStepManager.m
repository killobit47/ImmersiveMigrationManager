//  MigrationStepManager.m
//  ImmersiveMigrationManager
//
//  Created by Roman Ganzha on 5/23/18.
//  Copyright © 2018 Sample code. All rights reserved.
//

#import "MigrationStepManager.h"
#import "NSManagedObjectModel+Util.h"

@interface MigrationStepManager()
@property (nonatomic, strong) NSMutableArray *allSteps;
@end

@implementation MigrationStepManager

- (void)addOneStep:(MigrationStep *)step {
    if (step.migrationType == MigrationStepTypeImmersiveWeight) {
        [self.allSteps addObject:step];
    } else if (step.migrationType == MigrationStepTypeHeavyWeight) {
        BOOL isNeedInsertOneLightStep = NO;
        
        if ([self.allSteps count] == 0) {
            isNeedInsertOneLightStep = YES;
        } else {
            MigrationStep *lastStep = [self.allSteps lastObject];
            if (lastStep.migrationType != MigrationStepTypeLightWeight) {
                isNeedInsertOneLightStep = YES;
            }
        }
        if (isNeedInsertOneLightStep) {
            [self.allSteps addObject:[MigrationStep stepOfLightWeightWithSrcModel:step.srcModel desModel:step.srcModel]];
        }
        [self.allSteps addObject:step];
    } else if (step.migrationType == MigrationStepTypeLightWeight) {
        if ([self.allSteps count] > 0) {
            MigrationStep *lastStep = [self.allSteps lastObject];
            if (lastStep.migrationType == MigrationStepTypeLightWeight) {
                MigrationStep *mergedStep = [MigrationStep stepOfLightWeightWithSrcModel:lastStep.srcModel desModel:step.desModel];
                [self.allSteps replaceObjectAtIndex:[self.allSteps indexOfObject:lastStep] withObject:mergedStep];
            } else {
                [self.allSteps addObject:step];
            }
        } else {
            [self.allSteps addObject:step];
        }
    } else {
        NSLog(@"%@ %@ wrong type of migration step %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), step);
    }
}

- (void)enumerateStepsUsingBlock:(void (^)(MigrationStep *step, NSUInteger idx, BOOL *stop))block {
    [self.allSteps enumerateObjectsUsingBlock:block];
}

- (NSMutableArray *)allSteps {
    if (!_allSteps) {
        _allSteps = [NSMutableArray array];
    }
    
    return _allSteps;
}

- (NSString *)description {
    NSString *log = [NSString stringWithFormat:@" migration total steps count %lu\n", (unsigned long)[self.allSteps count]];
    
    for (int i = 0; i < [self.allSteps count]; i++) {
        log = [log stringByAppendingString:[NSString stringWithFormat:@"step%i: %@\n",i, self.allSteps[i]]];
    }
    
    return log;
}

@end

@implementation MigrationStep

+ (MigrationStep *)stepOfImmersiveMigration:(NSManagedObjectModel *)srcModel desModel:(NSManagedObjectModel *)desModel {
    MigrationStep *step = [[MigrationStep alloc] init];
    step.migrationType = MigrationStepTypeImmersiveWeight;
    step.srcModel = srcModel;
    step.desModel = desModel;
    
    return step;
}


+ (MigrationStep *)stepOfLightWeightWithSrcModel:(NSManagedObjectModel *)srcModel desModel:(NSManagedObjectModel *)desModel {
    MigrationStep *step = [[MigrationStep alloc] init];
    step.migrationType = MigrationStepTypeLightWeight;
    step.srcModel = srcModel;
    step.desModel = desModel;
    step.mappingModel = nil;
    
    return step;
}

+ (MigrationStep *)stepOfHeavyWeightWithSrcModel:(NSManagedObjectModel *)srcModel desModel:(NSManagedObjectModel *)desModel mappingModel:(NSMappingModel *)mappingModel {
    MigrationStep *step = [[MigrationStep alloc] init];
    step.migrationType = MigrationStepTypeHeavyWeight;
    step.srcModel = srcModel;
    step.desModel = desModel;
    step.mappingModel = mappingModel;
    
    return step;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"type:%@, src model version:%li, target model version:%li",
            [self migrationTypeDesc], (long)[self.srcModel _VersionNumber], (long)[self.desModel _VersionNumber]];
}

- (NSString *)migrationTypeDesc {
    switch (self.migrationType) {
        case MigrationStepTypeLightWeight:
            return @"lightweight migraion";
            break;
            
        case MigrationStepTypeHeavyWeight:
            return @"heightweight migraion";
            break;
        case MigrationStepTypeImmersiveWeight:
            return @"immersive migration";
            break;
            
        default:
            return @"unknown type migration";
            break;
    }
}

@end
