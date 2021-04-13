//
//  AVAssetImageGenerator+PSExtends.m
//  PSPhotos
//
//  Created by zisu on 2020/12/31.
//  Copyright © 2020 zisu. All rights reserved.
//

#import "AVAssetImageGenerator+PSExtends.h"
#import "PSDefines.h"

/// Dummy class for category
@interface AVAssetImageGenerator_PSExtends : NSObject @end
@implementation AVAssetImageGenerator_PSExtends @end

@implementation AVAssetImageGenerator (PSExtends)

+ (void)ps_generatorImagesWithAsset:(AVAsset *)asset requestedTimes:(NSArray<NSValue *> *)requestedTimes onPrepare:(void (^)(AVAssetImageGenerator * _Nonnull))prepare onSuccess:(void (^)(AVAssetImageGenerator * _Nonnull, UIImage * _Nonnull))success onFailure:(void (^)(AVAssetImageGenerator * _Nullable, NSError * _Nonnull))failure
{
    AVAssetImageGenerator *imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
    if (prepare) {
        prepare(imageGenerator);
    }
    [imageGenerator generateCGImagesAsynchronouslyForTimes:requestedTimes completionHandler:^(CMTime requestedTime, CGImageRef  _Nullable image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError * _Nullable error) {
        switch (result) {
            case AVAssetImageGeneratorSucceeded:
            {
                UIImage *resultImage = [UIImage imageWithCGImage:image];
                if (success) {
                    success(imageGenerator, resultImage);
                }
            }
                break;
            case AVAssetImageGeneratorFailed:
            {
                if (failure) {
                    failure(imageGenerator, error);
                }
            }
                break;
            case AVAssetImageGeneratorCancelled:
            {
                PSLog(@"视频生成图片取消...");
            }
                break;
                
            default:
                break;
        }
    }];
}

@end
