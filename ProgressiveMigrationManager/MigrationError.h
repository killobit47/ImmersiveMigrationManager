//  MigrationError.h
//  ImmersiveMigrationManager
//
//  Created by Roman Ganzha on 5/23/18.
//  Copyright © 2018 Sample code. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const MigrationErrorDomain;

typedef NS_ENUM(NSInteger, PMError) {
    PMErrorUnknown = 1,
    PMErrorSrcStoreMetaDataNotFound,
    PMErrorSrcStoreDataModelNotFound,
    PMErrorNextDataModelNotFound,
    PMErrorLigthWeightMigrationFail,
    PMErrorLigthWeightMigrationDoneWithSomeError,
    PMErrorHeavyWeightMigrationBackupOriginStoreFail,
    PMErrorHeavyWeightMigrationCopyNewStoreFail,
    PMErrorMax
};

@interface MigrationError: NSError

+ (MigrationError *)errorWithCode:(PMError)code;

@end
