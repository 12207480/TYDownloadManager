//
//  TYDownloadModel.h
//  TYDownloadManagerDemo
//
//  Created by tany on 16/6/1.
//  Copyright © 2016年 tany. All rights reserved.
//

#import <Foundation/Foundation.h>

// 下载状态
typedef NS_ENUM(NSUInteger, TYDownloadState) {
    TYDownloadStateNone,        // 未下载
    TYDownloadStateReadying,    // 等待下载
    TYDownloadStateRunning,     // 正在下载
    TYDownloadStateSuspended,   // 下载暂停
    TYDownloadStateCompleted,   // 下载完成
    TYDownloadStateFailed       // 下载失败
};

@class TYDownloadProgress;
@class TYDownloadModel;

// 进度更新block
typedef void (^TYDownloadProgressBlock)(TYDownloadProgress *progress);
// 状态更新block
typedef void (^TYDownloadStateBlock)(TYDownloadState state,NSString *filePath, NSError *error);

/**
 *  下载模型
 */
@interface TYDownloadModel : NSObject

// >>>>>>>>>>>>>>>>>>>>>>>>>>  download info
// 下载地址
@property (nonatomic, strong, readonly) NSString *downloadURL;
// 文件名 默认nil 则为下载URL中的文件名
@property (nonatomic, strong, readonly) NSString *fileName;
// 缓存文件目录 默认nil 则为manger缓存目录
@property (nonatomic, strong, readonly) NSString *downloadDirectory;

// >>>>>>>>>>>>>>>>>>>>>>>>>>  task info
// 下载状态
@property (nonatomic, assign, readonly) TYDownloadState state;
// 下载任务
@property (nonatomic, strong, readonly) NSURLSessionTask *task;
// 文件流
@property (nonatomic, strong, readonly) NSOutputStream *stream;
// 下载进度
@property (nonatomic, strong ,readonly) TYDownloadProgress *progress;
// 下载路径 如果设置了downloadDirectory，文件下载完成后会移动到这个目录，否则，在manager默认cache目录里
@property (nonatomic, strong, readonly) NSString *filePath;

// >>>>>>>>>>>>>>>>>>>>>>>>>>  download block
// 下载进度更新block
@property (nonatomic, copy) TYDownloadProgressBlock progressBlock;
// 下载状态更新block
@property (nonatomic, copy) TYDownloadStateBlock stateBlock;


- (instancetype)initWithURLString:(NSString *)URLString;
/**
 *  初始化方法
 *
 *  @param URLString 下载地址
 *  @param filePath  缓存地址 当为nil 默认缓存到cache
 */
- (instancetype)initWithURLString:(NSString *)URLString filePath:(NSString *)filePath;

@end

/**
 *  下载进度
 */
@interface TYDownloadProgress : NSObject

// 续传大小
@property (nonatomic, assign, readonly) int64_t resumeBytesWritten;
// 这次写入的数量
@property (nonatomic, assign, readonly) int64_t bytesWritten;
// 已下载的数量
@property (nonatomic, assign, readonly) int64_t totalBytesWritten;
// 文件的总大小
@property (nonatomic, assign, readonly) int64_t totalBytesExpectedToWrite;
// 下载进度
@property (nonatomic, assign, readonly) float progress;
// 下载速度
@property (nonatomic, assign, readonly) float speed;
// 下载剩余时间
@property (nonatomic, assign, readonly) int remainingTime;


@end
