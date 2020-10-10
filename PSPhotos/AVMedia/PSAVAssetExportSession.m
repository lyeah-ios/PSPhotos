//
//  PSAVAssetExportSession.m
//  PSPhotos
//
//  Created by zisu on 2019/7/23.
//  Copyright © 2019 zisu. All rights reserved.
//

#import "PSAVAssetExportSession.h"

@interface PSAVAssetExportSession ()

@property (nonatomic, assign, readwrite) float progress;

@property (nonatomic, strong) AVAssetReader *reader;
@property (nonatomic, strong) AVAssetReaderVideoCompositionOutput *videoOutput;
@property (nonatomic, strong) AVAssetReaderAudioMixOutput *audioOutput;
@property (nonatomic, strong) AVAssetWriter *writer;
@property (nonatomic, strong) AVAssetWriterInput *videoInput;
@property (nonatomic, strong) AVAssetWriterInputPixelBufferAdaptor *videoPixelBufferAdaptor;
@property (nonatomic, strong) AVAssetWriterInput *audioInput;

@property (nonatomic, strong) dispatch_queue_t inputQueue;

@property (nonatomic, strong) void (^completionHandler)(void);

@end

@implementation PSAVAssetExportSession
{
    NSError *_error;
    NSTimeInterval duration;
}

+ (instancetype)exportSessionWithAsset:(AVAsset *)asset
{
    return [[PSAVAssetExportSession alloc] initWithAsset:asset];
}

- (instancetype)initWithAsset:(AVAsset *)asset
{
    self = [super init];
    if (self) {
        _asset = asset;
        _timeRange = CMTimeRangeMake(kCMTimeZero, kCMTimePositiveInfinity);
    }
    return self;
}

- (void)exportAsynchronouslyWithCompletionHandler:(void (^)(void))handler
{
    NSParameterAssert(handler != nil);
    [self cancelExport];
    self.completionHandler = handler;
    
    if (!self.outputURL) {
        NSString *errorMessage = @"Output URL not set!";
        _error = [NSError errorWithDomain:AVFoundationErrorDomain code:AVErrorExportFailed userInfo:@{
            NSLocalizedDescriptionKey : errorMessage,
            NSLocalizedFailureReasonErrorKey : errorMessage,
        }];
        handler();
        return;
    }
    
    NSError *readerError = nil;
    self.reader = [AVAssetReader assetReaderWithAsset:self.asset error:&readerError];
    if (readerError) {
        _error = readerError;
        handler();
        return;
    }
    
    NSError *writerError = nil;
    self.writer = [AVAssetWriter assetWriterWithURL:self.outputURL fileType:self.outputFileType error:&writerError];
    if (writerError) {
        _error = writerError;
        handler();
        return;
    }
    
    self.reader.timeRange = self.timeRange;
    self.writer.shouldOptimizeForNetworkUse = self.shouldOptimizeForNetworkUse;
    self.writer.metadata = self.metadata;
    
    NSArray *videoTracks = [self.asset tracksWithMediaType:AVMediaTypeVideo];
    
    
    if (CMTIME_IS_VALID(self.timeRange.duration) && !CMTIME_IS_POSITIVE_INFINITY(self.timeRange.duration)) {
        duration = CMTimeGetSeconds(self.timeRange.duration);
    } else {
        duration = CMTimeGetSeconds(self.asset.duration);
    }
    //
    // Video output
    //
    if (videoTracks.count > 0) {
        self.videoOutput = [AVAssetReaderVideoCompositionOutput assetReaderVideoCompositionOutputWithVideoTracks:videoTracks videoSettings:self.videoInputSettings];
        self.videoOutput.alwaysCopiesSampleData = NO;
        if (self.videoComposition) {
            self.videoOutput.videoComposition = self.videoComposition;
        } else {
            self.videoOutput.videoComposition = [self buildDefaultVideoComposition];
        }
        if ([self.reader canAddOutput:self.videoOutput]) {
            [self.reader addOutput:self.videoOutput];
        }
        
        //
        // Video input
        //
        self.videoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:self.videoSettings];
        self.videoInput.expectsMediaDataInRealTime = NO;
        if ([self.writer canAddInput:self.videoInput]) {
            [self.writer addInput:self.videoInput];
        }
        if (self.pixelBufferHandler || (self.delegate && [self.delegate respondsToSelector:@selector(exportSession:didOutputPixelBuffer:presentationTime:)])) {
            // If a pixel format was specified in videoInputSettings, use the same pixel format for the render buffers
            // In practice, kCVPixelFormatType_32BGRA always seems to be the fastest (even when transcoding between YpCbCr formats, such as H.264)
            // This is despite the fact that the YpCbCr pixel buffers are less than half the size (12 bits/pixel vs. 32 bits/pixel)
            id pixelFormat = self.videoInputSettings[(__bridge NSString *)kCVPixelBufferPixelFormatTypeKey];
            if (!pixelFormat) {
                pixelFormat = @(kCVPixelFormatType_32BGRA);
            }
            NSDictionary *pixelBufferAttributes = @{
                (__bridge NSString *)kCVPixelBufferPixelFormatTypeKey       : pixelFormat,
                (__bridge NSString *)kCVPixelBufferWidthKey                 : @(self.videoOutput.videoComposition.renderSize.width),
                (__bridge NSString *)kCVPixelBufferHeightKey                : @(self.videoOutput.videoComposition.renderSize.height),
                @"IOSurfaceOpenGLESTextureCompatibility"                    : @YES,
                @"IOSurfaceOpenGLESFBOCompatibility"                        : @YES,
            };
            self.videoPixelBufferAdaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:self.videoInput sourcePixelBufferAttributes:pixelBufferAttributes];
        }
    }
    
    //
    //Audio output
    //
    NSArray *audioTracks = [self.asset tracksWithMediaType:AVMediaTypeAudio];
    if (audioTracks.count > 0) {
        self.audioOutput = [AVAssetReaderAudioMixOutput assetReaderAudioMixOutputWithAudioTracks:audioTracks audioSettings:nil];
        AVAudioTimePitchAlgorithm audioTimePitchAlgorithm = AVAudioTimePitchAlgorithmSpectral;
        if (self.audioTimePitchAlgorithm) {
            audioTimePitchAlgorithm = self.audioTimePitchAlgorithm;
        }
        self.audioOutput.audioTimePitchAlgorithm = audioTimePitchAlgorithm;
        self.audioOutput.alwaysCopiesSampleData = NO;
        self.audioOutput.audioMix = self.audioMix;
        if ([self.reader canAddOutput:self.audioOutput]) {
            [self.reader addOutput:self.audioOutput];
        }
    } else {
        // Just in case this gets reused
        self.audioOutput = nil;
    }
    
    //
    // Audio input
    //
    if (self.audioOutput) {
        self.audioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:self.audioSettings];
        self.audioInput.expectsMediaDataInRealTime = NO;
        if ([self.writer canAddInput:self.audioInput]) {
            [self.writer addInput:self.audioInput];
        }
    }
    
    [self.writer startWriting];
    [self.reader startReading];
    [self.writer startSessionAtSourceTime:self.timeRange.start];
    
    __block BOOL videoCompleted = NO;
    __block BOOL audioCompleted = NO;
    __weak typeof(self) wself = self;
    self.inputQueue = dispatch_queue_create("VideoEncoderInputQueue", DISPATCH_QUEUE_SERIAL);
    if (videoTracks.count > 0) {
        [self.videoInput requestMediaDataWhenReadyOnQueue:self.inputQueue usingBlock:^{
            if (![wself encodeReadySamplesFromOutput:wself.videoOutput toInput:wself.videoInput]) {
                @synchronized(wself) {
                    videoCompleted = YES;
                    if (audioCompleted) {
                        [wself finish];
                    }
                }
            }
        }];
    } else {
        videoCompleted = YES;
    }
    
    if (!self.audioOutput) {
        audioCompleted = YES;
    } else {
        [self.audioInput requestMediaDataWhenReadyOnQueue:self.inputQueue usingBlock:^{
            if (![wself encodeReadySamplesFromOutput:wself.audioOutput toInput:wself.audioInput]) {
                @synchronized(wself) {
                    audioCompleted = YES;
                    if (videoCompleted) {
                        [wself finish];
                    }
                }
            }
        }];
    }
}

- (BOOL)encodeReadySamplesFromOutput:(AVAssetReaderOutput *)output toInput:(AVAssetWriterInput *)input
{
    while (input.isReadyForMoreMediaData) {
        @autoreleasepool {
            if (self.progress > 0.99f) {
                //copyNextSampleBuffer在遇到某些特殊视频会挂起，目前暂时没有解决方案，暂时舍弃最后一部分
                [input markAsFinished];
                return NO;
            }
            CMSampleBufferRef sampleBuffer = [output copyNextSampleBuffer];
            if (sampleBuffer) {
                BOOL handled = NO;
                BOOL error = NO;
                
                if (self.reader.status != AVAssetReaderStatusReading || self.writer.status != AVAssetWriterStatusWriting) {
                    handled = YES;
                    error = YES;
                }
                
                if (!handled && self.videoOutput == output) {
                    // update the video progress
                    CMTime presentationTimeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
                    presentationTimeStamp = CMTimeSubtract(presentationTimeStamp, self.timeRange.start);
                    self.progress = duration == 0 ? 1 : CMTimeGetSeconds(presentationTimeStamp) / duration;
                    
                    if (self.processBlock) {
                        self.processBlock(self, self.progress);
                    }
                    
                    if (self.pixelBufferHandler) {
                        CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
                        pixelBuffer = self.pixelBufferHandler(self, pixelBuffer, presentationTimeStamp);
                        if (![self.videoPixelBufferAdaptor appendPixelBuffer:pixelBuffer withPresentationTime:presentationTimeStamp]) {
                            error = YES;
                        }
                        handled = YES;
                    } else if (self.delegate && [self.delegate respondsToSelector:@selector(exportSession:didOutputPixelBuffer:presentationTime:)]) {
                        CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
                        pixelBuffer = [self.delegate exportSession:self didOutputPixelBuffer:pixelBuffer presentationTime:presentationTimeStamp];
                        if (![self.videoPixelBufferAdaptor appendPixelBuffer:pixelBuffer withPresentationTime:presentationTimeStamp]) {
                            error = YES;
                        }
                        handled = YES;
                    }
                }
                if (!handled && ![input appendSampleBuffer:sampleBuffer]) {
                    error = YES;
                }
                CFRelease(sampleBuffer);
                
                if (error) {
                    return NO;
                }
            } else {
                [input markAsFinished];
                return NO;
            }
        }
    }
    return YES;
}

- (AVMutableVideoComposition *)buildDefaultVideoComposition
{
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    AVAssetTrack *videoTrack = [[self.asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    
    // get the frame rate from videoSettings, if not set then try to get it from the video track,
    // if not set (mainly when asset is AVComposition) then use the default frame rate of 30
    float trackFrameRate = 0;
    if (self.videoSettings) {
        NSDictionary *videoCompressionProperties = [self.videoSettings objectForKey:AVVideoCompressionPropertiesKey];
        if (videoCompressionProperties) {
            NSNumber *frameRate = [videoCompressionProperties objectForKey:AVVideoAverageNonDroppableFrameRateKey];
            if (frameRate) {
                trackFrameRate = [frameRate floatValue];
            } else {
                trackFrameRate = [videoTrack nominalFrameRate];
            }
        }
    } else {
        trackFrameRate = [videoTrack nominalFrameRate];
    }
    
    if (trackFrameRate == 0) {
        trackFrameRate = 30;
    }
    
    videoComposition.frameDuration = CMTimeMake(1, trackFrameRate);
    CGSize targetSize = CGSizeMake([self.videoSettings[AVVideoWidthKey] floatValue], [self.videoSettings[AVVideoHeightKey] floatValue]);
    CGSize naturalSize = [videoTrack naturalSize];
    CGAffineTransform transform = videoTrack.preferredTransform;
    
    // https://github.com/rs/SDAVAssetExportSession/issues/79
    CGRect rect = {{0, 0}, naturalSize};
    CGRect transformedRect = CGRectApplyAffineTransform(rect, transform);
    // transformedRect should have origin at 0 if correct; otherwise add offset to correct it
    transform.tx -= transformedRect.origin.x;
    transform.ty -= transformedRect.origin.y;
    
    // Workaround radar 31928389, see https://github.com/rs/SDAVAssetExportSession/pull/70 for more info
    if (transform.ty == -560) {
        transform.ty = 0;
    }
    
    if (transform.tx == -560) {
        transform.tx = 0;
    }
    
    CGFloat videoAngleInDegree  = atan2(transform.b, transform.a) * 180 / M_PI;
    if (videoAngleInDegree == 90 || videoAngleInDegree == -90) {
        CGFloat width = naturalSize.width;
        naturalSize.width = naturalSize.height;
        naturalSize.height = width;
    }
    
    //Fix issues related to https://github.com/rs/SDAVAssetExportSession/issues/91
    if (videoAngleInDegree == 90 && transform.tx == 0) {
        transform.tx = naturalSize.width;
    }
    
    if (videoAngleInDegree == -90 && transform.ty == 0) {
        transform.ty = naturalSize.height;
    }
    
    videoComposition.renderSize = naturalSize;
    // center inside
    {
        float ratio;
        float xratio = targetSize.width / naturalSize.width;
        float yratio = targetSize.height / naturalSize.height;
        ratio = MIN(xratio, yratio);
        
        float postWidth = naturalSize.width * ratio;
        float postHeight = naturalSize.height * ratio;
        float transx = (targetSize.width - postWidth) / 2;
        float transy = (targetSize.height - postHeight) / 2;
        
        CGAffineTransform matrix = CGAffineTransformMakeTranslation(transx / xratio, transy / yratio);
        matrix = CGAffineTransformScale(matrix, ratio / xratio, ratio / yratio);
        transform = CGAffineTransformConcat(transform, matrix);
    }
    
    // Make a "pass through video track" video composition.
    AVMutableVideoCompositionInstruction *passThroughInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    passThroughInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, self.asset.duration);
    
    AVMutableVideoCompositionLayerInstruction *passThroughLayer = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    
    [passThroughLayer setTransform:transform atTime:kCMTimeZero];
    
    passThroughInstruction.layerInstructions = @[passThroughLayer];
    videoComposition.instructions = @[passThroughInstruction];
    
    return videoComposition;
}

- (void)finish
{
    // Synchronized block to ensure we never cancel the writer before calling finishWritingWithCompletionHandler
    if (self.reader.status == AVAssetReaderStatusCancelled || self.writer.status == AVAssetWriterStatusCancelled) {
        return;
    }
    
    if (self.writer.status == AVAssetWriterStatusFailed) {
        [self complete];
    } else if (self.reader.status == AVAssetReaderStatusFailed) {
        [self.writer cancelWriting];
        [self complete];
    } else {
        [self.writer finishWritingWithCompletionHandler:^{
            [self complete];
        }];
    }
}

- (void)complete
{
    if (self.writer.status == AVAssetWriterStatusFailed || self.writer.status == AVAssetWriterStatusCancelled) {
        [[NSFileManager defaultManager] removeItemAtURL:self.outputURL error:nil];
    }
    
    if (self.completionHandler) {
        self.completionHandler();
        self.completionHandler = nil;
    }
}

- (NSError *)error
{
    if (_error) {
        return _error;
    } else {
        return self.writer.error ? self.writer.error : self.reader.error;
    }
}

- (AVAssetExportSessionStatus)status
{
    AVAssetExportSessionStatus status = AVAssetExportSessionStatusUnknown;
    switch (self.writer.status) {
        case AVAssetWriterStatusUnknown:
        {
            status = AVAssetExportSessionStatusUnknown;
        }
            break;
        case AVAssetWriterStatusWriting:
        {
            status = AVAssetExportSessionStatusExporting;
        }
            break;
        case AVAssetWriterStatusFailed:
        {
            status = AVAssetExportSessionStatusFailed;
        }
            break;
        case AVAssetWriterStatusCompleted:
        {
            status = AVAssetExportSessionStatusCompleted;
        }
            break;
        case AVAssetWriterStatusCancelled:
        {
            status = AVAssetExportSessionStatusCancelled;
        }
            break;
            
        default:
        {
            status = AVAssetExportSessionStatusUnknown;
        }
            break;
    }
    return status;
}

- (void)cancelExport
{
    if (self.inputQueue) {
        dispatch_async(self.inputQueue, ^{
            [self.writer cancelWriting];
            [self.reader cancelReading];
            [self complete];
            [self reset];
        });
    }
}

- (void)reset
{
    _error = nil;
    self.progress = 0;
    self.reader = nil;
    self.videoOutput = nil;
    self.audioOutput = nil;
    self.writer = nil;
    self.videoInput = nil;
    self.videoPixelBufferAdaptor = nil;
    self.audioInput = nil;
    self.inputQueue = nil;
    self.completionHandler = nil;
}

@end
