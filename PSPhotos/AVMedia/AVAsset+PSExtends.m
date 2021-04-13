//
//  AVAsset+PSExtends.m
//  PSPhotos
//
//  Created by zisu on 2019/7/1.
//  Copyright © 2019 zisu. All rights reserved.
//

#import "AVAsset+PSExtends.h"
#import "PSDefines.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

/// Dummy class for category
@interface AVAsset_PSExtends : NSObject @end
@implementation AVAsset_PSExtends @end

static const char PSAVAssetFileBytesKey = '\0';

@implementation AVAsset (PSExtends)

- (AVAssetTrack *)ps_videoAssetTrack
{
    NSArray<AVAssetTrack *> *tracksArray = self.tracks;
    AVAssetTrack *videoAssetTrack = nil;
    for (AVAssetTrack *track in tracksArray) {
        if ([track.mediaType isEqualToString:AVMediaTypeVideo]) {
            videoAssetTrack = track;
            break;
        }
    }
    return videoAssetTrack;
}

- (AVAssetTrack *)ps_audioAssetTrack
{
    NSArray<AVAssetTrack *> *tracksArray = self.tracks;
    AVAssetTrack *audioAssetTrack = nil;
    for (AVAssetTrack *track in tracksArray) {
        if ([track.mediaType isEqualToString:AVMediaTypeAudio]) {
            audioAssetTrack = track;
            break;
        }
    }
    return audioAssetTrack;
}

- (CGSize)ps_videoSize
{
    AVAssetTrack *videoAssetTrack = [self ps_videoAssetTrack];
    CGSize videoSize = CGSizeZero;
    if (videoAssetTrack) {
        CGSize naturalSize = videoAssetTrack.naturalSize;
        CGAffineTransform preferredTransform = videoAssetTrack.preferredTransform;
        CGSize size = CGSizeApplyAffineTransform(naturalSize, preferredTransform);
        videoSize = CGSizeMake(fabs(size.width), fabs(size.height));
    }
    return videoSize;
}

- (BOOL)ps_portrait
{
    AVAssetTrack *videoAssetTrack = [self ps_videoAssetTrack];
    BOOL isVideoPortrait = NO;
    if (videoAssetTrack) {
        CGAffineTransform videoPreferredTransform = videoAssetTrack.preferredTransform;
        if (videoPreferredTransform.a == 0 && videoPreferredTransform.b == 1.0 && videoPreferredTransform.c == -1.0 && videoPreferredTransform.d == 0)  {
            isVideoPortrait = YES;
        }
        if (videoPreferredTransform.a == 0 && videoPreferredTransform.b == -1.0 && videoPreferredTransform.c == 1.0 && videoPreferredTransform.d == 0)  {
            isVideoPortrait = YES;
        }
        if (videoPreferredTransform.a == 1.0 && videoPreferredTransform.b == 0 && videoPreferredTransform.c == 0 && videoPreferredTransform.d == 1.0)   {
            isVideoPortrait = NO;
        }
        if (videoPreferredTransform.a == -1.0 && videoPreferredTransform.b == 0 && videoPreferredTransform.c == 0 && videoPreferredTransform.d == -1.0) {
            isVideoPortrait = NO;
        }
    }
    return isVideoPortrait;
}

- (Float64)ps_duration
{
    CMTime time = [self duration];
    return CMTimeGetSeconds(time);
}

- (float)ps_bitrate
{
    CGFloat bitRate = 0;
    AVAssetTrack *videoAssetTrack = [self ps_videoAssetTrack];
    if (videoAssetTrack) {
        bitRate = videoAssetTrack.estimatedDataRate;
    }
    return bitRate;
}

- (float)ps_normalFrameRate
{
    CGFloat frameRate = 0;
    AVAssetTrack *videoAssetTrack = [self ps_videoAssetTrack];
    if (videoAssetTrack) {
        frameRate = videoAssetTrack.nominalFrameRate;
    }
    return frameRate;
}

- (BOOL)ps_isVideoCodecH264
{
    BOOL isH264 = NO;
    AVAssetTrack *videoAssetTrack = [self ps_videoAssetTrack];
    if (videoAssetTrack) {
        isH264 = videoAssetTrack.ps_isVideoCodecH264;
    }
    return isH264;
}

- (BOOL)ps_isVideoCodecHEVC
{
    BOOL isHEVC = NO;
    AVAssetTrack *videoAssetTrack = [self ps_videoAssetTrack];
    if (videoAssetTrack) {
        isHEVC = videoAssetTrack.ps_isVideoCodecHEVC;
    }
    return isHEVC;
}

- (void)ps_checkAssetPlayable:(void (^)(BOOL))block
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BOOL isPlayable = self.isPlayable;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (block) {
                block(isPlayable);
            }
        });
    });
}

@end

@implementation AVURLAsset (PSExtends)

- (NSNumber *)ps_fileBytes
{
    NSNumber *fileBytes = (NSNumber *)objc_getAssociatedObject(self, &PSAVAssetFileBytesKey);
    if (!fileBytes) {
        fileBytes = [self.URL ps_fileBytes];
        objc_setAssociatedObject(self, &PSAVAssetFileBytesKey, fileBytes, OBJC_ASSOCIATION_RETAIN);
    }
    return fileBytes;
}

- (NSData *)ps_binaryData
{
    NSData *binaryData = nil;
    if (self.URL) {
        binaryData = [self.URL ps_binaryData];
    }
    return binaryData;
}

@end

@implementation NSURL (PSExtends)

- (NSNumber *)ps_fileBytes
{
    NSNumber *fileBytes = @(0);
    NSError *error = nil;
    if ([self isFileURL]) {
        [self getResourceValue:&fileBytes forKey:NSURLFileSizeKey error:&error];
    }
    return fileBytes;
}

- (NSData *)ps_binaryData
{
    NSData *binaryData = nil;
    if ([self isFileURL]) {
        NSError *error = nil;
        /// [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:&error] 不能用在大于 200M的文件上，改用NSFileHandle
        NSUInteger fileSize = [self.ps_fileBytes unsignedIntegerValue];
        if (fileSize > 16 * 1000.0f * 1000.0f) {
            NSError *readError = nil;
            NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingFromURL:self error:&readError];
            if (fileHandle) {
                if (@available(iOS 13.0, *)) {
                    [fileHandle seekToOffset:0 error:&error];
                    binaryData = [fileHandle readDataUpToLength:fileSize error:&error];
                } else {
                    [fileHandle seekToFileOffset:0];
                    binaryData = [fileHandle readDataOfLength:fileSize];
                }
            } else {
                PSLog(@"%@", readError);
                binaryData = [NSData dataWithContentsOfURL:self options:NSDataReadingMappedAlways error:&error];
            }
        } else {
            binaryData = [NSData dataWithContentsOfURL:self options:NSDataReadingMappedAlways error:&error];
        }
    }
    return binaryData;
}

@end

@implementation AVAssetTrack (PSExtends)

- (CMFormatDescriptionRef)ps_CMFormatDescriptionRef
{
    NSArray *formatDescriptions = [self formatDescriptions];
    CMFormatDescriptionRef formatDescription = (__bridge CMFormatDescriptionRef)(formatDescriptions.firstObject);
    return formatDescription;
}

- (CMVideoCodecType)ps_CMVideoCodecType
{
    CMFormatDescriptionRef formatDescription = [self ps_CMFormatDescriptionRef];
    CMVideoCodecType codecType = CMVideoFormatDescriptionGetCodecType(formatDescription);
    return codecType;
}

- (BOOL)ps_isVideoCodecH264
{
    BOOL isH264 = NO;
    CMVideoCodecType codecType = [self ps_CMVideoCodecType];
    isH264 = (codecType == kCMVideoCodecType_H264);
    return isH264;
}

- (BOOL)ps_isVideoCodecHEVC
{
    BOOL isHEVC = NO;
    CMVideoCodecType codecType = [self ps_CMVideoCodecType];
    isHEVC = (codecType == kCMVideoCodecType_HEVC);
    return isHEVC;
}

@end
