//
//  AVAssetExportSession+PSExtends.m
//  PSPhotos
//
//  Created by zisu on 2019/7/1.
//  Copyright © 2019 zisu. All rights reserved.
//

#import "AVAssetExportSession+PSExtends.h"
#import "PSPhotosDefines.h"

@implementation AVAssetExportSession (PSExtends)

+ (void)ps_exportAsset:(AVAsset *)asset presetName:(NSString *)presetName onPrepare:(void (^)(AVAssetExportSession * _Nonnull))prepare onSuccess:(void (^)(AVAssetExportSession * _Nonnull, NSURL * _Nonnull))success onFailure:(void (^)(AVAssetExportSession * _Nullable, NSError * _Nonnull))failure
{
    AVAssetExportSession *exportSession = [AVAssetExportSession exportSessionWithAsset:asset presetName:presetName];
    if (prepare) {
        prepare(exportSession);
    }
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        AVAssetExportSessionStatus status = exportSession.status;
        if (status == AVAssetExportSessionStatusCompleted) {
            if (success) {
                success(exportSession, exportSession.outputURL);
            }
        } else if (status == AVAssetExportSessionStatusWaiting) {
            NSLog(@"视频准备导出...");
        } else if (status == AVAssetExportSessionStatusExporting) {
            NSLog(@"视频正在导出...");
        } else if (status == AVAssetExportSessionStatusCancelled) {
            NSLog(@"视频导出取消...");
        } else {
            if (failure) {
                NSError *error = exportSession.error;
                if (!error) {
                    NSString *errorMessage = @"由于未知原因暂不支持导出该视频";
                    error = [self ps_exportErrorWithMessage:errorMessage errorCode:PSErrorCodeExportFailed];
                }
                failure(exportSession, error);
            }
        }
    }];
}

+ (NSError *)ps_exportErrorWithMessage:(NSString *)errorMessage errorCode:(NSInteger)errorCode
{
    NSError *error = [NSError errorWithDomain:AVFoundationErrorDomain code:errorCode userInfo:@{
                                                                                                NSLocalizedDescriptionKey : errorMessage,
                                                                                                NSLocalizedFailureReasonErrorKey : errorMessage,
                                                                                                }];
    return error;
}

@end
