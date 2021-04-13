//
//  AVPlayer+PSExtends.h
//  PSPhotos
//
//  Created by zisu on 2019/7/1.
//  Copyright © 2019 zisu. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AVPlayer (PSExtends)

- (BOOL)ps_isPlaying;

+ (BOOL)ps_isPictureInPictureSupported;

@end

NS_ASSUME_NONNULL_END
