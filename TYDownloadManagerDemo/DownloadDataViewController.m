//
//  ViewController.m
//  TYDownloadManagerDemo
//
//  Created by tany on 16/6/12.
//  Copyright © 2016年 tany. All rights reserved.
//

#import "DownloadDataViewController.h"
#import "TYDownLoadDataManager.h"
#import "TYDownLoadUtility.h"
#import <MediaPlayer/MediaPlayer.h>

@interface DownloadDataViewController ()<TYDownloadDelegate>

@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UIButton *downloadBtn;
@property (weak, nonatomic) IBOutlet UILabel *progressLabel;

@property (weak, nonatomic) IBOutlet UIProgressView *progressView1;
@property (weak, nonatomic) IBOutlet UIButton *downloadBtn1;
@property (weak, nonatomic) IBOutlet UILabel *progressLabel1;

@property (weak, nonatomic) IBOutlet UIProgressView *progressView2;
@property (weak, nonatomic) IBOutlet UIButton *downloadBtn2;
@property (weak, nonatomic) IBOutlet UILabel *progressLabel2;

@property (nonatomic,strong) TYDownloadModel *downloadModel;
@property (nonatomic,strong) TYDownloadModel *downloadModel1;
@property (nonatomic,strong) TYDownloadModel *downloadModel2;

//播放器视图控制器
@property (nonatomic,strong) MPMoviePlayerViewController *moviePlayerViewController;
@end

static NSString * const downloadUrl = @"http://baobab.wdjcdn.com/1456117847747a_x264.mp4";
static NSString * const downloadUrl1 = @"http://baobab.wdjcdn.com/14525705791193.mp4";
static NSString * const downloadUrl2 = @"http://baobab.wdjcdn.com/1456459181808howtoloseweight_x264.mp4";

@implementation DownloadDataViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.title = @"DownloadDataViewControllerDemo";
    
    // 下载可以使用 manager的代理 或者 downloadModel的block
    [TYDownLoadDataManager manager].delegate = self;
    [self refreshDowloadInfo];
    [self refreshDowloadInfo1];
    [self refreshDowloadInfo2];
}

- (void)refreshDowloadInfo
{
    // manager里面是否有这个model是正在下载
    _downloadModel = [[TYDownLoadDataManager manager] downLoadingModelForURLString:downloadUrl];
    if (_downloadModel) {
        [self startDownlaod];
        return;
    }
    
    // 没有正在下载的model 重新创建
    TYDownloadModel *model = [[TYDownloadModel alloc]initWithURLString:downloadUrl];
    TYDownloadProgress *progress = [[TYDownLoadDataManager manager]progessWithDownloadModel:model];
    
    self.progressLabel.text = [self detailTextForDownloadProgress:progress];
    self.progressView.progress = progress.progress;
    [self.downloadBtn setTitle:[[TYDownLoadDataManager manager] isDownloadCompletedWithDownloadModel:model] ? @"下载完成，重新下载":@"开始" forState:UIControlStateNormal];
    _downloadModel = model;
}

- (void)refreshDowloadInfo1
{
    _downloadModel1 = [[TYDownLoadDataManager manager] downLoadingModelForURLString:downloadUrl1];
    if (_downloadModel1) {
        [self startDownlaod1];
        return;
    }
    
    TYDownloadModel *model = [[TYDownloadModel alloc]initWithURLString:downloadUrl1];
    TYDownloadProgress *progress = [[TYDownLoadDataManager manager]progessWithDownloadModel:model];
    
    self.progressLabel1.text = [self detailTextForDownloadProgress:progress];
    self.progressView1.progress = progress.progress;
    [self.downloadBtn1 setTitle:[[TYDownLoadDataManager manager] isDownloadCompletedWithDownloadModel:model] ? @"下载完成，重新下载":@"开始" forState:UIControlStateNormal];
    _downloadModel1 = model;
}

- (void)refreshDowloadInfo2
{
    _downloadModel2 = [[TYDownLoadDataManager manager] downLoadingModelForURLString:downloadUrl2];
    if (_downloadModel2) {
        [self startDownlaod2];
        return;
    }
    
    TYDownloadModel *model = [[TYDownloadModel alloc]initWithURLString:downloadUrl2];
    TYDownloadProgress *progress = [[TYDownLoadDataManager manager]progessWithDownloadModel:model];
    
    self.progressLabel2.text = [self detailTextForDownloadProgress:progress];
    self.progressView2.progress = progress.progress;
    [self.downloadBtn2 setTitle:[[TYDownLoadDataManager manager] isDownloadCompletedWithDownloadModel:model] ? @"下载完成，重新下载":@"开始" forState:UIControlStateNormal];
    _downloadModel2 = model;
}

- (IBAction)download:(id)sender {
    TYDownLoadDataManager *manager = [TYDownLoadDataManager manager];
    
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
    TYDownLoadDataManager *manager = [TYDownLoadDataManager manager];
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
- (IBAction)download1:(id)sender {
    TYDownLoadDataManager *manager = [TYDownLoadDataManager manager];
    
    if (_downloadModel1.state == TYDownloadStateReadying) {
         [manager cancleWithDownloadModel:_downloadModel1];
        return;
    }
    
    if ([manager isDownloadCompletedWithDownloadModel:_downloadModel1]) {
        [manager deleteFileWithDownloadModel:_downloadModel1];
    }
    
    if (_downloadModel1.state == TYDownloadStateRunning) {
        [manager suspendWithDownloadModel:_downloadModel1];
        return;
    }
    
    [self startDownlaod1];
}

- (void)startDownlaod1
{
    TYDownLoadDataManager *manager = [TYDownLoadDataManager manager];
    __weak typeof(self) weakSelf = self;
    [manager startWithDownloadModel:_downloadModel1 progress:^(TYDownloadProgress *progress) {
        weakSelf.progressView1.progress = progress.progress;
        weakSelf.progressLabel1.text = [weakSelf detailTextForDownloadProgress:progress];
        
    } state:^(TYDownloadState state, NSString *filePath, NSError *error) {
        if (state == TYDownloadStateCompleted) {
            weakSelf.progressView1.progress = 1.0;
            weakSelf.progressLabel1.text = [NSString stringWithFormat:@"progress %.2f",weakSelf.progressView1.progress];
        }
        
        [weakSelf.downloadBtn1 setTitle:[weakSelf stateTitleWithState:state] forState:UIControlStateNormal];
        
        //NSLog(@"state %ld error%@ filePath%@",state,error,filePath);
    }];
}

- (IBAction)download2:(id)sender {
    TYDownLoadDataManager *manager = [TYDownLoadDataManager manager];
    
    if (_downloadModel2.state == TYDownloadStateReadying) {
        [manager cancleWithDownloadModel:_downloadModel2];
        return;
    }
    
    if ([manager isDownloadCompletedWithDownloadModel:_downloadModel2]) {
        _moviePlayerViewController=[[MPMoviePlayerViewController alloc]initWithContentURL:[NSURL fileURLWithPath:_downloadModel2.filePath]];
        [self presentMoviePlayerViewControllerAnimated:_moviePlayerViewController];
        //[manager deleteFileWithDownloadModel:_downloadModel2];
        return;
    }
    
    if (_downloadModel2.state == TYDownloadStateRunning) {
        [manager suspendWithDownloadModel:_downloadModel2];
        return;
    }
    
    [self startDownlaod2];
}

- (void)startDownlaod2
{
    TYDownLoadDataManager *manager = [TYDownLoadDataManager manager];
    __weak typeof(self) weakSelf = self;
    [manager startWithDownloadModel:_downloadModel2 progress:^(TYDownloadProgress *progress) {
        weakSelf.progressView2.progress = progress.progress;
        weakSelf.progressLabel2.text = [weakSelf detailTextForDownloadProgress:progress];
        
    } state:^(TYDownloadState state, NSString *filePath, NSError *error) {
        if (state == TYDownloadStateCompleted) {
            weakSelf.progressView2.progress = 1.0;
            weakSelf.progressLabel2.text = [NSString stringWithFormat:@"progress %.2f",weakSelf.progressView2.progress];
        }
        
        [weakSelf.downloadBtn2 setTitle:[weakSelf stateTitleWithState:state] forState:UIControlStateNormal];
        
        //NSLog(@"state %ld error%@ filePath%@",state,error,filePath);
    }];
}

- (NSString *)detailTextForDownloadProgress:(TYDownloadProgress *)progress
{
    NSString *fileSizeInUnits = [NSString stringWithFormat:@"%.2f %@",
                                 [TYDownloadUtility calculateFileSizeInUnit:(unsigned long long)progress.totalBytesExpectedToWrite],
                                 [TYDownloadUtility calculateUnit:(unsigned long long)progress.totalBytesExpectedToWrite]];
    
    NSMutableString *detailLabelText = [NSMutableString stringWithFormat:@"File Size: %@\nDownloaded: %.2f %@ (%.2f%%)\nSpeed: %.2f %@/sec\nLeftTime: %dsec",fileSizeInUnits,
                                        [TYDownloadUtility calculateFileSizeInUnit:(unsigned long long)progress.totalBytesWritten],
                                        [TYDownloadUtility calculateUnit:(unsigned long long)progress.totalBytesWritten],progress.progress*100,
                                        [TYDownloadUtility calculateFileSizeInUnit:(unsigned long long) progress.speed],
                                        [TYDownloadUtility calculateUnit:(unsigned long long)progress.speed]
                                        ,progress.remainingTime];
    return detailLabelText;
}

- (NSString *)stateTitleWithState:(TYDownloadState)state
{
    switch (state) {
        case TYDownloadStateReadying:
            return @"等待下载";
            break;
        case TYDownloadStateRunning:
            return @"暂停下载";
            break;
        case TYDownloadStateFailed:
            return @"下载失败";
            break;
        case TYDownloadStateCompleted:
            return @"下载完成，重新下载";
            break;
        default:
            return @"开始下载";
            break;
    }
}

#pragma mark - TYDownloadDelegate

- (void)downloadModel:(TYDownloadModel *)downloadModel didUpdateProgress:(TYDownloadProgress *)progress
{
    NSLog(@"delegate progress %.3f",progress.progress);
}

- (void)downloadModel:(TYDownloadModel *)downloadModel didChangeState:(TYDownloadState)state filePath:(NSString *)filePath error:(NSError *)error
{
    NSLog(@"delegate state %ld error%@ filePath%@",state,error,filePath);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
