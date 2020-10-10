//
//  MPNowPlayingInfoCenter+PSExtends.m
//  PSPhotos
//
//  Created by zisu on 2020/5/19.
//  Copyright © 2020 zisu. All rights reserved.
//

#import "MPNowPlayingInfoCenter+PSExtends.h"
#import "AVAudioSession+PSExtends.h"

/// Dummy class for category
@interface MPNowPlayingInfoCenter_PSExtends : NSObject @end
@implementation MPNowPlayingInfoCenter_PSExtends @end

@implementation MPNowPlayingInfoCenter (PSExtends)

#pragma mark - 控制中心播放器

+ (NSDictionary *)ps_nowPlayerInfo
{
    NSDictionary *info = [[MPNowPlayingInfoCenter defaultCenter] nowPlayingInfo];
    return info;
}

+ (void)ps_clearNowPlayerInfo
{
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:nil];
}

+ (void)ps_updateNowPlayerInfo:(NSDictionary *)info
{
    if (info && [info isKindOfClass:[NSDictionary class]]) {
        NSDictionary *nowInfo = [self ps_nowPlayerInfo];
        if (!nowInfo) {
            nowInfo = [NSDictionary dictionary];
        }
        NSMutableDictionary *mutableInfo = [nowInfo mutableCopy];
        [info enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            mutableInfo[key] = obj;
        }];
        [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:mutableInfo];
    } else {
        [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:nil];
    }
}

+ (void)ps_activeBackgroundPlayer
{
    [AVAudioSession ps_activeBackgroundAudioSession];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
}

+ (void)ps_deactiveBackgroundPlayer
{
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
}

@end
