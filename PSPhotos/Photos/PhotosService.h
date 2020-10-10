//
//  PhotosService.h
//  PSPhotos
//
//  Created by zisu on 2018/11/22.
//  Copyright © 2018年 zisu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN NSString * const PSErrorDomain;
FOUNDATION_EXTERN NSString * const PSBundleNameKey;
FOUNDATION_EXTERN NSString * const PSBundleDisplayNameKey;
FOUNDATION_EXPORT NSString * const PSPhotoLibraryUsageDescriptionKey;

@interface PhotosService : NSObject

/// 临时文件存储目录，不设置默认存在NSTemporaryDirectory()
@property (nonatomic, copy) NSString *cacheDirectory;

+ (PhotosService *)service;

/// 随机生成的文件名，尽量保证不重复，由当前时间戳+随机数组合而成
+ (NSString *)uniqueRandomFileName;

/// 请求相册权限
+ (void)requestAuthorization:(void(^)(PHAuthorizationStatus status))handler;

/// 清除内部缓存
+ (void)clearCaches;

@end

@interface PhotosService (Photo)

/// 保存图片到指定相册，如果指定相册创建失败，则直接保存到系统相册
/// @param image 图片
/// @param albumName 相册名称，不传则只保存到相机胶卷
/// @param completion 完成
+ (void)saveImage:(UIImage *)image toAlbum:(NSString *__nullable)albumName onCompletion:(void (^__nullable)(NSError *__nullable error))completion;

/// 保存图片到指定相册，如果指定相册创建失败，则直接保存到系统相册
/// @param imageData 图片元数据
/// @param isGIF 是否为GIF
/// @param albumName 相册名称，不传则只保存到相机胶卷
/// @param completion 完成
+ (void)saveImageData:(NSData *)imageData isGIF:(BOOL)isGIF toAlbum:(NSString *__nullable)albumName onCompletion:(void (^__nullable)(NSError *__nullable error))completion;

/// 保存图片到指定相册，如果指定相册创建失败，则直接保存到系统相册
/// @param fileURL 图片的沙盒路径
/// @param albumName 相册名称，不传则只保存到相机胶卷
/// @param completion 完成
+ (void)saveImageWithURL:(NSURL *)fileURL toAlbum:(NSString *__nullable)albumName onCompletion:(void (^__nullable)(NSError *__nullable error))completion;

@end

@interface PhotosService (Video)

/// 保存视频到指定相册，如果指定相册创建失败，则直接保存到系统相册
/// @param fileURL 视频的沙盒路径
/// @param albumName 相册名称，不传则只保存到相机胶卷
/// @param completion 完成
+ (void)saveVideoWithURL:(NSURL *)fileURL toAlbum:(NSString *__nullable)albumName onCompletion:(void (^__nullable)(NSError *__nullable error))completion;

/**
 保存视频到指定相册，如果指定相册创建失败，则直接保存到系统相册

 @param fileURL 视频的沙盒路径
 @param shouldMoveFile 移动视频而非拷贝
 @param albumName 相册名称，不传则只保存到相机胶卷
 @param completion 完成
*/
+ (void)saveVideoWithURL:(NSURL *)fileURL shouldMoveFile:(BOOL)shouldMoveFile toAlbum:(NSString *__nullable)albumName onCompletion:(void (^__nullable)(NSError *__nullable error))completion;

@end

@interface PhotosService (System)

+ (BOOL)ps_isAlbumAuthorized;
+ (BOOL)ps_isAlbumLimited;
+ (PHAuthorizationStatus)ps_albumAuthorizationStatus;
+ (BOOL)ps_isCameraAuthorized;
+ (AVAuthorizationStatus)ps_cameraAuthorizationStatus;

/// info.plist
+ (NSDictionary *)ps_infoDictionary;

/// 去手机设置
+ (void)ps_openPhoneSettings;

@end

@interface NSError (PhotosService)

+ (NSError *)ps_errorWithMessage:(NSString *)errorMessage code:(NSInteger)code;

@end

NS_ASSUME_NONNULL_END
