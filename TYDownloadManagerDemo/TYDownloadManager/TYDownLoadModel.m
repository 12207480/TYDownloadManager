//
//  TYDownloadModel.m
//  TYDownloadManagerDemo
//
//  Created by tany on 16/6/1.
//  Copyright © 2016年 tany. All rights reserved.
//

#import "TYDownloadModel.h"

@interface TYDownloadProgress ()
// 续传大小
@property (nonatomic, assign) int64_t resumeBytesWritten;
// 这次写入的数量
@property (nonatomic, assign) int64_t bytesWritten;
// 已下载的数量
@property (nonatomic, assign) int64_t totalBytesWritten;
// 文件的总大小
@property (nonatomic, assign) int64_t totalBytesExpectedToWrite;
// 下载进度
@property (nonatomic, assign) float progress;
// 下载速度
@property (nonatomic, assign) float speed;
// 下载剩余时间
@property (nonatomic, assign) int remainingTime;

@end

@interface TYDownloadModel ()

// >>>>>>>>>>>>>>>>>>>>>>>>>>  download info
// 下载地址
@property (nonatomic, strong) NSString *downloadURL;
// 文件名 默认nil 则为下载URL中的文件名
@property (nonatomic, strong) NSString *fileName;
// 缓存文件目录 默认nil 则为manger缓存目录
@property (nonatomic, strong) NSString *downloadDirectory;

// >>>>>>>>>>>>>>>>>>>>>>>>>>  task info
// 下载状态
@property (nonatomic, assign) TYDownloadState state;
// 下载任务
@property (nonatomic, strong) NSURLSessionTask *task;
// 文件流
@property (nonatomic, strong) NSOutputStream *stream;
// 下载文件路径,下载完成后有值,把它移动到你的目录
@property (nonatomic, strong) NSString *filePath;
// 下载时间
@property (nonatomic, strong) NSDate *downloadDate;
// 断点续传需要设置这个数据 
@property (nonatomic, strong) NSData *resumeData;
// 手动取消当做暂停
@property (nonatomic, assign) BOOL manualCancle;

@end

@implementation TYDownloadModel

- (instancetype)init
{
    if (self = [super init]) {
        _progress = [[TYDownloadProgress alloc]init];
    }
    return self;
}

- (instancetype)initWithURLString:(NSString *)URLString
{
    return [self initWithURLString:URLString filePath:nil];
}

- (instancetype)initWithURLString:(NSString *)URLString filePath:(NSString *)filePath
{
    if (self = [self init]) {
        _downloadURL = URLString;
        _fileName = filePath.lastPathComponent;
        _downloadDirectory = filePath.stringByDeletingLastPathComponent;
        _filePath = filePath;
    }
    return self;
}

-(NSString *)fileName
{
    if (!_fileName) {
        _fileName = _downloadURL.lastPathComponent;
    }
    return _fileName;
}

- (NSString *)downloadDirectory
{
    if (!_downloadDirectory) {
        _downloadDirectory = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"TYDownloadCache"];
    }
    return _downloadDirectory;
}

- (NSString *)filePath
{
    if (!_filePath) {
        _filePath = [self.downloadDirectory stringByAppendingPathComponent:self.fileName];
    }
    return _filePath;
}

@end

@implementation TYDownloadProgress

@end