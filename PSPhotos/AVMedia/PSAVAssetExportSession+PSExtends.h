//
//  PSAVAssetExportSession+PSExtends.h
//  PSPhotos
//
//  Created by zisu on 2019/7/26.
//  Copyright © 2019 zisu. All rights reserved.
//

#if __has_include(<PSPhotos/PSAVAssetExportSession.h>)
#import <PSPhotos/PSAVAssetExportSession.h>
#else
#import "PSAVAssetExportSession.h"
#endif

NS_ASSUME_NONNULL_BEGIN

/**
 __weak typeof(self)wself = self;
 PHVideoRequestOptions * requestOptions = [[PHVideoRequestOptions alloc] init];
 requestOptions.networkAccessAllowed = YES;
 requestOptions.deliveryMode = PHVideoRequestOptionsDeliveryModeHighQualityFormat;
 [requestOptions setProgressHandler:^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
 dispatch_async(dispatch_get_main_queue(), ^{
 PSLog(@"正在从iCloud同步...%f", progress);
 });
 }];
 [[PHImageManager defaultManager] requestAVAssetForVideo:model.asset options:requestOptions resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
 if (asset && [asset isKindOfClass:[AVURLAsset class]]) {
 PSLog(@"视频信息%@ --- %@", info, [asset metadata]);
 [PSAVAssetExportSession ps_exportAsset:asset onPrepare:^(PSAVAssetExportSession * _Nonnull session) {
 AVURLAsset * urlAsset = (AVURLAsset *)session.asset;
 NSNumber * size = nil;
 [urlAsset.URL getResourceValue:&size forKey:NSURLFileSizeKey error:nil];
 CGFloat fileSize = [size floatValue]/(1000.0f * 1000.0f);
 PSLog(@"视频导出前的大小%@", @(fileSize));
 NSInteger randomCode = arc4random() % 1000;
 NSTimeInterval interval = [[NSDate date] timeIntervalSince1970];
 NSString * uniqueRandomFileName = [NSString stringWithFormat:@"%f%@", interval, @(randomCode)];
 uniqueRandomFileName = [uniqueRandomFileName stringByReplacingOccurrencesOfString:@"." withString:@""];
 NSString *fileName = [NSString stringWithFormat:@"%@.mp4", uniqueRandomFileName];
 NSString *outputPath = [[PhotosService service].cacheDirectory stringByAppendingPathComponent:fileName];
 NSURL *outputURL = [NSURL fileURLWithPath:outputPath];
 session.outputURL = outputURL;
 session.outputFileType = AVFileTypeMPEG4;
 session.shouldOptimizeForNetworkUse = YES;
 CGSize videoSize = session.asset.ps_videoSize;
 CGFloat videoWidth = roundf(videoSize.width/16) * 16;
 CGFloat videoHeight = roundf(videoSize.height/16) * 16;
 CGFloat dimension = videoWidth * videoHeight;
 CGFloat rate = 5.0f;
 CGFloat bitRateKey = dimension * rate;
 NSDictionary *videoSettings = @{
 AVVideoCodecKey                 : AVVideoCodecH264,
 AVVideoWidthKey                 : @(videoWidth),
 AVVideoHeightKey                : @(videoHeight),
 AVVideoScalingModeKey           : AVVideoScalingModeResizeAspectFill,
 AVVideoCompressionPropertiesKey : @{
 AVVideoAverageBitRateKey : @(bitRateKey),
 AVVideoProfileLevelKey   : AVVideoProfileLevelH264BaselineAutoLevel,
 },
 };
 session.videoSettings = videoSettings;
 NSDictionary *audioSettings = @{
 AVFormatIDKey         : @(kAudioFormatMPEG4AAC),
 AVNumberOfChannelsKey : @2,
 AVSampleRateKey       : @44100,
 AVEncoderBitRateKey   : @128000,
 };
 session.audioSettings = audioSettings;
 [session setProcessBlock:^(PSAVAssetExportSession * _Nonnull session, float progress) {
 PSLog(@"视频导出进度%@", @(progress));
 }];
 } onSuccess:^(PSAVAssetExportSession * _Nonnull session, NSURL * _Nonnull outputURL) {
 AVURLAsset *outputAsset = [AVURLAsset assetWithURL:outputURL];
 NSNumber *size = nil;
 [outputAsset.URL getResourceValue:&size forKey:NSURLFileSizeKey error:nil];
 CGFloat fileSize = [size floatValue]/(1000.0f * 1000.0f);
 PSLog(@"视频导出后的大小%@", @(fileSize));
 [PhotosService saveVideoWithURL:outputURL toAlbum:@"视频转码" onCompletion:^(NSError * _Nullable error) {
 if (error) {
 PSLog(@"视频转码失败：%@", error);
 }
 }];
 } onFailure:^(PSAVAssetExportSession * _Nonnull session, NSError * _Nonnull error) {
 PSLog(@"视频导出失败%@", error);
 }];
 } else {
 PSLog(@"视频获取失败%@", info);
 }
 }];
 */
@interface PSAVAssetExportSession (PSExtends)

+ (void)ps_exportAsset:(AVAsset *)asset onPrepare:(void(^)(PSAVAssetExportSession *session))prepare onSuccess:(void(^_Nullable)(PSAVAssetExportSession *session, NSURL *outputURL))success onFailure:(void(^_Nullable)(PSAVAssetExportSession *session, NSError *error))failure;

@end

NS_ASSUME_NONNULL_END
