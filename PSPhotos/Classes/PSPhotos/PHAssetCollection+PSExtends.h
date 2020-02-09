//
//  PHAssetCollection+PSExtends.h
//  PSPhotos
//
//  Created by zisu on 2019/7/3.
//  Copyright © 2019 zisu. All rights reserved.
//

#import <Photos/Photos.h>
#import "PSPhotosDefines.h"

NS_ASSUME_NONNULL_BEGIN

@interface PHAssetCollection (PSExtends)

+ (PHAssetCollection *)ps_fetchSmartAlbumUserLibrary;
+ (NSArray<PHAssetCollection *> *)ps_fetchAlbums:(PSMediaType)mediaType;

@end

NS_ASSUME_NONNULL_END
