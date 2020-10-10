//
//  PSAVAssetExportSession+PSExtends.m
//  PSPhotos
//
//  Created by zisu on 2019/7/26.
//  Copyright © 2019 zisu. All rights reserved.
//

#import "PSAVAssetExportSession+PSExtends.h"
#import "PSDefines.h"

/// Dummy class for category
@interface PSAVAssetExportSession_PSExtends : NSObject @end
@implementation PSAVAssetExportSession_PSExtends @end

@implementation PSAVAssetExportSession (PSExtends)

+ (void)ps_exportAsset:(AVAsset *)asset onPrepare:(nonnull void (^)(PSAVAssetExportSession * _Nonnull))prepare onSuccess:(void (^ _Nullable)(PSAVAssetExportSession * _Nonnull, NSURL * _Nonnull))success onFailure:(void (^ _Nullable)(PSAVAssetExportSession * _Nonnull, NSError * _Nonnull))failure
{
    PSAVAssetExportSession *exportSession = [PSAVAssetExportSession exportSessionWithAsset:asset];
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
            PSLog(@"视频准备导出...");
        } else if (status == AVAssetExportSessionStatusExporting) {
            PSLog(@"视频正在导出...");
        } else if (status == AVAssetExportSessionStatusCancelled) {
            PSLog(@"视频导出取消...");
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
