//
//  AVAssetImageGenerator+PSExtends.h
//  PSPhotos
//
//  Created by zisu on 2020/12/31.
//  Copyright © 2020 zisu. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AVAssetImageGenerator (PSExtends)

/// 生成指定的一系列时间的截图
/// @param asset 视频
/// @param requestedTimes 时间数组
/// @param prepare 准备
/// @param success 成功，会多次回调，每次一张图
/// @param failure 失败
+ (void)ps_generatorImagesWithAsset:(AVAsset *)asset requestedTimes:(NSArray<NSValue *> *)requestedTimes onPrepare:(void(^)(AVAssetImageGenerator *generator))prepare onSuccess:(void(^_Nullable)(AVAssetImageGenerator *generator, UIImage *resultImage))success onFailure:(void(^_Nullable)(AVAssetImageGenerator *_Nullable generator, NSError *error))failure;

@end

NS_ASSUME_NONNULL_END
