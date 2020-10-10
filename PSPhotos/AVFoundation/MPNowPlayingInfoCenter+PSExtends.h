//
//  MPNowPlayingInfoCenter+PSExtends.h
//  PSPhotos
//
//  Created by zisu on 2020/5/19.
//  Copyright © 2020 lyeah. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>

NS_ASSUME_NONNULL_BEGIN

@interface MPNowPlayingInfoCenter (PSExtends)

/// 控制中心播放器
+ (nullable NSDictionary *)ps_nowPlayerInfo;
+ (void)ps_clearNowPlayerInfo;
+ (void)ps_updateNowPlayerInfo:(NSDictionary *)info;
+ (void)ps_activeBackgroundPlayer;
+ (void)ps_deactiveBackgroundPlayer;

@end

NS_ASSUME_NONNULL_END
