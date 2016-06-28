//
//  ViewController.m
//  TYDownloadManagerDemo
//
//  Created by tany on 16/6/12.
//  Copyright © 2016年 tany. All rights reserved.
//

#import "DownloadSessionViewController.h"
#import "TYDownLoadUtility.h"
#import "TYDownloadSessionManager.h"
#import <MediaPlayer/MediaPlayer.h>

@interface DownloadSessionViewController ()<TYDownloadDelegate>

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

static NSString * const downloadUrl = @"http://baobab.wdjcdn.com/145076769089714.mp4";
static NSString * const downloadUrl1 = @"http://baobab.wdjcdn.com/1458625865688ONE.mp4";
static NSString * const downloadUrl2 = @"http://baobab.wdjcdn.com/1442142801331138639111.mp4";

@implementation DownloadSessionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.title = @"DownloadSessionViewControllerDemo";
    // 下载可以使用 manager的代理 或者 downloadModel的block
    [TYDownloadSessionManager manager].delegate = self;
    [self refreshDowloadInfo];
    [self refreshDowloadInfo1];
    [self refreshDowloadInfo2];
}

- (void)refreshDowloadInfo
{
    // manager里面是否有这个model是正在下载
    _downloadModel = [[TYDownloadSessionManager manager] downLoadingModelForURLString:downloadUrl];
    if (_downloadModel) {
        [self startDownlaod];
        return;
    }
    TYDownloadModel *model = [[TYDownloadModel alloc]initWithURLString:downloadUrl];
    [self.downloadBtn setTitle:[[TYDownloadSessionManager manager] isDownloadCompletedWithDownloadModel:model] ? @"下载完成，重新下载":@"开始" forState:UIControlStateNormal];
    _downloadModel = model;
    
    if (!_downloadModel.task && [[TYDownloadSessionManager manager] backgroundSessionTasksWithDownloadModel:_downloadModel]) {
        [self download:nil];
    }
}

- (void)refreshDowloadInfo1
{
    _downloadModel1 = [[TYDownloadSessionManager manager] downLoadingModelForURLString:downloadUrl1];
    if (_downloadModel1) {
        [self startDownlaod1];
        return;
    }
    TYDownloadModel *model = [[TYDownloadModel alloc]initWithURLString:downloadUrl1];
    [self.downloadBtn1 setTitle:[[TYDownloadSessionManager manager] isDownloadCompletedWithDownloadModel:model] ? @"下载完成，重新下载":@"开始" forState:UIControlStateNormal];
    _downloadModel1 = model;
    
    if (!_downloadModel1.task && [[TYDownloadSessionManager manager] backgroundSessionTasksWithDownloadModel:_downloadModel1]) {
        [self download1:nil];
    }
}

- (void)refreshDowloadInfo2
{
    _downloadModel2 = [[TYDownloadSessionManager manager] downLoadingModelForURLString:downloadUrl2];
    if (_downloadModel2) {
        [self startDownlaod2];
        return;
    }
    TYDownloadModel *model = [[TYDownloadModel alloc]initWithURLString:downloadUrl2];
    [self.downloadBtn2 setTitle:[[TYDownloadSessionManager manager] isDownloadCompletedWithDownloadModel:model] ? @"下载完成，重新下载":@"开始" forState:UIControlStateNormal];
    _downloadModel2 = model;
    
    if (!_downloadModel2.task && [[TYDownloadSessionManager manager] backgroundSessionTasksWithDownloadModel:_downloadModel2]) {
        [self download2:nil];
    }
}

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

- (IBAction)download1:(id)sender {
    TYDownloadSessionManager *manager = [TYDownloadSessionManager manager];
    
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
    TYDownloadSessionManager *manager = [TYDownloadSessionManager manager];
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
    TYDownloadSessionManager *manager = [TYDownloadSessionManager manager];
    
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
    TYDownloadSessionManager *manager = [TYDownloadSessionManager manager];
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
                                        [TYDownloadUtility calculateUnit:(unsigned long long)progress.speed],progress.remainingTime];
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

- (void)downloadModel:(TYDownloadModel *)downloadModel updateProgress:(TYDownloadProgress *)progress
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
