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

/**
 是否为GIF
 */
- (BOOL)ps_isGIF;

/**
 是否是视频
 */
- (BOOL)ps_isVideo;

/**
 UTI
 */
- (NSString *)ps_UTIString;

/**
 获取指定大小的图片，可能会请求网络
 */
- (PHImageRequestID)ps_requestImageWithSize:(CGSize)targetSize progressHandler:(nullable PHAssetImageProgressHandler)progressHandler onCompletion:(void (^)(UIImage *__nullable resultImage, NSDictionary *__nullable info))completion;

/**
 获取图片元数据，可能会请求网络
 */
- (PHImageRequestID)ps_requestImageData:(nullable PHAssetImageProgressHandler)progressHandler onCompletion:(void(^)(NSData *__nullable imageData, NSString *__nullable dataUTI, UIImageOrientation orientation, NSDictionary *__nullable info))completion;

/**
 获取视频，可能会请求网络
 */
- (PHImageRequestID)ps_requestPlayerItem:(nullable PHAssetVideoProgressHandler)progressHandler onCompletion:(void (^)(AVPlayerItem * __nullable playerItem, NSDictionary *__nullable info))completion;
- (PHImageRequestID)ps_requestVideoAsset:(nullable PHAssetVideoProgressHandler)progressHandler onCompletion:(void (^)(AVAsset *__nullable asset, AVAudioMix *__nullable audioMix, NSDictionary *__nullable info))completion;

@end

@interface PHAsset (PSConvenience)

/**
 获取图片，本地存在直接读取本地，本地不存在，从iCloud获取
 */
- (void)ps_fetchImageData:(void (^)(CGFloat progress, BOOL is_iCloud))progressHandler onCompletion:(void(^)(NSData *__nullable imageData, UIImage *__nullable resultImage, NSDictionary *__nullable info, NSError *__nullable error))completion;

/**
 基于- (void)ps_requestImageData:获取图片，并且存储到指定沙盒地址
*/
- (void)ps_export:(NSURL *_Nullable)fileURL progressHandler:(void (^)(CGFloat progress, BOOL is_iCloud))progressHandler onCompletion:(void(^)(NSURL *__nullable fileURL, NSDictionary *__nullable info, NSError *__nullable error))completion;

@end

NS_ASSUME_NONNULL_END
