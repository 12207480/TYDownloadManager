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
 *  下载管理类 使用NSURLSessionDataTask
 */
@interface TYDownLoadDataManager : NSObject <NSURLSessionDelegate>

// 下载中的模型 只读
@property (nonatomic, strong,readonly) NSMutableArray *waitingDownloadModels;
// 等待中的模型 只读
@property (nonatomic, strong,readonly) NSMutableArray *downloadingModels;

// 最大下载数
@property (nonatomic, assign) NSInteger maxDownloadCount;

// 等待下载队列 先进先出 默认YES， 当NO时，先进后出
@property (nonatomic, assign) BOOL resumeDownloadFIFO;

// 全部并发 默认NO, 当YES时，忽略maxDownloadCount
@property (nonatomic, assign) BOOL isBatchDownload;

// 单例
+ (TYDownLoadDataManager *)manager;

// 开始下载
- (TYDownLoadModel *)startDownloadURLString:(NSString *)URLString toDestinationPath:(NSString *)destinationPath progress:(TYDownloadProgressBlock)progress state:(TYDownloadStateBlock)state;

// 开始下载
- (void)startWithDownloadModel:(TYDownLoadModel *)downloadModel;

// 开始下载
- (void)startWithDownloadModel:(TYDownLoadModel *)downloadModel progress:(TYDownloadProgressBlock)progress state:(TYDownloadStateBlock)state;

// 恢复下载（除非确定对这个model进行了suspend，否则使用start）
- (void)resumeWithDownloadModel:(TYDownLoadModel *)downloadModel;

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
