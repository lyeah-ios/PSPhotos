//
//  AVAudioSession+PSExtends.h
//  PSPhotos
//
//  Created by zisu on 2020/5/13.
//  Copyright © 2020 zisu. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AVAudioSession (PSExtends)

/**
 检查当前 AVAudioSession 的 category 配置是否可以播放音频。
 
 @return 当为 AVAudioSessionCategoryAmbient,AVAudioSessionCategorySoloAmbient, AVAudioSessionCategoryPlayback,
 AVAudioSessionCategoryPlayAndRecord中的一种时为 YES, 否则为 NO。
 */
+ (BOOL)ps_isPlayable;

/**
 检查当前 AVAudioSession 的 category 配置是否可以后台播放。
 
 @return 当为 AVAudioSessionCategoryPlayback,AVAudioSessionCategoryPlayAndRecord 中的一种时为 YES, 否则为 NO。
 */
+ (BOOL)ps_canPlayInBackground;

/// 将AVAudioSession的category设为AVAudioSessionCategoryPlayback，active == YES
+ (BOOL)ps_activeBackgroundAudioSession;

/// 将AVAudioSession的category设为AVAudioSessionCategoryAmbient，active == NO
+ (BOOL)ps_deactiveBackgroundAudioSession;

+ (BOOL)ps_setCategory:(AVAudioSessionCategory)category active:(BOOL)active;

+ (BOOL)ps_setCategoryOnly:(AVAudioSessionCategory)category;

@end

NS_ASSUME_NONNULL_END
