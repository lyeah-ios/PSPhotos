//
//  AVAsset+PSExport.h
//  PSPhotos
//
//  Created by zisu on 2019/7/28.
//  Copyright © 2019 zisu. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@class PSAVAssetExportSession;

/// 导出视频
@interface AVAsset (PSExport)

/// 方便调用取消导出，成功，失败，取消都会被置为nil
@property (nullable, nonatomic, strong, readonly) AVAssetExportSession *aSession;

/// 方便调用取消导出，成功，失败，取消都会被置为nil
@property (nullable, nonatomic, strong, readonly) PSAVAssetExportSession *pSession;

- (void)ps_export:(NSString *)presetName onPrepare:(void(^)(AVAssetExportSession *session))prepare onSuccess:(void(^_Nullable)(AVAssetExportSession *session, NSURL *outputURL))success onFailure:(void(^_Nullable)(AVAssetExportSession *_Nullable session, NSError *error))failure;

- (void)ps_export:(void(^)(PSAVAssetExportSession *session))prepare onSuccess:(void(^_Nullable)(PSAVAssetExportSession *session, NSURL *outputURL))success onFailure:(void(^_Nullable)(PSAVAssetExportSession *session, NSError *error))failure;

- (void)ps_cancelExport;

- (NSDictionary *)ps_defaultVideoInputSettings;
- (NSDictionary *)ps_defaultVideoSettings;
- (NSDictionary *)ps_defaultAudioSettings;
- (NSDictionary *)ps_defaultVideoCompressSettings:(CGFloat)compression;
- (NSDictionary *)ps_videoCompressSettings:(CGSize)targetSize averageBitRate:(CGFloat)averageBitRate normalFrameRate:(CGFloat)normalFrameRate;

@end

@interface AVAsset (PSAVImageGenerator)

/// 方便调用取消导出，成功，失败，取消都会被置为nil
@property (nullable, nonatomic, strong, readonly) AVAssetImageGenerator *ps_imageGenerator;

/// 生成指定的一系列时间的截图
/// @param requestedTimes 时间数组
/// @param prepare 准备
/// @param success 成功，会多次回调，每次一张图
/// @param failure 失败
- (void)ps_generateImagesWithTimes:(NSArray<NSValue *> *)requestedTimes onPrepare:(void(^)(AVAssetImageGenerator *generator))prepare onSuccess:(void(^_Nullable)(AVAssetImageGenerator *generator, UIImage *resultImage))success onFailure:(void(^_Nullable)(AVAssetImageGenerator *_Nullable generator, NSError *error))failure;

/// 取消生成器
- (void)ps_cancelImageGeneration;

/// 视频的封面
- (UIImage *_Nullable)ps_coverImage;

/// 对某个时间截图
- (UIImage *_Nullable)ps_screenshotAtTime:(CMTime)time;

@end

NS_ASSUME_NONNULL_END
