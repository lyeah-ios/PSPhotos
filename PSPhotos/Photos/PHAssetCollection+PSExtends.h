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
+ (nullable PHAssetCollection *)ps_fetchAlbumWithLocalIdentifier:(NSString *)localIdentifier;
+ (NSArray<PHAssetCollection *> *)ps_fetchAlbumsWithLocalIdentifiers:(NSArray<NSString *> *)localIdentifiers;

@end

NS_ASSUME_NONNULL_END
