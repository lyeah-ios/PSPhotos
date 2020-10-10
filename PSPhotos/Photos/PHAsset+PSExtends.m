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
    return [[self valueForKey:@"filename"] hasSuffix:@"GIF"] || [[self ps_UTIString] isEqualToString:(__bridge NSString *)kUTTypeGIF];
}

- (BOOL)ps_isVideo
{
    return (self.mediaType == PHAssetMediaTypeVideo);
}

- (NSString *)ps_UTIString
{
    return [self valueForKey:@"uniformTypeIdentifier"];
}

- (PHImageRequestID)ps_requestImageWithSize:(CGSize)targetSize progressHandler:(nullable PHAssetImageProgressHandler)progressHandler onCompletion:(nonnull void (^)(UIImage * _Nullable, NSDictionary * _Nullable))completion
{
    PHImageRequestOptions *requestOptions = [[PHImageRequestOptions alloc] init];
    requestOptions.networkAccessAllowed = YES;
    requestOptions.resizeMode = PHImageRequestOptionsResizeModeFast;
    if (progressHandler) {
        [requestOptions setProgressHandler:^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
            dispatch_async(dispatch_get_main_queue(), ^{
                PSLog(@"正在从iCloud同步...%f", progress);
                progressHandler(progress, error, stop, info);
            });
        }];
    }
    CGFloat scale = [UIScreen mainScreen].scale;
    targetSize = CGSizeMake(scale *targetSize.width, scale *targetSize.height);
    return [[PHImageManager defaultManager] requestImageForAsset:self targetSize:targetSize contentMode:PHImageContentModeAspectFill options:requestOptions resultHandler:completion];
}

- (PHImageRequestID)ps_requestImageData:(PHAssetImageProgressHandler)progressHandler onCompletion:(nonnull void (^)(NSData * _Nullable, NSString * _Nullable, UIImageOrientation, NSDictionary * _Nullable))completion
{
    PHImageRequestOptions *requestOptions = [[PHImageRequestOptions alloc] init];
    requestOptions.networkAccessAllowed = YES;
    if ([self ps_isGIF]) {
        requestOptions.version = PHImageRequestOptionsVersionOriginal;
    }
    if (progressHandler) {
        [requestOptions setProgressHandler:^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
            dispatch_async(dispatch_get_main_queue(), ^{
                PSLog(@"正在从iCloud同步...%f", progress);
                progressHandler(progress, error, stop, info);
            });
        }];
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
                PSLog(@"正在从iCloud同步...%f", progress);
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
                PSLog(@"正在从iCloud同步...%f", progress);
                progressHandler(progress, error, stop, info);
            });
        }];
    }
    return [[PHImageManager defaultManager] requestAVAssetForVideo:self options:requestOptions resultHandler:completion];
}

@end

@implementation PHAsset (PSConvenience)

- (void)ps_fetchImageData:(void (^)(CGFloat, BOOL))progressHandler onCompletion:(nonnull void (^)(NSData * _Nullable, UIImage * _Nullable, NSDictionary * _Nullable, NSError * _Nullable))completion
{
    PHImageRequestOptions *requestOptions = [[PHImageRequestOptions alloc] init];
    __weak typeof(self)wself = self;
    [[PHImageManager defaultManager] ps_requestImageDataForAsset:self options:requestOptions resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
        BOOL isDegraded  = [info[PHImageResultIsDegradedKey] boolValue];
        BOOL isCancelled = [info[PHImageCancelledKey] boolValue];
        NSError *error  = info[PHImageErrorKey];
        if (imageData && !isDegraded && !isCancelled && !error) {
            PSLog(@"该图片本地已存在：%@", info);
            if (progressHandler) {
                progressHandler(1.0f, NO);
            }
            //本地已经读取到则直接返回
            [wself requestImageDataSuccess:imageData info:info onCompletion:completion];
        } else {
            PSLog(@"该图片本地不存在：%@", info);
            //本地没有读取到则直接下载
            [self ps_requestImageData:^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
                if (progressHandler) {
                    progressHandler(progress, YES);
                }
            } onCompletion:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
                [wself requestImageDataSuccess:imageData info:info onCompletion:completion];
            }];
        }
    }];
}

- (void)requestImageDataSuccess:(NSData *)imageData info:(NSDictionary *)info onCompletion:(nonnull void (^)(NSData * _Nullable, UIImage * _Nullable, NSDictionary * _Nullable, NSError * _Nullable))completion
{
    if (![info isKindOfClass:[NSDictionary class]]) {
        info = @{};
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableDictionary *mutableInfo = [info mutableCopy];
        BOOL isDegraded  = [mutableInfo[PHImageResultIsDegradedKey] boolValue];
        BOOL isCancelled = [mutableInfo[PHImageCancelledKey] boolValue];
        NSError *error  = mutableInfo[PHImageErrorKey];
        if (imageData && !isDegraded && !isCancelled && !error) {
            CGFloat fileSize = imageData.length/(1000.0f * 1000.0f);
            mutableInfo[@"fileSize"]    = @(fileSize);
            UIImage *resultImage = [UIImage imageWithData:imageData];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion(imageData, resultImage, [mutableInfo copy], nil);
                }
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    if (error) {
                        completion(nil, nil, nil, error);
                    } else {
                        NSError *aError = [NSError ps_errorWithMessage:@"iCloud同步图片不成功" code:PSErrorCodeSyncFailed];
                        completion(nil, nil, nil, aError);
                    }
                }
            });
        }
    });
}

- (void)ps_export:(NSURL *)fileURL progressHandler:(void (^)(CGFloat, BOOL))progressHandler onCompletion:(void (^)(NSURL * _Nullable, NSDictionary * _Nullable, NSError * _Nullable))completion
{
    if (!fileURL) {
        NSString *extension = self.ps_isGIF ? @"gif" : @"png";
        NSString *fileName = [NSString stringWithFormat:@"%@.%@", [PhotosService uniqueRandomFileName], extension];
        NSString *filePath = [[PhotosService service].cacheDirectory stringByAppendingPathComponent:fileName];
        fileURL = [NSURL fileURLWithPath:filePath];
    }
    [self ps_fetchImageData:progressHandler onCompletion:^(NSData * _Nullable imageData, UIImage * _Nullable resultImage, NSDictionary * _Nullable info, NSError * _Nullable error) {
        if (error) {
            if (completion) {
                completion(nil, info, error);
            }
        } else {
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
        }
    }];
}

@end
