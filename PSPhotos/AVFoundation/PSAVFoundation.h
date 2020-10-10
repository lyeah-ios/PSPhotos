//
//  PSAVFoundation.h
//  PSPhotos
//
//  Created by zisu on 2020/2/9.
//  Copyright © 2020 zisu. All rights reserved.
//

#ifndef PSAVFoundation_h
#define PSAVFoundation_h

#if __has_include(<PSPhotos/PSAVFoundation.h>)

#import <PSPhotos/AVAsset+PSExtends.h>
#import <PSPhotos/AVAsset+PSExport.h>
#import <PSPhotos/AVPlayer+PSExtends.h>
#import <PSPhotos/AVAudioSession+PSExtends.h>
#import <PSPhotos/AVAssetExportSession+PSExtends.h>
#import <PSPhotos/PSAVAssetExportSession+PSExtends.h>
#import <PSPhotos/MPNowPlayingInfoCenter+PSExtends.h>

#else

#import "AVAsset+PSExtends.h"
#import "AVAsset+PSExport.h"
#import "AVPlayer+PSExtends.h"
#import "AVAudioSession+PSExtends.h"
#import "AVAssetExportSession+PSExtends.h"
#import "PSAVAssetExportSession+PSExtends.h"
#import "MPNowPlayingInfoCenter+PSExtends.h"

#endif

#endif /* PSPhotos_h */
