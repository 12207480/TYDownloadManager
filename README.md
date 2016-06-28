# TYDownloadManager
Download file manager wrapped NSURLSessionDataTask and NSURLSessionDownloadTask,provide progress update and status change.<br>
下载管理类(TYDownLoadDataManager和TYDownloadSessionManager) 支持多文件断点下载和后台下载 封装了NSURLSessionDataTask和NSURLSessionDownloadTask，提供进度更新和状态改变bloc 和 delegate。

## Requirements
* Xcode 6 or higher
* iOS 7.0 or higher
* ARC

## Features
* TYDownLoadDataManager封装了NSURLSessionDataTask
* TYDownloadSessionManager封装了NSURLSessionDownloadTask
* 支持进度更新和状态改变block和delegate
* 支持多文件下载和断点续传下载，TYDownloadSessionManager支持后台下载
* 支持设置最大同时下载数maxDownloadCount和批量下载isBatchDownload
* 支持等待下载队列 先进先出或先进后出 resumeDownloadFIFO

## ScreenShot
![image](https://raw.githubusercontent.com/12207480/TYDownloadManager/master/screenshot/TYDownloadManager.gif)
<br>
![image](https://raw.githubusercontent.com/12207480/TYDownloadManager/master/screenshot/TYDownloadManager1.gif)

## Usage

### API Quickstart
```objc

// 下载代理
@property (nonatomic,weak) id<TYDownloadDelegate> delegate;

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

// 单例
+ (TYDownloadSessionManager *)manager;

// 开始下载
- (TYDownloadModel *)startDownloadURLString:(NSString *)URLString toDestinationPath:(NSString *)destinationPath progress:(TYDownloadProgressBlock)progress state:(TYDownloadStateBlock)state;

// 开始下载
- (void)startWithDownloadModel:(TYDownloadModel *)downloadModel progress:(TYDownloadProgressBlock)progress state:(TYDownloadStateBlock)state;

// 开始下载
- (void)startWithDownloadModel:(TYDownloadModel *)downloadModel;

// 恢复下载（除非确定对这个model进行了suspend，否则使用start）
- (void)resumeWithDownloadModel:(TYDownloadModel *)downloadModel;

// 暂停下载
- (void)suspendWithDownloadModel:(TYDownloadModel *)downloadModel;

// 取消下载
- (void)cancleWithDownloadModel:(TYDownloadModel *)downloadModel;

// 删除下载
- (void)deleteFileWithDownloadModel:(TYDownloadModel *)downloadModel;

// 删除下载
- (void)deleteAllFileWithDownloadDirectory:(NSString *)downloadDirectory;

// 获取正在下载模型
- (TYDownloadModel *)downLoadingModelForURLString:(NSString *)URLString;

```

```objc
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
```

### Block

```objc

// TYDownloadModel block
// 进度更新block
typedef void (^TYDownloadProgressBlock)(TYDownloadProgress *progress);
// 状态更新block
typedef void (^TYDownloadStateBlock)(TYDownloadState state,NSString *filePath, NSError *error);

```

### Delegate

```objc
// TYDownLoadDataManager 和 TYDownloadSessionManager
// TYDownLoadManager下载代理
@protocol TYDownloadDelegate <NSObject>

// 更新下载进度
- (void)downloadModel:(TYDownloadModel *)downloadModel didUpdateProgress:(TYDownloadProgress *)progress;
// 更新下载状态
- (void)downloadModel:(TYDownloadModel *)downloadModel didChangeState:(TYDownloadState)state filePath:(NSString *)filePath error:(NSError *)error;

@end

```

### Demo
```objc
// 下载可以使用 manager的代理 或者 downloadModel的block

- (IBAction)download:(id)sender {
    TYDownloadSessionManager *manager = [TYDownloadSessionManager manager];
    
    if (_downloadModel.state == TYDownloadStateReadying) {
        [manager cancleWithDownloadModel:_downloadModel];
        return;
    }
    
    if ([manager isDownloadCompletedWithDownloadModel:_downloadModel]) {
        [manager deleteFileWithDownloadModel:_downloadModel];
    }
    
    if (_downloadModel.state == TYDownloadStateRunning) {
        [manager suspendWithDownloadModel:_downloadModel];
        return;
    }
    [self startDownlaod];
}

- (void)startDownlaod
{
    TYDownloadSessionManager *manager = [TYDownloadSessionManager manager];
    __weak typeof(self) weakSelf = self;
    [manager startWithDownloadModel:_downloadModel progress:^(TYDownloadProgress *progress) {
        weakSelf.progressView.progress = progress.progress;
        weakSelf.progressLabel.text = [weakSelf detailTextForDownloadProgress:progress];
        
    } state:^(TYDownloadState state, NSString *filePath, NSError *error) {
        if (state == TYDownloadStateCompleted) {
            weakSelf.progressView.progress = 1.0;
            weakSelf.progressLabel.text = [NSString stringWithFormat:@"progress %.2f",weakSelf.progressView.progress];
        }
        
        [weakSelf.downloadBtn setTitle:[weakSelf stateTitleWithState:state] forState:UIControlStateNormal];
        
        //NSLog(@"state %ld error%@ filePath%@",state,error,filePath);
    }];
}

// [TYDownloadSessionManager manager].delegate = self;
// [TYDownLoadDataManager manager].delegate = self;

#pragma mark - TYDownloadDelegate

- (void)downloadModel:(TYDownloadModel *)downloadModel didUpdateProgress:(TYDownloadProgress *)progress
{
     NSLog(@"delegate progress %.3f",progress.progress);
}

- (void)downloadModel:(TYDownloadModel *)downloadModel didChangeState:(TYDownloadState)state filePath:(NSString *)filePath error:(NSError *)error
{
    NSLog(@"delegate state %ld error%@ filePath%@",state,error,filePath);
}

```

### Contact
如果你发现bug，please pull reqeust me <br>
如果你有更好的改进，please pull reqeust me <br>
如果你有更好的想法或者建议可以联系我，Email:122074809@qq.com
