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

/**
 导出视频
 */
@interface AVAsset (PSExport)

/**
 方便调用取消导出，成功，失败，取消都会被置为nil
 */
@property (nullable, nonatomic, strong) AVAssetExportSession *aSession;

/**
 方便调用取消导出，成功，失败，取消都会被置为nil
 */
@property (nullable, nonatomic, strong) PSAVAssetExportSession *pSession;

- (void)ps_export:(NSString *)presetName onPrepare:(void(^)(AVAssetExportSession *session))prepare onSuccess:(void(^_Nullable)(AVAssetExportSession *session, NSURL *outputURL))success onFailure:(void(^_Nullable)(AVAssetExportSession *_Nullable session, NSError *error))failure;

- (void)ps_export:(void(^)(PSAVAssetExportSession *session))prepare onSuccess:(void(^_Nullable)(PSAVAssetExportSession *session, NSURL *outputURL))success onFailure:(void(^_Nullable)(PSAVAssetExportSession *session, NSError *error))failure;

- (void)ps_cancelExport;

- (NSDictionary *)ps_defaultVideoInputSettings;
- (NSDictionary *)ps_defaultVideoSettings;
- (NSDictionary *)ps_defaultAudioSettings;
- (NSDictionary *)ps_defaultVideoCompressSettings:(CGFloat)compression;
- (NSDictionary *)ps_videoCompressSettings:(CGSize)targetSize averageBitRate:(CGFloat)averageBitRate normalFrameRate:(CGFloat)normalFrameRate;

@end

NS_ASSUME_NONNULL_END
