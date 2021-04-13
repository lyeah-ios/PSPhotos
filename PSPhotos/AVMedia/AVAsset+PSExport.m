//
//  AVAsset+PSExport.m
//  PSPhotos
//
//  Created by zisu on 2019/7/28.
//  Copyright © 2019 zisu. All rights reserved.
//

#import "AVAsset+PSExport.h"
#import "PSDefines.h"
#import "AVAsset+PSExtends.h"
#import <objc/runtime.h>
#import "AVAssetExportSession+PSExtends.h"
#import "PSAVAssetExportSession+PSExtends.h"
#import "AVAssetImageGenerator+PSExtends.h"

/// Dummy class for category
@interface AVAsset_PSExport : NSObject @end
@implementation AVAsset_PSExport @end

static const char PSSystemExportSessionKey = '\0';
static const char PSCustomExportSessionKey = '\0';
static const char PSAVAssetImageGeneratorKey = '\0';

@implementation AVAsset (PSExport)

- (void)setASession:(AVAssetExportSession *)aSession
{
    objc_setAssociatedObject(self, &PSSystemExportSessionKey, aSession, OBJC_ASSOCIATION_RETAIN);
}

- (AVAssetExportSession *)aSession
{
    return (AVAssetExportSession *)objc_getAssociatedObject(self, &PSSystemExportSessionKey);
}

- (void)ps_export:(NSString *)presetName onPrepare:(void (^)(AVAssetExportSession * _Nonnull))prepare onSuccess:(void (^)(AVAssetExportSession * _Nonnull, NSURL * _Nonnull))success onFailure:(void (^)(AVAssetExportSession * _Nullable, NSError * _Nonnull))failure
{
    [AVAssetExportSession ps_exportAsset:self presetName:presetName onPrepare:^(AVAssetExportSession * _Nonnull session) {
        self.aSession = session;
        if (prepare) {
            prepare(session);
        }
    } onSuccess:^(AVAssetExportSession * _Nonnull session, NSURL * _Nonnull outputURL) {
        if (success) {
            success(session, outputURL);
        }
        self.aSession = nil;
    } onFailure:^(AVAssetExportSession * _Nullable session, NSError * _Nonnull error) {
        if (failure) {
            failure(session, error);
        }
        self.aSession = nil;
    }];
}

- (void)setPSession:(PSAVAssetExportSession *)pSession
{
    objc_setAssociatedObject(self, &PSCustomExportSessionKey, pSession, OBJC_ASSOCIATION_RETAIN);
}

- (PSAVAssetExportSession *)pSession
{
    return (PSAVAssetExportSession *)objc_getAssociatedObject(self, &PSCustomExportSessionKey);
}

- (void)ps_export:(void (^)(PSAVAssetExportSession * _Nonnull))prepare onSuccess:(void (^)(PSAVAssetExportSession * _Nonnull, NSURL * _Nonnull))success onFailure:(void (^)(PSAVAssetExportSession * _Nonnull, NSError * _Nonnull))failure
{
    [PSAVAssetExportSession ps_exportAsset:self onPrepare:^(PSAVAssetExportSession * _Nonnull session) {
        self.pSession = session;
        if (prepare) {
            prepare(session);
        }
    } onSuccess:^(PSAVAssetExportSession * _Nonnull session, NSURL * _Nonnull outputURL) {
        if (success) {
            success(session, outputURL);
        }
        self.pSession = nil;
    } onFailure:^(PSAVAssetExportSession * _Nonnull session, NSError * _Nonnull error) {
        if (failure) {
            failure(session, error);
        }
        self.pSession = nil;
    }];
}

- (void)ps_cancelExport
{
    if (self.aSession) {
        [self.aSession cancelExport];
        self.aSession = nil;
    }
    if (self.pSession) {
        [self.pSession cancelExport];
        self.pSession = nil;
    }
}

- (NSDictionary *)ps_defaultVideoInputSettings
{
    return @{
             (__bridge NSString *)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32BGRA),
             };
}

- (NSDictionary *)ps_defaultVideoSettings
{
    CGSize videoSize = self.ps_videoSize;
    CGFloat videoWidth = roundf(videoSize.width/16) * 16;
    CGFloat videoHeight = roundf(videoSize.height/16) * 16;
    CGFloat averageBitRate = self.ps_bitrate;
    CGFloat normalFrameRate = self.ps_normalFrameRate;
    return [self ps_videoCompressSettings:CGSizeMake(videoWidth, videoHeight) averageBitRate:averageBitRate normalFrameRate:normalFrameRate];
}

- (NSDictionary *)ps_defaultAudioSettings
{
    NSDictionary *audioSettings = @{
                                    AVFormatIDKey         : @(kAudioFormatMPEG4AAC),
                                    AVNumberOfChannelsKey : @(2),
                                    AVSampleRateKey       : @(44100),
                                    AVEncoderBitRateKey   : @(PSAudioBitRate_128Kbps),
                                    };
    return audioSettings;
}

- (NSDictionary *)ps_defaultVideoCompressSettings:(CGFloat)compression
{
    CGSize videoSize = self.ps_videoSize;
    CGFloat videoWidth = roundf(videoSize.width/16) * 16;
    CGFloat videoHeight = roundf(videoSize.height/16) * 16;
    CGFloat maxLength = MAX(videoWidth, videoHeight);
    CGFloat minLength = MIN(videoWidth, videoHeight);
    CGFloat factor    = minLength/maxLength;
    BOOL isOverSize = (maxLength > 960.0f && minLength > 544.0f);
    if (isOverSize) {
        //视频宽高过大，需要进行裁剪，最长边设为960.0f
        if (videoWidth > videoHeight) {
            videoWidth = 960.0f;
            videoHeight = videoWidth * factor;
        } else {
            videoHeight = 960.0f;
            videoWidth = videoHeight * factor;
        }
    } else {
        //其他尺寸不做处理，不考虑异形视频
    }
    CGFloat sizePercent = 960.0f/MAX(maxLength, 960.0f);
    CGFloat normalFrameRate = self.ps_normalFrameRate;
    PSLog(@"originFrameRate:%@", @(normalFrameRate));
    CGFloat averageFrameRate = 30.0f;
    CGFloat frameRatePercent = averageFrameRate/normalFrameRate;
    PSLog(@"frameRatePercent:%@", @(frameRatePercent));
    frameRatePercent = MIN(frameRatePercent, 1.0f);
    PSLog(@"minFrameRatePercent:%@", @(frameRatePercent));
    averageFrameRate = MIN(normalFrameRate, averageFrameRate);
    averageFrameRate = ceilf(averageFrameRate);
    PSLog(@"resultFrameRate:%@", @(averageFrameRate));
    CGFloat percent = 1.0f;
    percent = percent *sizePercent *frameRatePercent *compression;
    PSLog(@"percent:%@", @(percent));
    PSLog(@"originBitRate:%@", @(self.ps_bitrate));
    CGFloat averageBitRate = self.ps_bitrate *percent;
    averageBitRate = ceilf(averageBitRate);
    PSLog(@"resultBitRate:%@", @(averageBitRate));
    return [self ps_videoCompressSettings:CGSizeMake(videoWidth, videoHeight) averageBitRate:averageBitRate normalFrameRate:averageFrameRate];
}

- (NSDictionary *)ps_videoCompressSettings:(CGSize)targetSize averageBitRate:(CGFloat)averageBitRate normalFrameRate:(CGFloat)normalFrameRate
{
    NSString *codecType = @"";
    if (@available(iOS 11.0, *)) {
        codecType = AVVideoCodecTypeH264;
    } else {
        codecType = AVVideoCodecH264;
    }
    NSDictionary *videoSettings = @{
                                    AVVideoCodecKey                 : codecType,
                                    AVVideoWidthKey                 : @(targetSize.width),
                                    AVVideoHeightKey                : @(targetSize.height),
                                    AVVideoScalingModeKey           : AVVideoScalingModeResizeAspectFill,
                                    AVVideoCompressionPropertiesKey : @{
                                            AVVideoAverageBitRateKey : @(averageBitRate),
                                            AVVideoAverageNonDroppableFrameRateKey : @(normalFrameRate),
                                            AVVideoProfileLevelKey   : AVVideoProfileLevelH264BaselineAutoLevel,
                                            },
                                    };
    return videoSettings;
}

@end

@implementation AVAsset (PSImageGenerator)

- (void)setPs_imageGenerator:(AVAssetImageGenerator *)ps_imageGenerator
{
    objc_setAssociatedObject(self, &PSAVAssetImageGeneratorKey, ps_imageGenerator, OBJC_ASSOCIATION_RETAIN);
}

- (AVAssetImageGenerator *)ps_imageGenerator
{
    return (AVAssetImageGenerator *)objc_getAssociatedObject(self, &PSAVAssetImageGeneratorKey);
}

- (void)ps_generateImagesWithTimes:(NSArray<NSValue *> *)requestedTimes onPrepare:(void (^)(AVAssetImageGenerator * _Nonnull))prepare onSuccess:(void (^)(AVAssetImageGenerator * _Nonnull, UIImage * _Nonnull))success onFailure:(void (^)(AVAssetImageGenerator * _Nullable, NSError * _Nonnull))failure
{
    [AVAssetImageGenerator ps_generatorImagesWithAsset:self requestedTimes:requestedTimes onPrepare:^(AVAssetImageGenerator * _Nonnull generator) {
        self.ps_imageGenerator = generator;
        if (prepare) {
            prepare(generator);
        }
    } onSuccess:^(AVAssetImageGenerator * _Nonnull generator, UIImage * _Nonnull resultImage) {
        if (success) {
            success(generator, resultImage);
        }
        self.ps_imageGenerator = nil;
    } onFailure:^(AVAssetImageGenerator * _Nullable generator, NSError * _Nonnull error) {
        if (failure) {
            failure(generator, error);
        }
        self.ps_imageGenerator = nil;
    }];
}

- (void)ps_cancelImageGeneration
{
    [self.ps_imageGenerator cancelAllCGImageGeneration];
}

- (UIImage *)ps_coverImage
{
    float frameRate = [self ps_normalFrameRate];
    Float64 seconds = 0;
    /// 防止视频第一帧为黑屏，影响美观
    if ([self ps_duration] >= 1) {
        seconds = 1;
    }
    CMTime snaptime = CMTimeMakeWithSeconds(seconds, frameRate);
    UIImage *currentFrame = [self ps_screenshotAtTime:snaptime];
    return currentFrame;
}

- (UIImage *)ps_screenshotAtTime:(CMTime)time
{
    AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:self];
    generator.requestedTimeToleranceBefore = kCMTimeZero;
    generator.requestedTimeToleranceAfter = kCMTimeZero;
    generator.appliesPreferredTrackTransform = YES;
    CGImageRef cgImageRef = [generator copyCGImageAtTime:time actualTime:&time error:nil];
    UIImage *resultImage = [UIImage imageWithCGImage:cgImageRef];
    return resultImage;
}

@end
