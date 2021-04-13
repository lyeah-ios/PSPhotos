//
//  PHAsset+PSExtends.m
//  PSPhotos
//
//  Created by zisu on 2019/7/1.
//  Copyright © 2019 zisu. All rights reserved.
//

#import "PHAsset+PSExtends.h"
#import "PSDefines.h"
#import "PSPhotosDefines.h"
#import "PhotosService.h"
#import "PHImageManager+PSExtends.h"
#import <CoreServices/CoreServices.h>

/// Dummy class for category
@interface PHAsset_PSExtends : NSObject @end
@implementation PHAsset_PSExtends @end

@implementation PHAsset (PSExtends)

- (BOOL)ps_isGIF
{
    BOOL isGIF = NO;
    if (@available(iOS 11.0, *)) {
        isGIF = (self.playbackStyle == PHAssetPlaybackStyleImageAnimated);
    } else {
        if ([self ps_UTIString]) {
            isGIF = [[self ps_UTIString] isEqualToString:(__bridge NSString *)kUTTypeGIF];
        } else if ([self ps_fileName]) {
            isGIF = [[self ps_fileName].lowercaseString hasSuffix:@"gif"];
        }
    }
    return isGIF;
}

- (BOOL)ps_isPNG
{
    BOOL isPNG = NO;
    if ([self ps_UTIString]) {
        isPNG = [[self ps_UTIString] isEqualToString:(__bridge NSString *)kUTTypePNG];
    } else if ([self ps_fileName]) {
        isPNG = [[self ps_fileName].lowercaseString hasSuffix:@"png"];
    }
    return isPNG;
}

- (BOOL)ps_isJPEG
{
    BOOL isJPEG = NO;
    if ([self ps_UTIString]) {
        isJPEG = [[self ps_UTIString] isEqualToString:(__bridge NSString *)kUTTypeJPEG];
    } else if ([self ps_fileName]) {
        isJPEG = [[self ps_fileName].lowercaseString hasSuffix:@"jpeg"] || [[self ps_fileName].lowercaseString hasSuffix:@"jpg"];
    }
    return isJPEG;
}

- (BOOL)ps_isVideo
{
    return (self.mediaType == PHAssetMediaTypeVideo);
}

- (NSString *)ps_fileName
{
    NSString *fileName = nil;
    if ([self valueForKey:@"filename"]) {
        fileName = [self valueForKey:@"filename"];
    }
    return fileName;
}

- (NSString *)ps_UTIString
{
    NSString *ps_UTIString = nil;
    if ([self valueForKey:@"uniformTypeIdentifier"]) {
        ps_UTIString = [self valueForKey:@"uniformTypeIdentifier"];
    }
    return ps_UTIString;
}

- (BOOL)ps_isIniCloud
{
    BOOL result = NO;
    NSArray<PHAssetResource *> *resources = [PHAssetResource assetResourcesForAsset:self];
    if (resources.count > 0) {
        PHAssetResource *assetResource = resources.firstObject;
        id locallyAvailable = [assetResource valueForKey:@"locallyAvailable"];
        if (locallyAvailable) {
            result = ![locallyAvailable boolValue];
        }
    }
    return result;
}

+ (BOOL)ps_isDownloadFinined:(NSDictionary *)info
{
    BOOL downloadFinined = (![self ps_isDegraded:info] && ![self ps_isCancelled:info] && ![self ps_error:info]);
    return downloadFinined;
}

+ (BOOL)ps_isIniCloud:(NSDictionary *)info
{
    return [[info objectForKey:PHImageResultIsInCloudKey] boolValue];
}

+ (BOOL)ps_isDegraded:(NSDictionary *)info
{
    return [[info objectForKey:PHImageResultIsDegradedKey] boolValue];
}

+ (BOOL)ps_isCancelled:(NSDictionary *)info
{
    return [[info objectForKey:PHImageCancelledKey] boolValue];
}

+ (NSError *)ps_error:(NSDictionary *)info
{
    return [info objectForKey:PHImageErrorKey];
}

+ (BOOL)ps_isiCloudSyncError:(NSError *)error
{
    if (!error) return NO;
    if ([error.domain isEqualToString:@"CKErrorDomain"]
        || [error.domain isEqualToString:@"CloudPhotoLibraryErrorDomain"]) {
        return YES;
    }
    return NO;
}

- (PHImageRequestID)ps_requestImageWithOptions:(void (^)(PHImageRequestOptions * _Nonnull))optionsHandler
                                    targetSize:(CGSize)targetSize
                                   contentMode:(PHImageContentMode)contentMode
                                  onCompletion:(void (^)(UIImage * _Nullable, NSDictionary * _Nullable))completion
{
    PHImageRequestOptions *requestOptions = [[PHImageRequestOptions alloc] init];
    if (optionsHandler) {
        optionsHandler(requestOptions);
    }
    return [[PHImageManager defaultManager] requestImageForAsset:self targetSize:targetSize contentMode:contentMode options:requestOptions resultHandler:completion];
}

- (PHImageRequestID)ps_requestImageDataWithOptions:(void (^)(PHImageRequestOptions * _Nonnull))optionsHandler onCompletion:(void (^)(NSData * _Nullable, NSString * _Nullable, UIImageOrientation, NSDictionary * _Nullable))completion
{
    PHImageRequestOptions *requestOptions = [[PHImageRequestOptions alloc] init];
    if (optionsHandler) {
        optionsHandler(requestOptions);
    }
    return [[PHImageManager defaultManager] ps_requestImageDataForAsset:self options:requestOptions resultHandler:completion];
}

- (PHImageRequestID)ps_requestPlayerItem:(PHAssetVideoProgressHandler)progressHandler onCompletion:(nonnull void (^)(AVPlayerItem * _Nullable, NSDictionary * _Nullable))completion
{
    PHVideoRequestOptions *requestOptions = [[PHVideoRequestOptions alloc] init];
    requestOptions.networkAccessAllowed = YES;
    requestOptions.deliveryMode = PHVideoRequestOptionsDeliveryModeHighQualityFormat;
    if (progressHandler) {
        [requestOptions setProgressHandler:^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
            dispatch_async(dispatch_get_main_queue(), ^{
                progressHandler(progress, error, stop, info);
            });
        }];
    }
    return [[PHImageManager defaultManager] requestPlayerItemForVideo:self options:requestOptions resultHandler:completion];
}

- (PHImageRequestID)ps_requestVideoAsset:(PHAssetVideoProgressHandler)progressHandler onCompletion:(nonnull void (^)(AVAsset * _Nullable, AVAudioMix * _Nullable, NSDictionary * _Nullable))completion
{
    PHVideoRequestOptions *requestOptions = [[PHVideoRequestOptions alloc] init];
    requestOptions.networkAccessAllowed = YES;
    requestOptions.deliveryMode = PHVideoRequestOptionsDeliveryModeHighQualityFormat;
    if (progressHandler) {
        [requestOptions setProgressHandler:^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
            dispatch_async(dispatch_get_main_queue(), ^{
                progressHandler(progress, error, stop, info);
            });
        }];
    }
    return [[PHImageManager defaultManager] requestAVAssetForVideo:self options:requestOptions resultHandler:completion];
}

@end

@implementation PHAsset (PSConvenience)

- (PHImageRequestID)ps_requestImageWithSize:(CGSize)targetSize
                            progressHandler:(nullable PHAssetImageProgressHandler)progressHandler
                               onCompletion:(nonnull void (^)(UIImage * _Nullable, NSDictionary * _Nullable))completion
{
    BOOL isCustomSize = !CGSizeEqualToSize(targetSize, PHImageManagerMaximumSize);
    if (isCustomSize) {
        CGFloat scale = [UIScreen mainScreen].scale;
        targetSize = CGSizeMake(scale * targetSize.width, scale * targetSize.height);
    }
    return [self ps_requestImageWithOptions:^(PHImageRequestOptions * _Nonnull options) {
        options.networkAccessAllowed = YES;
        if (isCustomSize) {
            options.resizeMode = PHImageRequestOptionsResizeModeFast;
        }
        if (progressHandler) {
            [options setProgressHandler:^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    progressHandler(progress, error, stop, info);
                });
            }];
        }
    } targetSize:targetSize contentMode:PHImageContentModeAspectFill onCompletion:completion];
}

- (PHImageRequestID)ps_requestImageData:(PHAssetImageProgressHandler)progressHandler
                           onCompletion:(nonnull void (^)(NSData * _Nullable, NSString * _Nullable, UIImageOrientation, NSDictionary * _Nullable))completion
{
    return [self ps_requestImageDataWithOptions:^(PHImageRequestOptions * _Nonnull options) {
        options.networkAccessAllowed = YES;
        if ([self ps_isGIF]) {
            options.version = PHImageRequestOptionsVersionOriginal;
        }
        if (progressHandler) {
            [options setProgressHandler:^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    progressHandler(progress, error, stop, info);
                });
            }];
        }
    } onCompletion:completion];
}

- (void)ps_export:(NSURL *)fileURL progressHandler:(void (^)(CGFloat))progressHandler
     onCompletion:(void (^)(NSURL * _Nullable, NSDictionary * _Nullable, NSError * _Nullable))completion
{
    if (!fileURL) {
        NSString *extension = @"png";
        if (self.ps_isGIF) {
            extension = @"gif";
        } else if (self.ps_isJPEG) {
            extension = @"jpg";
        }
        NSString *fileName = [NSString stringWithFormat:@"%@.%@", [PhotosService uniqueRandomFileName], extension];
        NSString *filePath = [[PhotosService service].cacheDirectory stringByAppendingPathComponent:fileName];
        fileURL = [NSURL fileURLWithPath:filePath];
    }
    [self ps_requestImageData:^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
        if (progressHandler) {
            progressHandler(progress);
        }
    } onCompletion:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
        BOOL isDownloadFinined = [PHAsset ps_isDownloadFinined:info];
        if (imageData && isDownloadFinined) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSError *aError = nil;
                [imageData writeToURL:fileURL options:NSDataWritingAtomic error:&aError];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (!aError) {
                        if (completion) {
                            completion(fileURL, info, nil);
                        }
                    } else {
                        if (completion) {
                            completion(nil, info, aError);
                        }
                    }
                });
            });
        } else {
            NSError *error = [PHAsset ps_error:info];
            if (error) {
                if (completion) {
                    completion(nil, info, error);
                }
            } else {
                /// 这里可能是低清图或者被取消之类的，不作回调
            }
        }
    }];
}

@end
