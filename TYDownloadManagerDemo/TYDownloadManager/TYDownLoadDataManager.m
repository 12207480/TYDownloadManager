//
//  TYDownLoadDataManager.m
//  TYDownloadManagerDemo
//
//  Created by tany on 16/6/12.
//  Copyright © 2016年 tany. All rights reserved.
//

#import "TYDownLoadDataManager.h"

@interface TYDownLoadModel ()

// >>>>>>>>>>>>>>>>>>>>>>>>>>  task info
// 下载状态
@property (nonatomic, assign) TYDownLoadState state;
// 下载任务
@property (nonatomic, strong) NSURLSessionDataTask *task;
// 文件流
@property (nonatomic, strong) NSOutputStream *stream;
// 下载文件路径,下载完成后有值,把它移动到你的目录
@property (nonatomic, strong) NSString *filePath;
// 下载时间
@property (nonatomic, strong) NSDate *downloadDate;

@end

/**
 *  下载进度
 */
@interface TYDownloadProgress ()
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
@property (nonatomic, assign) int remainingTime;
@end


@interface TYDownLoadDataManager ()
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

// 手动取消当做停止操作
@property (nonatomic, assign) BOOL manaualCancle;
@end

@implementation TYDownLoadDataManager

#pragma mark - getter

+ (TYDownLoadDataManager *)manager
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
        _maxDownloadCount = 1;
    }
    return self;
}

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
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:self.queue];
    }
    return _session;
}

- (NSOperationQueue *)queue
{
    if (!_queue) {
        _queue = [[NSOperationQueue alloc]init];
        _queue.maxConcurrentOperationCount = 3;
    }
    return _queue;
}

- (NSString *)downloadDirectory
{
    if (!_downloadDirectory) {
        _downloadDirectory = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"TYDownlodCache"];
    }
    return _downloadDirectory;
}

- (NSString *)fileSizePathWithDownloadModel:(TYDownLoadModel *)downloadModel
{
    return [downloadModel.downloadDirectory stringByAppendingPathComponent:@"downloadsFileSize.plist"];
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
    
    downloadModel.progressBlock = progress;
    downloadModel.stateBlock = state;
    
    [self startWithDownloadModel:downloadModel];
    
    return downloadModel;
}

- (void)startWithDownloadModel:(TYDownLoadModel *)downloadModel
{
    if (!downloadModel) {
        NSLog(@"downloadModel can't nil");
        return;
    }
    
    // 验证是否已经下载文件
    if ([self isDownloadCompletedWithDownloadModel:downloadModel]) {
        NSString *filePath = downloadModel.filePath;
        downloadModel.state = TYDownLoadStateCompleted;
        dispatch_async(dispatch_get_main_queue(), ^(){
            if (downloadModel.stateBlock) {
                downloadModel.stateBlock(TYDownLoadStateCompleted,filePath,nil);
            }
        });
        return;
    }
    
    // 验证是否存在
    if (downloadModel.task && downloadModel.task.state == NSURLSessionTaskStateRunning) {
        downloadModel.state = TYDownLoadStateRunning;
        if ([self.downloadingModels indexOfObject:downloadModel] == NSNotFound) {
            [self.downloadingModels addObject:downloadModel];
        }
        return;
    }
    
    [self resumeWithDownloadModel:downloadModel];
}

- (void)resumeWithDownloadModel:(TYDownLoadModel *)downloadModel
{
    if (!downloadModel) {
        return;
    }
    if (self.downloadingModels.count >= _maxDownloadCount ) {
        if ([self.waitingDownloadModels indexOfObject:downloadModel] == NSNotFound) {
            [self.waitingDownloadModels addObject:downloadModel];
            downloadModel.state = TYDownLoadStateReadying;
             dispatch_async(dispatch_get_main_queue(), ^(){
                 if (downloadModel.stateBlock) {
                     downloadModel.stateBlock(TYDownLoadStateReadying,nil,nil);
                 }
            });
        }
        return;
    }
    
    if ([self.waitingDownloadModels indexOfObject:downloadModel] != NSNotFound) {
        [self.waitingDownloadModels removeObject:downloadModel];
    }
    
    // 创建目录
    [self createDirectory:downloadModel.downloadDirectory];
    
    // 如果task 不存在 或者 取消了
    if (!downloadModel.task || downloadModel.task.state == NSURLSessionTaskStateCanceling) {
        NSString *URLString = downloadModel.downloadURL;
        
        NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:self.queue];
        // 创建请求
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:URLString]];
        
        // 设置请求头
        NSString *range = [NSString stringWithFormat:@"bytes=%zd-", [self fileSizeWithDownloadModel:downloadModel]];
        [request setValue:range forHTTPHeaderField:@"Range"];
        
        // 创建流
        downloadModel.stream = [NSOutputStream outputStreamToFileAtPath:downloadModel.filePath append:YES];
        
        downloadModel.downloadDate = [NSDate date];
        self.downloadingModelDic[downloadModel.downloadURL] = downloadModel;
    
        // 创建一个Data任务
        downloadModel.task = [session dataTaskWithRequest:request];
        downloadModel.task.taskDescription = URLString;
    }
    
    if ([self.downloadingModels indexOfObject:downloadModel] == NSNotFound) {
        [self.downloadingModels addObject:downloadModel];
    }
    
    [downloadModel.task resume];
    downloadModel.state = TYDownLoadStateRunning;
    if (downloadModel.stateBlock) {
        downloadModel.stateBlock(TYDownLoadStateRunning,nil,nil);
    }
}

- (void)suspendWithDownloadModel:(TYDownLoadModel *)downloadModel
{
    _manaualCancle = YES;
    [downloadModel.task cancel];
}

- (void)cancleWithDownloadModel:(TYDownLoadModel *)downloadModel
{
    [downloadModel.task cancel];
}

#pragma mark - delete file

- (void)deleteFileWithDownloadModel:(TYDownLoadModel *)downloadModel
{
    if (!downloadModel) {
        return;
    }
    
    if (!downloadModel.filePath) {
        return;
    }
    
    if ([self.fileManager fileExistsAtPath:downloadModel.filePath]) {
        
        // 删除任务
        downloadModel.task.taskDescription = nil;
        [downloadModel.task cancel];
        downloadModel.task = nil;
        
        // 删除流
        if (downloadModel.stream.streamStatus > NSStreamStatusNotOpen && downloadModel.stream.streamStatus < NSStreamStatusClosed) {
            [downloadModel.stream close];
        }
        downloadModel.stream = nil;
        // 删除沙盒中的资源
        [self.fileManager removeItemAtPath:downloadModel.filePath error:nil];
        
        [self removeDownLoadingModelForURLString:downloadModel.downloadURL];
        // 删除资源总长度
        if ([self.fileManager fileExistsAtPath:[self fileSizePathWithDownloadModel:downloadModel]]) {
            
            NSMutableDictionary *dict = [self fileSizePlistWithDownloadModel:downloadModel];
            [dict removeObjectForKey:downloadModel.downloadURL];
            [dict writeToFile:[self fileSizePathWithDownloadModel:downloadModel] atomically:YES];
        }
    }
}

- (void)deleteAllFileWithDownloadDirectory:(NSString *)downloadDirectory
{
    if (!downloadDirectory) {
        downloadDirectory = self.downloadDirectory;
    }
    if ([self.fileManager fileExistsAtPath:downloadDirectory]) {
        
        // 删除任务
        for (TYDownLoadModel *downloadModel in [self.downloadingModelDic allValues]) {
            if ([downloadModel.downloadDirectory isEqualToString:downloadDirectory]) {
                // 删除任务
                downloadModel.task.taskDescription = nil;
                [downloadModel.task cancel];
                downloadModel.task = nil;
                
                // 删除流
                if (downloadModel.stream.streamStatus > NSStreamStatusNotOpen && downloadModel.stream.streamStatus < NSStreamStatusClosed) {
                    [downloadModel.stream close];
                }
                downloadModel.stream = nil;
            }
        }
        // 删除沙盒中所有资源
        [self.fileManager removeItemAtPath:downloadDirectory error:nil];
    }
}

#pragma mark - public

// 获取下载模型
- (TYDownLoadModel *)downLoadingModelForURLString:(NSString *)URLString
{
    TYDownLoadModel *downloadModel = [self.downloadingModelDic objectForKey:URLString];
    return downloadModel;
}

// 是否已经下载
- (BOOL)isDownloadCompletedWithDownloadModel:(TYDownLoadModel *)downloadModel
{
    long long fileSize = [self fileSizeInCachePlistWithDownloadModel:downloadModel];
    if (fileSize > 0 && fileSize == [self fileSizeWithDownloadModel:downloadModel]) {
        return YES;
    }
    return NO;
}

- (TYDownloadProgress *)progessWithDownloadModel:(TYDownLoadModel *)downloadModel
{
    TYDownloadProgress *progress = [[TYDownloadProgress alloc]init];
    progress.totalBytesExpectedToWrite = [self fileSizeInCachePlistWithDownloadModel:downloadModel];
    progress.totalBytesWritten = [self fileSizeWithDownloadModel:downloadModel];
    progress.progress = progress.totalBytesExpectedToWrite > 0 ? 1.0*progress.totalBytesWritten/progress.totalBytesExpectedToWrite : 0;
    
    return progress;
}

#pragma mark - private

- (void)removeDownLoadingModelForURLString:(NSString *)URLString
{
    [self.downloadingModelDic removeObjectForKey:URLString];
}

//  创建缓存目录文件
- (void)createDirectory:(NSString *)directory
{
    if (![self.fileManager fileExistsAtPath:directory]) {
        [self.fileManager createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:NULL];
    }
}

// 获取文件大小
- (long long)fileSizeWithDownloadModel:(TYDownLoadModel *)downloadModel{
    NSString *filePath = downloadModel.filePath;
    if (![self.fileManager fileExistsAtPath:filePath]) return 0;
    return [[self.fileManager attributesOfItemAtPath:filePath error:nil] fileSize];
}

// 获取plist保存文件大小
- (long long)fileSizeInCachePlistWithDownloadModel:(TYDownLoadModel *)downloadModel
{
    NSDictionary *downloadsFileSizePlist = [NSDictionary dictionaryWithContentsOfFile:[self fileSizePathWithDownloadModel:downloadModel]];
    return [downloadsFileSizePlist[downloadModel.downloadURL] longLongValue];
}

- (NSMutableDictionary *)fileSizePlistWithDownloadModel:(TYDownLoadModel *)downloadModel
{
    NSMutableDictionary *downloadsFileSizePlist = [NSMutableDictionary dictionaryWithContentsOfFile:[self fileSizePathWithDownloadModel:downloadModel]];
    if (!downloadsFileSizePlist) {
        downloadsFileSizePlist = [NSMutableDictionary dictionary];
    }
    return downloadsFileSizePlist;
}

#pragma mark - NSURLSessionDelegate

/**
 * 接收到响应
 */
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSHTTPURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    
    TYDownLoadModel *downloadModel = [self downLoadingModelForURLString:dataTask.taskDescription];
    if (!downloadModel) {
        return;
    }
    // 打开流
    [downloadModel.stream open];
    
    // 获得服务器这次请求 返回数据的总长度
    long long totalBytesWritten =  [self fileSizeWithDownloadModel:downloadModel];
    long long totalBytesExpectedToWrite = totalBytesWritten + [response.allHeaderFields[@"Content-Length"] longLongValue];
    
    downloadModel.progress.resumeBytesWritten = totalBytesWritten;
    downloadModel.progress.totalBytesWritten = totalBytesWritten;
    downloadModel.progress.totalBytesExpectedToWrite = totalBytesExpectedToWrite;
    
    // 存储总长度
    NSMutableDictionary *dic = [self fileSizePlistWithDownloadModel:downloadModel];
    dic[downloadModel.downloadURL] = @(totalBytesExpectedToWrite);
    [dic writeToFile:[self fileSizePathWithDownloadModel:downloadModel] atomically:YES];
    
    // 接收这个请求，允许接收服务器的数据
    completionHandler(NSURLSessionResponseAllow);
}

/**
 * 接收到服务器返回的数据
 */
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    TYDownLoadModel *downloadModel = [self downLoadingModelForURLString:dataTask.taskDescription];
    if (!downloadModel) {
        return;
    }
    // 写入数据
    [downloadModel.stream write:data.bytes maxLength:data.length];
    
    // 下载进度
    downloadModel.progress.bytesWritten = data.length;
    downloadModel.progress.totalBytesWritten += downloadModel.progress.bytesWritten;
    downloadModel.progress.progress  = MIN(1.0, 1.0*downloadModel.progress.totalBytesWritten/downloadModel.progress.totalBytesExpectedToWrite);
    
    
    NSTimeInterval downloadTime = -1 * [downloadModel.downloadDate timeIntervalSinceNow];
    downloadModel.progress.speed = (downloadModel.progress.totalBytesWritten - downloadModel.progress.resumeBytesWritten) / downloadTime;
    
    
    int64_t remainingContentLength = downloadModel.progress.totalBytesExpectedToWrite - downloadModel.progress.totalBytesWritten;
    downloadModel.progress.remainingTime = (int)(remainingContentLength / downloadModel.progress.speed);
    
    dispatch_async(dispatch_get_main_queue(), ^(){
        if (downloadModel.progress) {
                downloadModel.progressBlock(downloadModel.progress);
        }
    });
}

/**
 * 请求完毕（成功|失败）
 */
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    TYDownLoadModel *downloadModel = [self downLoadingModelForURLString:task.taskDescription];
    
    if (!downloadModel) {
        return;
    }
    
    if (_manaualCancle == YES) {
        _manaualCancle = NO;
        downloadModel.state = TYDownLoadStateSuspended;
        dispatch_async(dispatch_get_main_queue(), ^(){
            if (downloadModel.stateBlock) {
                downloadModel.stateBlock(TYDownLoadStateSuspended,nil,nil);
            }
        });
    }else if ([self isDownloadCompletedWithDownloadModel:downloadModel]) {
        downloadModel.state = TYDownLoadStateCompleted;
        dispatch_async(dispatch_get_main_queue(), ^(){
            if (downloadModel.stateBlock) {
                downloadModel.stateBlock(TYDownLoadStateCompleted,downloadModel.filePath,nil);
            }
        });
    }else if (error){
        // 下载失败
        downloadModel.state = TYDownLoadStateFailed;
        dispatch_async(dispatch_get_main_queue(), ^(){
            if (downloadModel.stateBlock) {
                downloadModel.stateBlock(TYDownLoadStateFailed,nil,error);
            }
        });
    }
    
    // 关闭流
    [downloadModel.stream close];
    downloadModel.stream = nil;
    downloadModel.task = nil;
    
    // 清除任务
    [self removeDownLoadingModelForURLString:downloadModel.downloadURL];
    
    dispatch_async(dispatch_get_main_queue(), ^(){
        [self.downloadingModels removeObject:downloadModel];
        // 还有未下载的
        if (self.waitingDownloadModels.count > 0) {
            [self resumeWithDownloadModel:self.waitingDownloadModels.firstObject];
        }
    });
}

@end
