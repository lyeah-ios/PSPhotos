//
//  PSPhotosDefines.h
//  PSPhotos
//
//  Created by zisu on 2020/2/9.
//  Copyright © 2020 zisu. All rights reserved.
//

#ifndef PSPhotosDefines_h
#define PSPhotosDefines_h

#import <Photos/Photos.h>

typedef NS_ENUM(NSUInteger, PSErrorCode) {
    PSErrorCodeInvalid = 0,
    PSErrorCodeSyncFailed,          /// iCloud同步失败
    PSErrorCodeSaveFailed,          /// 保存失败
    PSErrorCodeSaveUnauthorized,    /// 相册保存未授权
    PSErrorCodeExportFailed,        /// 导出失败
};

typedef NS_ENUM(NSUInteger, PSMediaType) {
    PSMediaTypeAll     = 0,                         //PHAssetMediaTypeImage + PHAssetMediaTypeVideo
    PSMediaTypeImage   = PHAssetMediaTypeImage,
    PSMediaTypeVideo   = PHAssetMediaTypeVideo,
};

#ifdef DEBUG
#define PSLog(format,...) NSLog(@"%s(line %d): " format, __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#define PSLog(format,...) do{}while(0)
#endif

#endif /* PSPhotosDefines_h */
