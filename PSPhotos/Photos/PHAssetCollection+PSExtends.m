//
//  PHAssetCollection+PSExtends.m
//  PSPhotos
//
//  Created by zisu on 2019/7/3.
//  Copyright © 2019 zisu. All rights reserved.
//

#import "PHAssetCollection+PSExtends.h"

/// Dummy class for category
@interface PHAssetCollection_PSExtends : NSObject @end
@implementation PHAssetCollection_PSExtends @end

@implementation PHAssetCollection (PSExtends)

+ (PHAssetCollection *)ps_fetchSmartAlbumUserLibrary
{
    PHFetchResult<PHAssetCollection *> *fetchResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil];
    PHAssetCollection *album = fetchResult.lastObject;
    return album;
}

+ (NSArray<PHAssetCollection *> *)ps_fetchAlbums:(PSMediaType)mediaType
{
    NSMutableArray<PHAssetCollection *> *mutableList = [NSMutableArray array];
    PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
    if (mediaType != PSMediaTypeAll) {
        fetchOptions.predicate = [NSPredicate predicateWithFormat:@"mediaType = %d", mediaType];
    }
    PHFetchResult<PHAssetCollection *> *smartAlbums               = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    PHFetchResult<PHAssetCollection *> *streamAlbums              = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumMyPhotoStream options:nil];
    PHFetchResult<PHAssetCollection *> *syncedAlbums              = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumSyncedAlbum options:nil];
    PHFetchResult<PHAssetCollection *> *importedAlbums            = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumImported options:nil];
    PHFetchResult<PHAssetCollection *> *sharedAlbums              = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumCloudShared options:nil];
    PHFetchResult<PHCollection *> *userAlbums                     = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];/// 用户自己创建的相册
    NSArray *allAlbums = @[
                           smartAlbums,
                           streamAlbums,
                           syncedAlbums,
                           sharedAlbums,
                           importedAlbums,
                           userAlbums
                           ];
    for (PHFetchResult *fetchResult in allAlbums) {
        for (PHAssetCollection *album in fetchResult) {
            if (![album isKindOfClass:[PHAssetCollection class]]) continue;
            if (album.estimatedAssetCount <= 0) continue;
            PHFetchResult<PHAsset *> *assetResult = [PHAsset fetchAssetsInAssetCollection:album options:fetchOptions];
            if (assetResult.count <= 0) continue;
            if (album.assetCollectionSubtype == 1000000201) continue;
            if (album.assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumAllHidden) continue;
            if (album.assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumUserLibrary) {
                [mutableList insertObject:album atIndex:0];
            } else {
                [mutableList addObject:album];
            }
        }
    }
    return [mutableList copy];
}

+ (PHAssetCollection *)ps_fetchAlbumWithLocalIdentifier:(NSString *)localIdentifier
{
    if (localIdentifier.length == 0) {
        return nil;
    }
    NSArray<PHAssetCollection *> *fetchResult = [self ps_fetchAlbumsWithLocalIdentifiers:@[localIdentifier]];
    if (fetchResult.count > 0) {
        PHAssetCollection *album = fetchResult.lastObject;
        return album;
    }
    return nil;
}

+ (NSArray<PHAssetCollection *> *)ps_fetchAlbumsWithLocalIdentifiers:(NSArray<NSString *> *)localIdentifiers
{
    NSMutableArray<PHAssetCollection *> *mutableList = [NSMutableArray array];
    if (localIdentifiers.count == 0) {
        return [mutableList copy];
    }
    PHFetchResult<PHAssetCollection *> *fetchResult = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:localIdentifiers options:nil];
    for (PHAssetCollection *album in fetchResult) {
        if (![album isKindOfClass:[PHAssetCollection class]]) continue;
        [mutableList addObject:album];
    }
    return [mutableList copy];
}

@end
