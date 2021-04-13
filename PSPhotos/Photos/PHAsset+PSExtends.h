//
//  PHAsset+PSExtends.h
//  PSPhotos
//
//  Created by zisu on 2019/7/1.
//  Copyright © 2019 zisu. All rights reserved.
//

#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@interface PHAsset (PSExtends)

/// 是否为GIF
- (BOOL)ps_isGIF;

/// 是否为PNG
- (BOOL)ps_isPNG;

/// 是否为JPEG
- (BOOL)ps_isJPEG;

/// 是否是视频
- (BOOL)ps_isVideo;

/// UTI
- (nullable NSString *)ps_UTIString;

/// 文件名
- (nullable NSString *)ps_fileName;

/// 是否在 iCloud 中
- (BOOL)ps_isIniCloud;

/// 是否下载完成
+ (BOOL)ps_isDownloadFinined:(NSDictionary *)info;

/// 是否在 iCloud 中
+ (BOOL)ps_isIniCloud:(NSDictionary *)info;

/// 是否是低清图
+ (BOOL)ps_isDegraded:(NSDictionary *)info;

/// 是否已取消
+ (BOOL)ps_isCancelled:(NSDictionary *)info;

/// 错误信息
+ (NSError *)ps_error:(NSDictionary *)info;

/// 是否是 iCloud 同步错误
+ (BOOL)ps_isiCloudSyncError:(NSError *)error;

/// 通用获取 UIImage 的方法，可自定义 PHImageRequestOptions
- (PHImageRequestID)ps_requestImageWithOptions:(void (^_Nullable)(PHImageRequestOptions *options))optionsHandler
                                    targetSize:(CGSize)targetSize
                                   contentMode:(PHImageContentMode)contentMode
                                  onCompletion:(void (^)(UIImage *_Nullable resultImage, NSDictionary *_Nullable info))completion;

/// 通用获取 imageData 的方法，可自定义 PHImageRequestOptions
- (PHImageRequestID)ps_requestImageDataWithOptions:(void (^_Nullable)(PHImageRequestOptions *options))optionsHandler
                                      onCompletion:(void(^)(NSData *_Nullable imageData, NSString *_Nullable dataUTI, UIImageOrientation orientation, NSDictionary *_Nullable info))completion;

/**
 获取视频，可能会请求网络
 */
- (PHImageRequestID)ps_requestPlayerItem:(nullable PHAssetVideoProgressHandler)progressHandler onCompletion:(void (^)(AVPlayerItem * __nullable playerItem, NSDictionary *__nullable info))completion;
- (PHImageRequestID)ps_requestVideoAsset:(nullable PHAssetVideoProgressHandler)progressHandler onCompletion:(void (^)(AVAsset *__nullable asset, AVAudioMix *__nullable audioMix, NSDictionary *__nullable info))completion;

@end

@interface PHAsset (PSConvenience)

/// 获取指定大小的图片，可能会请求网络，基于 ps_requestImageWithOptions 实现
- (PHImageRequestID)ps_requestImageWithSize:(CGSize)targetSize
                            progressHandler:(nullable PHAssetImageProgressHandler)progressHandler
                               onCompletion:(void (^)(UIImage *_Nullable resultImage, NSDictionary *_Nullable info))completion;

/// 获取图片元数据，可能会请求网络，基于 ps_requestImageDataWithOptions 实现
- (PHImageRequestID)ps_requestImageData:(nullable PHAssetImageProgressHandler)progressHandler
                           onCompletion:(void(^)(NSData *_Nullable imageData, NSString *_Nullable dataUTI, UIImageOrientation orientation, NSDictionary *_Nullable info))completion;

/// 基于- (void)ps_requestImageData:获取图片，并且存储到指定沙盒地址
- (void)ps_export:(NSURL *_Nullable)fileURL progressHandler:(void (^)(CGFloat progress))progressHandler
     onCompletion:(void(^)(NSURL *__nullable fileURL, NSDictionary *__nullable info, NSError *__nullable error))completion;

@end

NS_ASSUME_NONNULL_END
