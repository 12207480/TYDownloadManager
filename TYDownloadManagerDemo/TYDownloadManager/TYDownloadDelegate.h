//
//  TYDownloadDelegate.h
//  TYDownloadManagerDemo
//
//  Created by tany on 16/6/24.
//  Copyright © 2016年 tany. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TYDownloadModel.h"

// 下载代理
@protocol TYDownloadDelegate <NSObject>

// 更新下载进度
- (void)downloadModel:(TYDownloadModel *)downloadModel didUpdateProgress:(TYDownloadProgress *)progress;

// 更新下载状态
- (void)downloadModel:(TYDownloadModel *)downloadModel didChangeState:(TYDownloadState)state filePath:(NSString *)filePath error:(NSError *)error;

@end
