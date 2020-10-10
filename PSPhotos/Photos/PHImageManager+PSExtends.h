//
//  PHImageManager+PSExtends.h
//  PSPhotos
//
//  Created by zisu on 2020/1/8.
//  Copyright © 2020 zisu. All rights reserved.
//

#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@interface PHImageManager (PSExtends)

- (PHImageRequestID)ps_requestImageDataForAsset:(PHAsset *)asset options:(nullable PHImageRequestOptions *)options resultHandler:(void (^)(NSData *_Nullable imageData, NSString *_Nullable dataUTI, UIImageOrientation orientation, NSDictionary *_Nullable info))resultHandler;

@end

NS_ASSUME_NONNULL_END
