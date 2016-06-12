//
//  TYDownLoadDataManager.h
//  TYDownloadManagerDemo
//
//  Created by tany on 16/6/12.
//  Copyright © 2016年 tany. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TYDownLoadModel.h"

/**
 *  下载管理类
 */
@interface TYDownLoadDataManager : NSObject <NSURLSessionDelegate>

// 最大下载数
@property (nonatomic, assign) NSInteger maxDownloadCount;

// 单例
+ (TYDownLoadDataManager *)manager;

// 开始下载
- (TYDownLoadModel *)startDownloadURLString:(NSString *)URLString toDestinationPath:(NSString *)destinationPath progress:(TYDownloadProgressBlock)progress state:(TYDownloadStateBlock)state;

// 开始下载
- (void)startWithDownloadModel:(TYDownLoadModel *)downloadModel;

// 暂停下载
- (void)suspendWithDownloadModel:(TYDownLoadModel *)downloadModel;

// 取消下载
- (void)cancleWithDownloadModel:(TYDownLoadModel *)downloadModel;

// 删除下载
- (void)deleteFileWithDownloadModel:(TYDownLoadModel *)downloadModel;

// 删除下载
- (void)deleteAllFileWithDownloadDirectory:(NSString *)downloadDirectory;

// 获取正在下载模型
- (TYDownLoadModel *)downLoadingModelForURLString:(NSString *)URLString;
// 获取下载模型的进度
- (TYDownloadProgress *)progessWithDownloadModel:(TYDownLoadModel *)downloadModel;
// 是否已经下载
- (BOOL)isDownloadCompletedWithDownloadModel:(TYDownLoadModel *)downloadModel;

@end
