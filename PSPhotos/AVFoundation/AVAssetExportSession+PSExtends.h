//
//  AVAssetExportSession+PSExtends.h
//  PSPhotos
//
//  Created by zisu on 2019/7/1.
//  Copyright © 2019 zisu. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AVAssetExportSession (PSExtends)

+ (void)ps_exportAsset:(AVAsset *)asset presetName:(NSString *)presetName onPrepare:(void(^)(AVAssetExportSession *session))prepare onSuccess:(void(^_Nullable)(AVAssetExportSession *session, NSURL *outputURL))success onFailure:(void(^_Nullable)(AVAssetExportSession *_Nullable session, NSError *error))failure;

@end

NS_ASSUME_NONNULL_END
