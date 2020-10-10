//
//  AVAudioSession+PSExtends.m
//  PSPhotos
//
//  Created by zisu on 2020/5/13.
//  Copyright © 2020 lyeah. All rights reserved.
//

#import "AVAudioSession+PSExtends.h"

@implementation AVAudioSession (PSExtends)

+ (BOOL)ps_isPlayable
{
    BOOL isPlayable = NO;
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    AVAudioSessionCategory category = audioSession.category;
    if (category == AVAudioSessionCategoryAmbient
        || category == AVAudioSessionCategorySoloAmbient
        || category == AVAudioSessionCategoryPlayback
        || category == AVAudioSessionCategoryPlayAndRecord) {
        isPlayable = YES;
    }
    return isPlayable;
}

+ (BOOL)ps_canPlayInBackground
{
    BOOL canPlayInBackground = NO;
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    AVAudioSessionCategory category = audioSession.category;
    if (category == AVAudioSessionCategoryPlayback
        || category == AVAudioSessionCategoryPlayAndRecord) {
        canPlayInBackground = YES;
    }
    return canPlayInBackground;
}

+ (BOOL)ps_activeBackgroundAudioSession
{
    return [self ps_setCategory:AVAudioSessionCategoryPlayback active:YES];
}

+ (BOOL)ps_deactiveBackgroundAudioSession
{
    return [self ps_setCategory:AVAudioSessionCategoryAmbient active:NO];
}

+ (BOOL)ps_setCategory:(AVAudioSessionCategory)category active:(BOOL)active
{
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *error = nil;
    if (![audioSession.category isEqualToString:category]) {
        if (![audioSession setCategory:category error:&error]) {
            LYHLog(@"setCategory:%@ error:%@", category, error);
            return NO;
        }
    }
    if (active) {
        if (![audioSession setActive:YES error:&error]) {
            LYHLog(@"setActive:YES error:%@", error);
            return NO;
        }
    } else {
        if (![audioSession setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&error]) {
            LYHLog(@"setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:%@", error);
            return NO;
        }
    }
    return YES;
}

+ (BOOL)ps_setCategoryOnly:(AVAudioSessionCategory)category
{
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *error = nil;
    if (![audioSession.category isEqualToString:category]) {
        if (![audioSession setCategory:category error:&error]) {
            LYHLog(@"setCategory:%@ error:%@", category, error);
            return NO;
        }
    }
    return YES;
}

@end
