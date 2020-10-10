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

typedef NS_ENUM(NSUInteger, PSMediaType) {
    PSMediaTypeAll     = 0,                         /// PHAssetMediaTypeImage + PHAssetMediaTypeVideo
    PSMediaTypeImage   = PHAssetMediaTypeImage,
    PSMediaTypeVideo   = PHAssetMediaTypeVideo,
};

#endif /* PSPhotosDefines_h */
