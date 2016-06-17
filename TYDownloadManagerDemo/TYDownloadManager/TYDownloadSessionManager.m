//
//  TYDownloadSessionManager.m
//  TYDownloadManagerDemo
//
//  Created by tany on 16/6/12.
//  Copyright © 2016年 tany. All rights reserved.
//

#import "TYDownloadSessionManager.h"
#import <CommonCrypto/CommonDigest.h>
#import <UIKit/UIKit.h>

/**
 *  下载模型
 */
@interface TYDownLoadModel ()

// >>>>>>>>>>>>>>>>>>>>>>>>>>  task info
// 下载状态
@property (nonatomic, assign) TYDownLoadState state;
// 下载任务
@property (nonatomic, strong) NSURLSessionDownloadTask *task;
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

/**
 *  下载进度
 */
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

@interface TYDownloadSessionManager ()

// >>>>>>>>>>>>>>>>>>>>>>>>>>  file info
// 文件管理
@property (nonatomic, strong) NSFileManager *fileManager;
// 缓存文件目录
@property (nonatomic, strong) NSString *downloadDirectory;

// >>>>>>>>>>>>>>>>>>>>>>>>>>  session info
// 下载seesion会话
@property (nonatomic, strong) NSURLSession *session;
// 下载模型字典 key = url
@property (nonatomic, strong) NSMutableDictionary *downloadingModelDic;
// 下载中的模型
@property (nonatomic, strong) NSMutableArray *waitingDownloadModels;
// 等待中的模型
@property (nonatomic, strong) NSMutableArray *downloadingModels;
// 回调代理的队列
@property (strong, nonatomic) NSOperationQueue *queue;

@end

#define IS_IOS8ORLATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8)

@implementation TYDownloadSessionManager

+ (TYDownloadSessionManager *)manager
{
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init
{
    if (self = [super init]) {
        _backgroundConfigure = @"TYDownloadSessionManager.backgroundConfigure";
        _maxDownloadCount = 1;
        _resumeDownloadFIFO = YES;
        _isBatchDownload = NO;
    }
    return self;
}

- (void)configureBackroundSession
{
    if (!_backgroundConfigure) {
        return;
    }
    [self session];
}

#pragma mark - getter

- (NSFileManager *)fileManager
{
    if (!_fileManager) {
        _fileManager = [[NSFileManager alloc]init];
    }
    return _fileManager;
}

- (NSURLSession *)session
{
    if (!_session) {
        if (_backgroundConfigure) {
            if (IS_IOS8ORLATER) {
                _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:_backgroundConfigure]delegate:self delegateQueue:self.queue];
            }else{
                _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration backgroundSessionConfiguration:_backgroundConfigure]delegate:self delegateQueue:self.queue];
            }
        }else {
            _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:self.queue];
        }
    }
    return _session;
}

- (NSOperationQueue *)queue
{
    if (!_queue) {
        _queue = [[NSOperationQueue alloc]init];
        _queue.maxConcurrentOperationCount = 1;
    }
    return _queue;
}

- (NSString *)downloadDirectory
{
    if (!_downloadDirectory) {
        _downloadDirectory = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"TYDownloadCache"];
        [self createDirectory:_downloadDirectory];
        NSLog(@"downloadDirectory %@",_downloadDirectory);
    }
    return _downloadDirectory;
}

- (NSMutableDictionary *)downloadingModelDic
{
    if (!_downloadingModelDic) {
        _downloadingModelDic = [NSMutableDictionary dictionary];
    }
    return _downloadingModelDic;
}

- (NSMutableArray *)waitingDownloadModels
{
    if (!_waitingDownloadModels) {
        _waitingDownloadModels = [NSMutableArray array];
    }
    return _waitingDownloadModels;
}

- (NSMutableArray *)downloadingModels
{
    if (!_downloadingModels) {
        _downloadingModels = [NSMutableArray array];
    }
    return _downloadingModels;
}

#pragma mark - downlaod

- (TYDownLoadModel *)startDownloadURLString:(NSString *)URLString toDestinationPath:(NSString *)destinationPath progress:(TYDownloadProgressBlock)progress state:(TYDownloadStateBlock)state
{
    // 验证下载地址
    if (!URLString) {
        NSLog(@"dwonloadURL can't nil");
        return nil;
    }
    
    TYDownLoadModel *downloadModel = [self downLoadingModelForURLString:URLString];
    
    if (!downloadModel || ![downloadModel.filePath isEqualToString:destinationPath]) {
        downloadModel = [[TYDownLoadModel alloc]initWithURLString:URLString filePath:destinationPath];
    }
    
    [self startWithDownloadModel:downloadModel progress:progress state:state];
    
    return downloadModel;
}

- (void)startWithDownloadModel:(TYDownLoadModel *)downloadModel progress:(TYDownloadProgressBlock)progress state:(TYDownloadStateBlock)state
{
    downloadModel.progressBlock = progress;
    downloadModel.stateBlock = state;
    
    [self startWithDownloadModel:downloadModel];
}


- (void)startWithDownloadModel:(TYDownLoadModel *)downloadModel
{
    if (!downloadModel || downloadModel.state == TYDownLoadStateReadying) {
        return;
    }

    // 验证是否存在
    if (downloadModel.task && downloadModel.task.state == NSURLSessionTaskStateRunning) {
        downloadModel.state = TYDownLoadStateRunning;
        return;
    }
    
    [self createDirectory:_downloadDirectory];
    [self createDirectory:downloadModel.downloadDirectory];
    
    // 后台下载设置
    [self configirebackgroundSessionTasksWithDownloadModel:downloadModel];
    
    [self resumeWithDownloadModel:downloadModel];
}

- (void)resumeWithDownloadModel:(TYDownLoadModel *)downloadModel
{
    if (!downloadModel) {
        return;
    }
    
    if (![self canResumeDownlaodModel:downloadModel]) {
        return;
    }
    
    // 如果task 不存在 或者 取消了
    if (!downloadModel.task || downloadModel.task.state == NSURLSessionTaskStateCanceling) {
        
        NSData *resumeData = [self resumeDataFromFileWithDownloadModel:downloadModel];
        
        if (resumeData) {
            downloadModel.task = [self.session downloadTaskWithResumeData:resumeData];
        }else {
            NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:downloadModel.downloadURL]];
            downloadModel.task = [self.session downloadTaskWithRequest:request];
        }
        downloadModel.task.taskDescription = downloadModel.downloadURL;
        downloadModel.downloadDate = [NSDate date];
    }

    if (!downloadModel.downloadDate) {
        downloadModel.downloadDate = [NSDate date];
    }
    
    if (![self.downloadingModelDic objectForKey:downloadModel.downloadURL]) {
        self.downloadingModelDic[downloadModel.downloadURL] = downloadModel;
    }
    
    [downloadModel.task resume];
    
    if (downloadModel.stateBlock) {
        downloadModel.state = TYDownLoadStateRunning;
        downloadModel.stateBlock(TYDownLoadStateRunning,nil,nil);
    }
}

- (void)suspendWithDownloadModel:(TYDownLoadModel *)downloadModel
{
    if (!downloadModel.manualCancle) {
        downloadModel.manualCancle = YES;
        [self cancleWithDownloadModel:downloadModel clearResumeData:NO];
    }
}

- (void)cancleWithDownloadModel:(TYDownLoadModel *)downloadModel
{
    if (downloadModel.state != TYDownLoadStateCompleted && downloadModel.state != TYDownLoadStateFailed){
        [self cancleWithDownloadModel:downloadModel clearResumeData:NO];
    }
}

// 删除下载
- (void)deleteFileWithDownloadModel:(TYDownLoadModel *)downloadModel
{
    if (downloadModel.state != TYDownLoadStateCompleted && downloadModel.state != TYDownLoadStateFailed){
        [self cancleWithDownloadModel:downloadModel clearResumeData:YES];
        [self deleteFileIfExist:downloadModel.filePath];
    }
}

- (void)cancleWithDownloadModel:(TYDownLoadModel *)downloadModel clearResumeData:(BOOL)clearResumeData
{
    if (clearResumeData) {
        downloadModel.resumeData = nil;
        [downloadModel.task cancel];
    }else {
        [(NSURLSessionDownloadTask *)downloadModel.task cancelByProducingResumeData:^(NSData *resumeData){
        }];
    }
}

- (void)willResumeNextWithDowloadModel:(TYDownLoadModel *)downloadModel
{
    if (_isBatchDownload) {
        return;
    }
    
    @synchronized (self) {
        [self.downloadingModels removeObject:downloadModel];
        // 还有未下载的
        if (self.waitingDownloadModels.count > 0) {
            [self resumeWithDownloadModel:_resumeDownloadFIFO ? self.waitingDownloadModels.firstObject:self.waitingDownloadModels.lastObject];
        }
    }
}

- (BOOL)canResumeDownlaodModel:(TYDownLoadModel *)downloadModel
{
    if (_isBatchDownload) {
        return YES;
    }
    
    @synchronized (self) {
        if (self.downloadingModels.count >= _maxDownloadCount ) {
            if ([self.waitingDownloadModels indexOfObject:downloadModel] == NSNotFound) {
                [self.waitingDownloadModels addObject:downloadModel];
                self.downloadingModelDic[downloadModel.downloadURL] = downloadModel;
                downloadModel.state = TYDownLoadStateReadying;
                if (downloadModel.stateBlock) {
                    downloadModel.stateBlock(TYDownLoadStateReadying,nil,nil);
                }
            }
            return NO;
        }
        
        if ([self.waitingDownloadModels indexOfObject:downloadModel] != NSNotFound) {
            [self.waitingDownloadModels removeObject:downloadModel];
        }
        
        if ([self.downloadingModels indexOfObject:downloadModel] == NSNotFound) {
            [self.downloadingModels addObject:downloadModel];
        }
        return YES;
    }
}

#pragma mark - configire background task

- (void)configirebackgroundSessionTasksWithDownloadModel:(TYDownLoadModel *)downloadModel
{
    if (!_backgroundConfigure) {
        return ;
    }
    
    NSURLSessionDownloadTask *task = [self backgroundSessionTasksWithDownloadModel:downloadModel];
    if (!task) {
        return;
    }
    
    downloadModel.task = task;
    if (task.state == NSURLSessionTaskStateRunning) {
        [task suspend];
    }
}

- (NSURLSessionDownloadTask *)backgroundSessionTasksWithDownloadModel:(TYDownLoadModel *)downloadModel
{
    NSArray *tasks = [self sessionDownloadTasks];
    for (NSURLSessionDownloadTask *task in tasks) {
        if (task.state == NSURLSessionTaskStateRunning || task.state == NSURLSessionTaskStateSuspended) {
            NSString *taskInfo = downloadModel.downloadURL;
            if ([taskInfo isEqualToString:task.taskDescription]) {
                return task;
            }
        }
    }
    return nil;
}

- (NSArray *)sessionDownloadTasks
{
    return [self tasksForKeyPath:@"sessionDownloadTasks"];
}

- (NSArray *)tasksForKeyPath:(NSString *)keyPath
{
    __block NSArray *tasks = nil;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [self.session getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        if ([keyPath isEqualToString:@"sessionDownloadTasks"]) {
            tasks = downloadTasks;
        }
        
        dispatch_semaphore_signal(semaphore);
    }];
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return tasks;
}

#pragma mark - public

// 获取下载模型
- (TYDownLoadModel *)downLoadingModelForURLString:(NSString *)URLString
{
    return [self.downloadingModelDic objectForKey:URLString];
}

// 是否已经下载
- (BOOL)isDownloadCompletedWithDownloadModel:(TYDownLoadModel *)downloadModel
{
    return [self.fileManager fileExistsAtPath:downloadModel.filePath];
}

// 取消所有后台
- (void)cancleAllBackgroundSessionTasks
{
    if (!_backgroundConfigure) {
        return;
    }
    
    for (NSURLSessionDownloadTask *task in [self sessionDownloadTasks]) {
        [task cancelByProducingResumeData:^(NSData * resumeData) {
            }];
    }
}

#pragma mark - private

- (void)removeDownLoadingModelForURLString:(NSString *)URLString
{
    [self.downloadingModelDic removeObjectForKey:URLString];
}

- (NSData *)resumeDataFromFileWithDownloadModel:(TYDownLoadModel *)downloadModel
{
    if (downloadModel.resumeData) {
        return downloadModel.resumeData;
    }
    NSString *resumeDataPath = [self resumeDataPathWithDownloadURL:downloadModel.downloadURL];
    
    if ([_fileManager fileExistsAtPath:resumeDataPath]) {
        NSData *resumeData = [NSData dataWithContentsOfFile:resumeDataPath];
        return resumeData;
    }
    return nil;
}

- (NSString *)resumeDataPathWithDownloadURL:(NSString *)downloadURL
{
    NSString *resumeFileName = [[self class] md5:downloadURL];
    return [self.downloadDirectory stringByAppendingPathComponent:resumeFileName];
}

+ (NSString *)md5:(NSString *)str
{
    const char *cStr = [str UTF8String];
    if (cStr == NULL) {
        cStr = "";
    }
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5( cStr, (CC_LONG)strlen(cStr), result );
    return [NSString stringWithFormat:
            @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}

//  创建缓存目录文件
- (void)createDirectory:(NSString *)directory
{
    if (![self.fileManager fileExistsAtPath:directory]) {
        [self.fileManager createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:NULL];
    }
}

- (void)moveFileAtURL:(NSURL *)srcURL toPath:(NSString *)dstPath
{
    NSError *error = nil;
    if ([self.fileManager fileExistsAtPath:dstPath] ) {
        [self.fileManager removeItemAtPath:dstPath error:&error];
        if (error) {
            NSLog(@"removeItem error %@",error);
        }
    }
    
    NSURL *dstURL = [NSURL fileURLWithPath:dstPath];
    [self.fileManager moveItemAtURL:srcURL toURL:dstURL error:&error];
    if (error){
        NSLog(@"moveItem error:%@",error);
    }
}

- (void)deleteFileIfExist:(NSString *)filePath
{
    if ([self.fileManager fileExistsAtPath:filePath] ) {
        NSError *error  = nil;
        [self.fileManager removeItemAtPath:filePath error:&error];
        if (error) {
            NSLog(@"emoveItem error %@",error);
        }
    }
}


#pragma mark - NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes
{
    TYDownLoadModel *downloadModel = [self downLoadingModelForURLString:downloadTask.taskDescription];
    
    if (!downloadModel || downloadModel.state == TYDownLoadStateSuspended) {
        return;
    }
    
    downloadModel.progress.resumeBytesWritten = fileOffset;
}

// 监听文件下载进度
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    TYDownLoadModel *downloadModel = [self downLoadingModelForURLString:downloadTask.taskDescription];
    
    if (!downloadModel || downloadModel.state == TYDownLoadStateSuspended) {
        return;
    }
    
    float progress = (double)totalBytesWritten/totalBytesExpectedToWrite;
    
    int64_t resumeBytesWritten = downloadModel.progress.resumeBytesWritten;
    
    NSTimeInterval downloadTime = -1 * [downloadModel.downloadDate timeIntervalSinceNow];
    float speed = (totalBytesWritten - resumeBytesWritten) / downloadTime;
    
    int64_t remainingContentLength = totalBytesExpectedToWrite - totalBytesWritten;
    int remainingTime = (int)(remainingContentLength / speed);
    
    downloadModel.progress.bytesWritten = bytesWritten;
    downloadModel.progress.totalBytesWritten = totalBytesWritten;
    downloadModel.progress.totalBytesExpectedToWrite = totalBytesExpectedToWrite;
    downloadModel.progress.progress = progress;
    downloadModel.progress.speed = speed;
    downloadModel.progress.remainingTime = remainingTime;
    
    dispatch_async(dispatch_get_main_queue(), ^(){
        if (downloadModel.progressBlock) {
            downloadModel.progressBlock(downloadModel.progress);
        }
    });
}


// 下载成功
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location
{
    TYDownLoadModel *downloadModel = [self downLoadingModelForURLString:downloadTask.taskDescription];
    if (!downloadModel) {
        return;
    }
    
    if (location) {
        // 移动文件到下载目录
        [self createDirectory:downloadModel.downloadDirectory];
        [self moveFileAtURL:location toPath:downloadModel.filePath];
    }
}

// 下载完成
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    TYDownLoadModel *downloadModel = [self downLoadingModelForURLString:task.taskDescription];
    
    if (!downloadModel) {
        NSData *resumeData = error ? [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData]:nil;
        if (resumeData) {
            [resumeData writeToFile:[self resumeDataPathWithDownloadURL:task.taskDescription] atomically:YES];
        }else {
            [self deleteFileIfExist:[self resumeDataPathWithDownloadURL:task.taskDescription]];
        }
        return;
    }

    if (error) {
        downloadModel.progress.resumeBytesWritten = 0;
        downloadModel.resumeData = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];
        [downloadModel.resumeData writeToFile:[self resumeDataPathWithDownloadURL:downloadModel.downloadURL] atomically:YES];
    } else {
        downloadModel.resumeData = nil;
        downloadModel.progress.resumeBytesWritten = 0;
        [self deleteFileIfExist:[self resumeDataPathWithDownloadURL:downloadModel.downloadURL]];
    }
    
    downloadModel.task = nil;
    [self removeDownLoadingModelForURLString:downloadModel.downloadURL];
    
    if (downloadModel.manualCancle) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            downloadModel.manualCancle = NO;
            downloadModel.state = TYDownLoadStateSuspended;
            if (downloadModel.stateBlock) {
                downloadModel.stateBlock(TYDownLoadStateSuspended,nil,nil);
            }
            [self willResumeNextWithDowloadModel:downloadModel];
        });
    }else if (error){
        // 下载失败
        dispatch_async(dispatch_get_main_queue(), ^(){
            downloadModel.state = TYDownLoadStateFailed;
            if (downloadModel.stateBlock) {
                downloadModel.stateBlock(TYDownLoadStateFailed,nil,error);
            }
            [self willResumeNextWithDowloadModel:downloadModel];
        });
    }else {
        dispatch_async(dispatch_get_main_queue(), ^(){
            downloadModel.state = TYDownLoadStateCompleted;
            if (downloadModel.stateBlock) {
                downloadModel.stateBlock(TYDownLoadStateCompleted,downloadModel.filePath,nil);
            }
            [self willResumeNextWithDowloadModel:downloadModel];
        });
    }

}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session
{
    if (self.backgroundSessionCompletionHandler) {
        self.backgroundSessionCompletionHandler();
    }
}

@end
