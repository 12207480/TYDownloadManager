//
//  TYDownloadUtility.h
//  TYDownloadManagerDemo
//
//  Created by tany on 16/6/12.
//  Copyright © 2016年 tany. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  下载工具类
 */
@interface TYDownloadUtility : NSObject

// 返回文件大小
+ (float)calculateFileSizeInUnit:(unsigned long long)contentLength;

// 返回文件大小的单位
+ (NSString *)calculateUnit:(unsigned long long)contentLength;

@end
