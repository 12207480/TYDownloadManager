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

@property (nonatomic, assign) NSInteger maxDownloadCount;

+ (TYDownLoadDataManager *)manager;

- (TYDownLoadModel *)startDownloadURLString:(NSString *)URLString toDestinationPath:(NSString *)destinationPath progress:(TYDownloadProgressBlock)progress state:(TYDownloadStateBlock)state;

- (void)startWithDownloadModel:(TYDownLoadModel *)downloadModel;

- (void)suspendWithDownloadModel:(TYDownLoadModel *)downloadModel;

- (void)cancleWithDownloadModel:(TYDownLoadModel *)downloadModel;

- (void)deleteFileWithDownloadModel:(TYDownLoadModel *)downloadModel;

- (void)deleteAllFileWithDownloadDirectory:(NSString *)downloadDirectory;

// 获取正在下载模型
- (TYDownLoadModel *)downLoadingModelForURLString:(NSString *)URLString;
// 获取下载模型的进度
- (TYDownloadProgress *)progessWithDownloadModel:(TYDownLoadModel *)downloadModel;
// 是否已经下载
- (BOOL)isDownloadCompletedWithDownloadModel:(TYDownLoadModel *)downloadModel;

@end
