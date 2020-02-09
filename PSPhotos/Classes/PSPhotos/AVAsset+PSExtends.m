//
//  AVAsset+PSExtends.m
//  PSPhotos
//
//  Created by zisu on 2019/7/1.
//  Copyright © 2019 zisu. All rights reserved.
//

#import "AVAsset+PSExtends.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

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

- (UIImage *)ps_coverImage
{
    AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:self];
    generator.appliesPreferredTrackTransform = YES;
    float frameRate = [self ps_normalFrameRate];
    Float64 seconds = 0;
    //防止视频第一帧为黑屏，影响美观
    if ([self ps_duration] >= 1) {
        seconds = 1;
    }
    CMTime snaptime = CMTimeMakeWithSeconds(seconds, frameRate);
    CMTime time2;
    CGImageRef cgImageRef = [generator copyCGImageAtTime:snaptime actualTime:&time2 error:nil];
    UIImage *currentFrame = [UIImage imageWithCGImage:cgImageRef];
    return currentFrame;
}

@end

@implementation AVURLAsset (PSExtends)

- (NSNumber *)ps_fileBytes
{
    NSNumber *fileBytes = (NSNumber *)objc_getAssociatedObject(self, &PSAVAssetFileBytesKey);
    if (!fileBytes) {
        NSError *error = nil;
        if (self.URL) {
            [self.URL getResourceValue:&fileBytes forKey:NSURLFileSizeKey error:&error];
        }
        if (!fileBytes) {
            fileBytes = @(0);
        }
        objc_setAssociatedObject(self, &PSAVAssetFileBytesKey, fileBytes, OBJC_ASSOCIATION_RETAIN);
    }
    return fileBytes;
}

- (NSData *)ps_binaryData
{
    NSData *binaryData = nil;
    if (self.URL) {
        NSError *error = nil;
        //[NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:&error] 不能用在大于 200M的文件上，改用NSFileHandle
        NSUInteger fileSize = [self.ps_fileBytes unsignedIntegerValue];
        if (fileSize > 16 * 1024 * 1024) {
            NSError *readError = nil;
            NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingFromURL:self.URL error:&readError];
            if (fileHandle) {
                if (@available(iOS 13.0, *)) {
                    [fileHandle seekToOffset:0 error:&error];
                    binaryData = [fileHandle readDataUpToLength:fileSize error:&error];
                } else {
                    [fileHandle seekToFileOffset:0];
                    binaryData = [fileHandle readDataOfLength:fileSize];
                }
            } else {
                NSLog(@"%@", readError);
                binaryData = [NSData dataWithContentsOfURL:self.URL options:NSDataReadingMappedAlways error:&error];
            }
        } else {
            binaryData = [NSData dataWithContentsOfURL:self.URL options:NSDataReadingMappedAlways error:&error];
        }
    }
    return binaryData;
}

@end
