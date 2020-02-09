//
//  PHImageManager+PSExtends.m
//  PSPhotos
//
//  Created by zisu on 2020/1/8.
//  Copyright © 2020 zisu. All rights reserved.
//

#import "PHImageManager+PSExtends.h"

/// https://developer.apple.com/documentation/imageio/cgimagepropertyorientation?language=objc
UIImageOrientation UIImageOrientationForCGImagePropertyOrientation(CGImagePropertyOrientation cgOrientation) {
    UIImageOrientation orientation = UIImageOrientationUp;
    switch (cgOrientation) {
        case kCGImagePropertyOrientationUp: {orientation = UIImageOrientationUp;} break;
        case kCGImagePropertyOrientationDown: {orientation = UIImageOrientationDown;} break;
        case kCGImagePropertyOrientationLeft: {orientation = UIImageOrientationLeft;} break;
        case kCGImagePropertyOrientationRight: {orientation = UIImageOrientationRight;} break;
        case kCGImagePropertyOrientationUpMirrored: {orientation = UIImageOrientationUpMirrored;} break;
        case kCGImagePropertyOrientationDownMirrored: {orientation = UIImageOrientationDownMirrored;} break;
        case kCGImagePropertyOrientationLeftMirrored: {orientation = UIImageOrientationLeftMirrored;} break;
        case kCGImagePropertyOrientationRightMirrored: {orientation = UIImageOrientationRightMirrored;} break;
        default: {orientation = UIImageOrientationUp;} break;
    }
    return orientation;
}

@implementation PHImageManager (PSExtends)

- (PHImageRequestID)ps_requestImageDataForAsset:(PHAsset *)asset options:(PHImageRequestOptions *)options resultHandler:(void (^)(NSData * _Nullable, NSString * _Nullable, UIImageOrientation, NSDictionary * _Nullable))resultHandler
{
    if (@available(iOS 13.0, *)) {
        return [[PHImageManager defaultManager] requestImageDataAndOrientationForAsset:asset options:options resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, CGImagePropertyOrientation orientation, NSDictionary * _Nullable info) {
            if (resultHandler) {
                resultHandler(imageData, dataUTI, UIImageOrientationForCGImagePropertyOrientation(orientation), info);
            }
        }];
    } else {
        return [[PHImageManager defaultManager] requestImageDataForAsset:asset options:options resultHandler:resultHandler];
    }
}

@end
