//  MigrationError.m
//  ImmersiveMigrationManager
//
//  Created by Roman Ganzha on 5/23/18.
//  Copyright © 2018 Sample code. All rights reserved.
//

#import "MigrationError.h"

NSString *const kMigrateErrorDomain = @"Migrate Error";

@implementation MigrationError

+ (MigrationError *)errorWithCode:(PMError)code {
    if (code >= PMErrorMax) {
        return nil;
    }
    
    NSString *desc;
    switch (code) {
        case PMErrorUnknown:
            desc = @"_MIGRATE_ERROR_UNKNOWN";
            break;
            
        case PMErrorSrcStoreMetaDataNotFound:
            desc = @"_MIGRATE_ERROR_SrcStoreMetaDataNotFound";
            break;
            
        case PMErrorSrcStoreDataModelNotFound:
            desc = @"_MIGRATE_ERROR_SrcStoreDataModelNotFound";
            break;
            
        case PMErrorNextDataModelNotFound:
            desc = @"_MIGRATE_ERROR_NextDataModelNotFound";
            break;
            
        case PMErrorLigthWeightMigrationFail:
            desc = @"_MIGRATE_ERROR_LigthWeightMigrationFail";
            break;
            case PMErrorLigthWeightMigrationDoneWithSomeError:
            desc = @"_MIGRATE_ERROR_IncomprehensibleError";
            break;
            
        case PMErrorHeavyWeightMigrationBackupOriginStoreFail:
            desc = @"_MIGRATE_ERROR_HeavyWeightMigrationBackupOriginStoreFail";
            break;
            
        case PMErrorHeavyWeightMigrationCopyNewStoreFail:
            desc = @"_MIGRATE_ERROR_HeavyWeightMigrationCopyNewStoreFail";
            break;
            
        default:
            break;
    }
    
    NSDictionary *userInfo;
    if (desc) {
        userInfo = @{NSLocalizedDescriptionKey : desc};
    }

    MigrationError *error = [MigrationError errorWithDomain:kMigrateErrorDomain code:code userInfo:userInfo];
    return error;
}

@end
