//
//  PSAVAssetExportSession.h
//  PSPhotos
//
//  Created by zisu on 2019/7/23.
//  Copyright © 2019 zisu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 @typedef    PSAudioBitRate
 @abstract   音频编码码率
 */
typedef NS_ENUM(NSUInteger, PSAudioBitRate) {
    PSAudioBitRate_32Kbps = 32000,          //32Kbps 音频码率
    PSAudioBitRate_64Kbps = 64000,          //64Kbps 音频码率
    PSAudioBitRate_96Kbps = 96000,          //96Kbps 音频码率
    PSAudioBitRate_128Kbps = 128000,        //128Kbps 音频码率
    PSAudioBitRate_192Kbps = 192000,        //192Kbps 音频码率
    PSAudioBitRate_256Kbps = 256000,        //256Kbps 音频码率
 };

@class PSAVAssetExportSession;

typedef void(^PSAVExportSessionProcessBlock)(PSAVAssetExportSession *session, float progress);
typedef CVPixelBufferRef _Nonnull (^PSAVExportSessionPixelBufferHandler)(PSAVAssetExportSession *session, CVPixelBufferRef pixelBuffer, CMTime presentationTime);

@protocol PSAVAssetExportSessionDelegate <NSObject>

@optional

/**
 @abstract 输出视频文件的视频数据，用来做滤镜处理
 @param pixelBuffer 视频帧
 @param presentationTime 视频帧的时间戳
 */
- (CVPixelBufferRef)exportSession:(PSAVAssetExportSession *)session didOutputPixelBuffer:(CVPixelBufferRef)pixelBuffer presentationTime:(CMTime)presentationTime;

@end

/**
 Based on the SDAVAssetExportSession:https://github.com/rs/SDAVAssetExportSession
 */
@interface PSAVAssetExportSession : NSObject

@property (nullable, nonatomic, weak) id<PSAVAssetExportSessionDelegate> delegate;

@property (nullable, nonatomic, copy) PSAVExportSessionProcessBlock processBlock;
@property (nullable, nonatomic, copy) PSAVExportSessionPixelBufferHandler pixelBufferHandler;

/**
 * The asset with which the export session was initialized.
 */
@property (nonatomic, strong, readonly) AVAsset *asset;

/**
 * The type of a time pitch algorithm.
 * The default value is nil. If not set, will use AVAudioTimePitchAlgorithmSpectral.
 */
@property (nullable, nonatomic, copy) AVAudioTimePitchAlgorithm audioTimePitchAlgorithm;

/**
 * Indicates whether video composition is enabled for export, and supplies the instructions for video composition.
 *
 * You can observe this property using key-value observing.
 */
@property (nonatomic, copy) AVVideoComposition *videoComposition;

/**
 * Indicates whether non-default audio mixing is enabled for export, and supplies the parameters for audio mixing.
 */
@property (nonatomic, copy) AVAudioMix *audioMix;

/**
 * The type of file to be written by the session.
 *
 * The value is a UTI string corresponding to the file type to use when writing the asset.
 * For a list of constants specifying UTIs for standard file types, see `AV Foundation Constants Reference`.
 *
 * You can observe this property using key-value observing.
 */
@property (nonatomic, copy) AVFileType outputFileType;

/**
 * The URL of the export session’s output.
 *
 * You can observe this property using key-value observing.
 */
@property (nonatomic, copy) NSURL *outputURL;

/**
 * The settings used for input video track.
 *
 * The dictionary’s keys are from <CoreVideo/CVPixelBuffer.h>.
 */
@property (nonatomic, copy) NSDictionary *videoInputSettings;

/**
 * The settings used for encoding the video track.
 *
 * A value of nil specifies that appended output should not be re-encoded.
 * The dictionary’s keys are from <AVFoundation/AVVideoSettings.h>.
 */
@property (nonatomic, copy) NSDictionary *videoSettings;

/**
 * The settings used for encoding the audio track.
 *
 * A value of nil specifies that appended output should not be re-encoded.
 * The dictionary’s keys are from <CoreVideo/CVPixelBuffer.h>.
 */
@property (nonatomic, copy) NSDictionary *audioSettings;

/**
 * The time range to be exported from the source.
 *
 * The default time range of an export session is `kCMTimeZero` to `kCMTimePositiveInfinity`,
 * meaning that (modulo a possible limit on file length) the full duration of the asset will be exported.
 *
 * You can observe this property using key-value observing.
 *
 */
@property (nonatomic, assign) CMTimeRange timeRange;

/**
 * Indicates whether the movie should be optimized for network use.
 *
 * You can observe this property using key-value observing.
 */
@property (nonatomic, assign) BOOL shouldOptimizeForNetworkUse;

/**
 * The metadata to be written to the output file by the export session.
 */
@property (nonatomic, copy) NSArray *metadata;

/**
 * Describes the error that occurred if the export status is `AVAssetExportSessionStatusFailed`
 * or `AVAssetExportSessionStatusCancelled`.
 *
 * If there is no error to report, the value of this property is nil.
 */
@property (nonatomic, strong, readonly) NSError *error;

/**
 * The progress of the export on a scale from 0 to 1.
 *
 *
 * A value of 0 means the export has not yet begun, 1 means the export is complete.
 *
 * Unlike Apple provided `AVAssetExportSession`, this property can be observed using key-value observing.
 */
@property (nonatomic, assign, readonly) float progress;

/**
 * The status of the export session.
 *
 * For possible values, see “AVAssetExportSessionStatus.”
 *
 * You can observe this property using key-value observing. (TODO)
 */
@property (nonatomic, assign, readonly) AVAssetExportSessionStatus status;

/**
 * Returns an asset export session configured with a specified asset.
 *
 * @param asset The asset you want to export
 * @return An asset export session initialized to export `asset`.
 */
+ (instancetype)exportSessionWithAsset:(AVAsset *)asset;

/**
 * Initializes an asset export session with a specified asset.
 *
 * @param asset The asset you want to export
 * @return An asset export session initialized to export `asset`.
 */
- (instancetype)initWithAsset:(AVAsset *)asset;

/**
 * Starts the asynchronous execution of an export session.
 *
 * This method starts an asynchronous export operation and returns immediately. status signals the terminal
 * state of the export session, and if a failure occurs, error describes the problem.
 *
 * If internal preparation for export fails, handler is invoked synchronously. The handler may also be called
 * asynchronously, after the method returns, in the following cases:
 *
 * 1. If a failure occurs during the export, including failures of loading, re-encoding, or writing media data to the output.
 * 2. If cancelExport is invoked.
 * 3. After the export session succeeds, having completely written its output to the outputURL.
 *
 * @param handler A block that is invoked when writing is complete or in the event of writing failure.
 */
- (void)exportAsynchronouslyWithCompletionHandler:(void (^)(void))handler;

/**
 * Cancels the execution of an export session.
 *
 * You can invoke this method when the export is running.
 */
- (void)cancelExport;

@end

NS_ASSUME_NONNULL_END
