//
//  PSDefines.h
//  PSPhotos
//
//  Created by zisu on 2020/2/9.
//  Copyright © 2020 zisu. All rights reserved.
//

#ifndef PSDefines_h
#define PSDefines_h

typedef NS_ENUM(NSUInteger, PSErrorCode) {
    PSErrorCodeInvalid = 0,
    PSErrorCodeSyncFailed,          /// iCloud同步失败
    PSErrorCodeSaveFailed,          /// 保存失败
    PSErrorCodeSaveUnauthorized,    /// 相册保存未授权
    PSErrorCodeExportFailed,        /// 导出失败
};

#ifndef PSLog
#ifdef DEBUG
#define PSLog(format,...) NSLog(@"%s(Line %d): " format, __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#define PSLog(format,...) do{}while(0)
#endif
#endif

#endif /* PSDefines_h */
