//
//  AVPlayer+PSExtends.m
//  PSPhotos
//
//  Created by zisu on 2019/7/1.
//  Copyright © 2019 zisu. All rights reserved.
//

#import "AVPlayer+PSExtends.h"
#import <AVKit/AVKit.h>

/// Dummy class for category
@interface AVPlayer_PSExtends : NSObject @end
@implementation AVPlayer_PSExtends @end

@implementation AVPlayer (PSExtends)

- (BOOL)ps_isPlaying
{
    BOOL result = NO;
    if (@available(iOS 10.0, *)) {
        result = self.timeControlStatus == AVPlayerTimeControlStatusPlaying;
    } else {
        result = self.rate != 0;
    }
    return result;
}

+ (BOOL)ps_isPictureInPictureSupported
{
    BOOL result = NO;
    if (@available(iOS 11.0, *)) {
        result = [AVPictureInPictureController isPictureInPictureSupported];
    }
    return result;
}

@end
