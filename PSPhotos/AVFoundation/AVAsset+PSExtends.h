//
//  AVAsset+PSExtends.h
//  PSPhotos
//
//  Created by zisu on 2019/7/1.
//  Copyright © 2019 zisu. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AVAsset (PSExtends)

/**
 视频资源
 */
- (AVAssetTrack *_Nullable)ps_videoAssetTrack;

/**
 音频资源
 */
- (AVAssetTrack *_Nullable)ps_audioAssetTrack;

/**
 视频的真实分辨率
 */
- (CGSize)ps_videoSize;

/**
 视频是否为竖屏
 */
- (BOOL)ps_portrait;

/**
 视频的时长，单位秒
 */
- (Float64)ps_duration;

/**
 视频的码率
 */
- (float)ps_bitrate;

/**
 视频的帧率
 */
- (float)ps_normalFrameRate;

/**
 视频的封面
 */
- (UIImage *_Nullable)ps_coverImage;

/// 视频编码是否是 h.264
- (BOOL)ps_isVideoCodecH264;

/// 视频编码是否是 HEVC 即 h.265
- (BOOL)ps_isVideoCodecHEVC;

@end

@interface AVURLAsset (PSExtends)

@property (nonatomic, strong, readonly) NSNumber *ps_fileBytes;

- (NSData *)ps_binaryData;

@end

@interface AVAssetTrack (PSExtends)

/// formatDescription
- (CMFormatDescriptionRef)ps_CMFormatDescriptionRef;

/// mediaSubType
- (CMVideoCodecType)ps_CMVideoCodecType;

/// 视频编码是否是 h.264
- (BOOL)ps_isVideoCodecH264;

/// 视频编码是否是 HEVC 即 h.265
- (BOOL)ps_isVideoCodecHEVC;

@end

NS_ASSUME_NONNULL_END
