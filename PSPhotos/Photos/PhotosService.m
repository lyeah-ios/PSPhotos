//
//  PhotosService.m
//  PSPhotos
//
//  Created by zisu on 2018/11/22.
//  Copyright © 2018年 zisu. All rights reserved.
//

#import "PhotosService.h"
#import "PSDefines.h"
#import "PSPhotosDefines.h"
#import "PHAsset+PSExtends.h"
#import "PHAssetCollection+PSExtends.h"
#import "AVAssetExportSession+PSExtends.h"

NSString *const PSErrorDomain = @"PSErrorDomain";
NSString *const PSBundleNameKey = @"CFBundleName";
NSString *const PSBundleDisplayNameKey = @"CFBundleDisplayName";
NSString *const PSPhotoLibraryUsageDescriptionKey = @"NSPhotoLibraryUsageDescription";

static NSString *const kPhotosServiceDefaultCacheDirectory = @"PSPhotos";

@interface PhotosService ()

@end

@implementation PhotosService

+ (PhotosService *)service
{
    static PhotosService *sharedService = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedService = [[PhotosService alloc] init];
    });
    return sharedService;
}

- (NSString *)cacheDirectory
{
    if (!_cacheDirectory) {
        NSString *cacheDirectory = [NSString stringWithFormat:@"%@/%@", NSTemporaryDirectory(), kPhotosServiceDefaultCacheDirectory];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL isDir = NO;
        BOOL isExists = [fileManager fileExistsAtPath:cacheDirectory isDirectory:&isDir];
        if (isExists && isDir) {
            
        } else {
            NSError *error = nil;
            [fileManager createDirectoryAtPath:cacheDirectory withIntermediateDirectories:YES attributes:nil error:&error];
        }
        _cacheDirectory = cacheDirectory;
    }
    return _cacheDirectory;
}

+ (void)requestAuthorization:(void (^)(PHAuthorizationStatus))handler
{
    if (@available(iOS 14.0, *)) {
        PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatusForAccessLevel:PHAccessLevelReadWrite];
        if (status == PHAuthorizationStatusNotDetermined) {
            /// 还没决定
            [PHPhotoLibrary requestAuthorizationForAccessLevel:PHAccessLevelReadWrite handler:^(PHAuthorizationStatus status) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (handler) {
                        handler(status);
                    }
                });
            }];
        } else {
            if (handler) {
                handler(status);
            }
        }
    } else {
        PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
        if (status == PHAuthorizationStatusNotDetermined) {
            /// 还没决定
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (handler) {
                        handler(status);
                    }
                });
            }];
        } else {
            if (handler) {
                handler(status);
            }
        }
    }
}

+ (void)clearCaches
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    NSString *cacheDirectory = [PhotosService service].cacheDirectory;
    [fileManager removeItemAtPath:cacheDirectory error:&error];
    BOOL isDir = NO;
    BOOL isExists = [fileManager fileExistsAtPath:cacheDirectory isDirectory:&isDir];
    if (isExists && isDir) {
        
    } else {
        NSError *error = nil;
        [fileManager createDirectoryAtPath:cacheDirectory withIntermediateDirectories:YES attributes:nil error:&error];
    }
}

/**
 获取指定相册，在这之前需要请求权限
 
 @param albumName 相册名
 @param createIfNotExist 不存在是否创建
 */
+ (void)fetchAlbum:(NSString *)albumName createIfNotExist:(BOOL)createIfNotExist onCompletion:(void (^)(PHAssetCollection *album))completion
{
    if (albumName.length == 0) {
        if (completion) {
            completion(nil);
        }
        return;
    }
    PHFetchResult<PHAssetCollection *> *albums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    PHAssetCollection *targetAlbum = nil;
    for (PHAssetCollection *album in albums) {
        if ([album.localizedTitle isEqualToString:albumName]) {
            targetAlbum = album;
            break;
        }
    }
    if (targetAlbum) {
        //存在该相册
        if (completion) {
            completion(targetAlbum);
        }
    } else {
        if (!createIfNotExist) {
            if (completion) {
                completion(nil);
            }
            return;
        }
        //创建新相册
        __block NSString *albumLocalIdentifier = nil;
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            PHAssetCollectionChangeRequest *albumChangeRequest = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:albumName];
            PHObjectPlaceholder *placeholderAlbum = albumChangeRequest.placeholderForCreatedAssetCollection;
            albumLocalIdentifier = placeholderAlbum.localIdentifier;
        } completionHandler:^(BOOL success, NSError *_Nullable error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (success) {
                    PHFetchResult<PHAssetCollection *> *fetchResult = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[albumLocalIdentifier] options:nil];
                    PHAssetCollection *album = fetchResult.lastObject;
                    if (completion) {
                        completion(album);
                    }
                } else {
                    PSLog(@"创建相册《%@》失败:%@", albumName, error);
                    if (completion) {
                        completion(nil);
                    }
                }
            });
        }];
    }
}

/**
 统一处理保存结果
 */
+ (void)doAfterSaveSuccess:(NSString *)localIdentifier toAlbum:(NSString *)albumName onCompletion:(void (^)(void))completion
{
    //保存成功，尝试添加到指定相册（相册创建失败或者保存到指定相册失败都不做回调）
    [self fetchAlbum:albumName createIfNotExist:YES onCompletion:^(PHAssetCollection *album) {
        if (album) {
            [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                PHFetchResult<PHAsset *> *fetchResult = [PHAsset fetchAssetsWithLocalIdentifiers:@[localIdentifier] options:nil];
                PHAsset *targetAsset = fetchResult.lastObject;
                PHAssetCollectionChangeRequest *changeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:album];
                [changeRequest addAssets:@[targetAsset]];
            } completionHandler:^(BOOL success, NSError *_Nullable error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (!success) {
                        PSLog(@"保存到相册《%@》失败:%@", albumName, error);
                    }
                    if (completion) {
                        completion();
                    }
                });
            }];
        } else {
            if (completion) {
                completion();
            }
        }
    }];
}

+ (NSString *)uniqueRandomFileName
{
    NSInteger randomCode = arc4random() % 1000;
    NSTimeInterval interval = [[NSDate date] timeIntervalSince1970];
    NSString *uniqueRandomFileName = [NSString stringWithFormat:@"%f%@", interval, @(randomCode)];
    uniqueRandomFileName = [uniqueRandomFileName stringByReplacingOccurrencesOfString:@"." withString:@""];
    return uniqueRandomFileName;
}

@end

@implementation PhotosService (Photo)

+ (void)saveImage:(UIImage *)image toAlbum:(NSString *)albumName onCompletion:(void (^)(NSError * _Nullable))completion
{
    if (!image) {
        if (completion) {
            NSString *errorMessage = @"无效的图片格式";
            NSError *error = [NSError errorWithDomain:PSErrorDomain code:PSErrorCodeInvalid userInfo:@{
                NSLocalizedDescriptionKey : errorMessage,
                NSLocalizedFailureReasonErrorKey : errorMessage,
            }];
            completion(error);
        }
        return;
    }
    /// request authorization
    [self requestAuthorization:^(PHAuthorizationStatus status) {
        if (status == PHAuthorizationStatusAuthorized) {
            [self _saveImage:image toAlbum:albumName onCompletion:completion];
        } else if (status == PHAuthorizationStatusNotDetermined) {
            /// wait user authorized.
        } else {
            if (completion) {
                NSString *errorMessage = @"图片保存失败";
                NSError *error = [NSError errorWithDomain:PSErrorDomain code:PSErrorCodeSaveUnauthorized userInfo:@{
                    NSLocalizedDescriptionKey : errorMessage,
                    NSLocalizedFailureReasonErrorKey : errorMessage,
                }];
                completion(error);
            }
        }
    }];
}

+ (void)_saveImage:(UIImage *)image toAlbum:(NSString *)albumName onCompletion:(void (^)(NSError *_Nullable))completion
{
    __block NSString *assetLocalIdentifier = nil;
    __weak typeof(self)wself = self;
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        /// 图片会先保存到相机胶卷
        NSData *imageData = UIImageJPEGRepresentation(image, 1.0);
        PHAssetResourceCreationOptions *options = [[PHAssetResourceCreationOptions alloc] init];
        PHAssetCreationRequest *creationRequest = [PHAssetCreationRequest creationRequestForAsset];
        [creationRequest addResourceWithType:PHAssetResourceTypePhoto data:imageData options:options];
        creationRequest.creationDate = [NSDate date];
        PHObjectPlaceholder *placeholderAsset = creationRequest.placeholderForCreatedAsset;
        assetLocalIdentifier = placeholderAsset.localIdentifier;
    } completionHandler:^(BOOL success, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                [wself doAfterSaveSuccess:assetLocalIdentifier toAlbum:albumName onCompletion:^{
                    if (completion) {
                        completion(nil);
                    }
                }];
            } else {
                /// 保存失败
                if (completion) {
                    NSString *errorMessage = error.localizedFailureReason;
                    if (errorMessage.length == 0) {
                        errorMessage = @"图片保存失败";
                    }
                    NSError *error = [NSError errorWithDomain:PSErrorDomain code:PSErrorCodeSaveFailed userInfo:@{
                        NSLocalizedDescriptionKey : errorMessage,
                        NSLocalizedFailureReasonErrorKey : errorMessage,
                    }];
                    completion(error);
                }
            }
        });
    }];
}

+ (void)saveImageData:(NSData *)imageData isGIF:(BOOL)isGIF toAlbum:(NSString *)albumName onCompletion:(void (^)(NSError * _Nullable))completion
{
    if (!imageData || imageData.length == 0) {
        if (completion) {
            NSString *errorMessage = @"无效的图片格式";
            NSError *error = [NSError errorWithDomain:PSErrorDomain code:PSErrorCodeInvalid userInfo:@{
                NSLocalizedDescriptionKey : errorMessage,
                NSLocalizedFailureReasonErrorKey : errorMessage,
            }];
            completion(error);
        }
        return;
    }
    /// request authorization
    [self requestAuthorization:^(PHAuthorizationStatus status) {
        if (status == PHAuthorizationStatusAuthorized) {
            [self _saveImageData:(NSData *)imageData isGIF:isGIF toAlbum:albumName onCompletion:completion];
        } else if (status == PHAuthorizationStatusNotDetermined) {
            /// wait user authorized.
        } else {
            if (completion) {
                NSString *errorMessage = @"图片保存失败";
                NSError *error = [NSError errorWithDomain:PSErrorDomain code:PSErrorCodeSaveUnauthorized userInfo:@{
                    NSLocalizedDescriptionKey : errorMessage,
                    NSLocalizedFailureReasonErrorKey : errorMessage,
                }];
                completion(error);
            }
        }
    }];
}

+ (void)_saveImageData:(NSData *)imageData isGIF:(BOOL)isGIF toAlbum:(NSString *)albumName onCompletion:(void (^)(NSError *_Nullable))completion
{
    __weak typeof(self)wself = self;
    __block NSString *assetLocalIdentifier = nil;
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        PHAssetCreationRequest *assetCreationRequest = [PHAssetCreationRequest creationRequestForAsset];
        [assetCreationRequest addResourceWithType:PHAssetResourceTypePhoto data:imageData options:nil];
        PHObjectPlaceholder *placeholderAsset = assetCreationRequest.placeholderForCreatedAsset;
        assetLocalIdentifier = placeholderAsset.localIdentifier;
    } completionHandler:^(BOOL success, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                [wself doAfterSaveSuccess:assetLocalIdentifier toAlbum:albumName onCompletion:^{
                    if (completion) {
                        completion(nil);
                    }
                }];
            } else {
                /// 保存失败
                if (completion) {
                    NSString *errorMessage = error.localizedFailureReason;
                    if (errorMessage.length == 0) {
                        errorMessage = @"图片保存失败";
                    }
                    NSError *error = [NSError errorWithDomain:PSErrorDomain code:PSErrorCodeSaveFailed userInfo:@{
                        NSLocalizedDescriptionKey : errorMessage,
                        NSLocalizedFailureReasonErrorKey : errorMessage,
                    }];
                    completion(error);
                }
            }
        });
    }];
}

+ (void)saveImageWithURL:(NSURL *)fileURL toAlbum:(NSString *)albumName onCompletion:(void (^)(NSError * _Nullable))completion
{
    if (!fileURL) {
        if (completion) {
            NSString *errorMessage = @"图片路径不存在";
            NSError *error = [NSError errorWithDomain:PSErrorDomain code:PSErrorCodeInvalid userInfo:@{
                NSLocalizedDescriptionKey : errorMessage,
                NSLocalizedFailureReasonErrorKey : errorMessage,
            }];
            completion(error);
        }
        return;
    }
    /// request authorization
    [self requestAuthorization:^(PHAuthorizationStatus status) {
        if (status == PHAuthorizationStatusAuthorized) {
            [self _saveImageWithURL:fileURL toAlbum:albumName onCompletion:completion];
        } else if (status == PHAuthorizationStatusNotDetermined) {
            /// wait user authorized.
        } else {
            if (completion) {
                NSString *errorMessage = @"图片保存失败";
                NSError *error = [NSError errorWithDomain:PSErrorDomain code:PSErrorCodeSaveUnauthorized userInfo:@{
                    NSLocalizedDescriptionKey : errorMessage,
                    NSLocalizedFailureReasonErrorKey : errorMessage,
                }];
                completion(error);
            }
        }
    }];
}

+ (void)_saveImageWithURL:(NSURL *)fileURL toAlbum:(NSString *)albumName onCompletion:(void (^)(NSError *_Nullable))completion
{
    __block NSString *assetLocalIdentifier = nil;
    __weak typeof(self)wself = self;
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        //图片会先保存到相机胶卷
        PHAssetChangeRequest *changeRequest = [PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:fileURL];
        PHObjectPlaceholder *placeholderAsset = changeRequest.placeholderForCreatedAsset;
        assetLocalIdentifier = placeholderAsset.localIdentifier;
    } completionHandler:^(BOOL success, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                [wself doAfterSaveSuccess:assetLocalIdentifier toAlbum:albumName onCompletion:^{
                    if (completion) {
                        completion(nil);
                    }
                }];
            } else {
                //保存失败
                if (completion) {
                    NSString *errorMessage = error.localizedFailureReason;
                    if (errorMessage.length == 0) {
                        errorMessage = @"图片保存失败";
                    }
                    NSError *error = [NSError errorWithDomain:PSErrorDomain code:PSErrorCodeSaveFailed userInfo:@{
                        NSLocalizedDescriptionKey : errorMessage,
                        NSLocalizedFailureReasonErrorKey : errorMessage,
                    }];
                    completion(error);
                }
            }
        });
    }];
}

@end

@implementation PhotosService (Video)

+ (void)saveVideoWithURL:(NSURL *)fileURL toAlbum:(NSString *_Nullable)albumName onCompletion:(void (^ _Nullable)(NSError *_Nullable))completion
{
    [self saveVideoWithURL:fileURL shouldMoveFile:NO toAlbum:albumName onCompletion:completion];
}

+ (void)saveVideoWithURL:(NSURL *)fileURL shouldMoveFile:(BOOL)shouldMoveFile toAlbum:(NSString *)albumName onCompletion:(void (^)(NSError * _Nullable))completion
{
    if (!fileURL) {
        NSString *errorMessage = @"无效的视频格式";
        NSError *error = [NSError errorWithDomain:PSErrorDomain code:PSErrorCodeInvalid userInfo:@{
            NSLocalizedDescriptionKey : errorMessage,
            NSLocalizedFailureReasonErrorKey : errorMessage,
        }];
        if (completion) {
            completion(error);
        }
        return;
    }
    /// request authorization
    [self requestAuthorization:^(PHAuthorizationStatus status) {
        if (status == PHAuthorizationStatusAuthorized) {
            [self _saveVideoWithURL:fileURL shouldMoveFile:shouldMoveFile toAlbum:albumName onCompletion:completion];
        } else if (status == PHAuthorizationStatusNotDetermined) {
            /// wait user authorized.
        } else {
            if (completion) {
                NSString *errorMessage = @"视频保存失败";
                NSError *error = [NSError errorWithDomain:PSErrorDomain code:PSErrorCodeSaveUnauthorized userInfo:@{
                    NSLocalizedDescriptionKey : errorMessage,
                    NSLocalizedFailureReasonErrorKey : errorMessage,
                }];
                completion(error);
            }
        }
    }];
}

+ (void)_saveVideoWithURL:(NSURL *)fileURL shouldMoveFile:(BOOL)shouldMoveFile toAlbum:(NSString *)albumName onCompletion:(void (^)(NSError *_Nullable))completion
{
    __block NSString *assetLocalIdentifier = nil;
    __weak typeof(self)wself = self;
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        PHAssetResourceCreationOptions *options = [[PHAssetResourceCreationOptions alloc] init];
        options.shouldMoveFile = shouldMoveFile;
        PHAssetCreationRequest *creationRequest = [PHAssetCreationRequest creationRequestForAsset];
        [creationRequest addResourceWithType:PHAssetResourceTypeVideo fileURL:fileURL options:options];
        creationRequest.creationDate = [NSDate date];
        PHObjectPlaceholder *placeholderAsset = creationRequest.placeholderForCreatedAsset;
        assetLocalIdentifier = placeholderAsset.localIdentifier;
    } completionHandler:^(BOOL success, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                [wself doAfterSaveSuccess:assetLocalIdentifier toAlbum:albumName onCompletion:^{
                    if (completion) {
                        completion(nil);
                    }
                }];
            } else {
                /// 保存失败
                if (completion) {
                    NSString *errorMessage = error.localizedFailureReason;
                    if (errorMessage.length == 0) {
                        errorMessage = @"视频保存失败";
                    }
                    NSError *error = [NSError errorWithDomain:PSErrorDomain code:PSErrorCodeSaveFailed userInfo:@{
                        NSLocalizedDescriptionKey : errorMessage,
                        NSLocalizedFailureReasonErrorKey : errorMessage,
                    }];
                    completion(error);
                }
            }
        });
    }];
}

+ (void)saveVideoWithURL:(NSURL *)fileURL onCompletion:(void (^)(NSError *_Nullable))completion
{
    [self saveVideoWithURL:fileURL toAlbum:nil onCompletion:completion];
}

@end

@implementation PhotosService (System)

+ (BOOL)ps_isAlbumAuthorized
{
    PHAuthorizationStatus status = [self ps_albumAuthorizationStatus];
    return (status == PHAuthorizationStatusAuthorized);
}

+ (BOOL)ps_isAlbumLimited
{
    if (@available(iOS 14.0, *)) {
        PHAuthorizationStatus status = [self ps_albumAuthorizationStatus];
        return (status == PHAuthorizationStatusLimited);
    } else {
        return NO;
    }
}

+ (PHAuthorizationStatus)ps_albumAuthorizationStatus
{
    if (@available(iOS 14.0, *)) {
        PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatusForAccessLevel:PHAccessLevelReadWrite];
        return status;
    } else {
        PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
        return status;
    }
}

+ (BOOL)ps_isCameraAuthorized
{
    AVAuthorizationStatus status = [self ps_cameraAuthorizationStatus];
    return (status == AVAuthorizationStatusAuthorized);
}

+ (AVAuthorizationStatus)ps_cameraAuthorizationStatus
{
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    return status;
}

+ (NSDictionary *)ps_infoDictionary
{
    NSDictionary *infoData = [NSBundle mainBundle].localizedInfoDictionary;
    if (!infoData || !infoData.count) {
        infoData = [NSBundle mainBundle].infoDictionary;
    }
    if (!infoData || !infoData.count) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"Info" ofType:@"plist"];
        infoData = [NSDictionary dictionaryWithContentsOfFile:path];
    }
    return infoData ? infoData : @{};
}

+ (void)ps_openPhoneSettings
{
    UIApplication *application = [UIApplication sharedApplication];
    NSURL *settingURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    if (@available(iOS 10.0, *)) {
        [application openURL:settingURL options:@{} completionHandler:^(BOOL success) {
            
        }];
    } else {
        [application openURL:settingURL];
    }
}

@end

@implementation NSError (PhotosService)

+ (NSError *)ps_errorWithMessage:(NSString *)errorMessage code:(NSInteger)code
{
    NSError *error = [NSError errorWithDomain:PSErrorDomain code:code userInfo:@{
        NSLocalizedDescriptionKey : errorMessage,
        NSLocalizedFailureReasonErrorKey : errorMessage,
    }];
    return error;
}

@end
