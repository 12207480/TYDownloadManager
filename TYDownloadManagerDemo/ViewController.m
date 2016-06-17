//
//  ViewController.m
//  TYDownloadManagerDemo
//
//  Created by tany on 16/6/12.
//  Copyright © 2016年 tany. All rights reserved.
//

#import "ViewController.h"
//#import "TYDownLoadDataManager.h"
#import "TYDownLoadUtility.h"
#import "TYDownloadSessionManager.h"
#import <MediaPlayer/MediaPlayer.h>

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UIButton *downloadBtn;
@property (weak, nonatomic) IBOutlet UILabel *progressLabel;

@property (weak, nonatomic) IBOutlet UIProgressView *progressView1;
@property (weak, nonatomic) IBOutlet UIButton *downloadBtn1;
@property (weak, nonatomic) IBOutlet UILabel *progressLabel1;

@property (weak, nonatomic) IBOutlet UIProgressView *progressView2;
@property (weak, nonatomic) IBOutlet UIButton *downloadBtn2;
@property (weak, nonatomic) IBOutlet UILabel *progressLabel2;

@property (nonatomic,strong) TYDownLoadModel *downloadModel;
@property (nonatomic,strong) TYDownLoadModel *downloadModel1;
@property (nonatomic,strong) TYDownLoadModel *downloadModel2;

//播放器视图控制器
@property (nonatomic,strong) MPMoviePlayerViewController *moviePlayerViewController;
@end

NSString * const downloadUrl = @"http://down.233.com/2014_2015/2014/jzs1/jingji_zhenti_yjw/6-qllgl2v5x9b80vvgwgzzlnzydkj1bpr66hnool80.mp4";
NSString * const downloadUrl1 = @"http://down.233.com/2014a/cy/caijingfagui_jingjiang_quanguoban_mj/2-67fhxrzsawvhojeo5gpsxrafqnc82chu9kop0syla.mp4";
NSString * const downloadUrl2 = @"http://down.233.com/2014a/cy/caijingfagui_jingjiang_quanguoban_mj/10-607tmjbtijcoglgg5n4dlhgbnqipym23sw2fnvqaf.mp4";

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    // 配置后台session
    
    [self refreshDowloadInfo];
    [self refreshDowloadInfo1];
    [self refreshDowloadInfo2];
}

- (void)refreshDowloadInfo
{
    TYDownLoadModel *model = [[TYDownLoadModel alloc]initWithURLString:downloadUrl];
//    TYDownloadProgress *progress = [[TYDownLoadDataManager manager]progessWithDownloadModel:model];
//    
//    self.progressLabel.text = [self detailTextForDownloadProgress:progress];
//    self.progressView.progress = progress.progress;
    [self.downloadBtn setTitle:[[TYDownloadSessionManager manager] isDownloadCompletedWithDownloadModel:model] ? @"下载完成，重新下载":@"开始" forState:UIControlStateNormal];
    _downloadModel = model;
    
    if (!_downloadModel.task && [[TYDownloadSessionManager manager] backgroundSessionTasksWithDownloadModel:_downloadModel]) {
        [self download:nil];
    }
}

- (void)refreshDowloadInfo1
{
    TYDownLoadModel *model = [[TYDownLoadModel alloc]initWithURLString:downloadUrl1];
//    TYDownloadProgress *progress = [[TYDownLoadDataManager manager]progessWithDownloadModel:model];
//    
//    self.progressLabel1.text = [self detailTextForDownloadProgress:progress];
//    self.progressView1.progress = progress.progress;
    [self.downloadBtn1 setTitle:[[TYDownloadSessionManager manager] isDownloadCompletedWithDownloadModel:model] ? @"下载完成，重新下载":@"开始" forState:UIControlStateNormal];
    _downloadModel1 = model;
    
    if (!_downloadModel1.task && [[TYDownloadSessionManager manager] backgroundSessionTasksWithDownloadModel:_downloadModel1]) {
        [self download1:nil];
    }
}

- (void)refreshDowloadInfo2
{
    TYDownLoadModel *model = [[TYDownLoadModel alloc]initWithURLString:downloadUrl2];
//    TYDownloadProgress *progress = [[TYDownLoadDataManager manager]progessWithDownloadModel:model];
//    
//    self.progressLabel2.text = [self detailTextForDownloadProgress:progress];
//    self.progressView2.progress = progress.progress;
    [self.downloadBtn2 setTitle:[[TYDownloadSessionManager manager] isDownloadCompletedWithDownloadModel:model] ? @"下载完成，重新下载":@"开始" forState:UIControlStateNormal];
    _downloadModel2 = model;
    
    if (!_downloadModel2.task && [[TYDownloadSessionManager manager] backgroundSessionTasksWithDownloadModel:_downloadModel2]) {
        [self download2:nil];
    }
}

- (IBAction)download:(id)sender {
    TYDownloadSessionManager *manager = [TYDownloadSessionManager manager];
    
    if (_downloadModel.state == TYDownLoadStateReadying) {
        return;
    }
    
    if ([manager isDownloadCompletedWithDownloadModel:_downloadModel]) {
        _moviePlayerViewController=[[MPMoviePlayerViewController alloc]initWithContentURL:[NSURL fileURLWithPath:_downloadModel.filePath]];
        [self presentMoviePlayerViewControllerAnimated:_moviePlayerViewController];
        //[manager deleteFileWithDownloadModel:_downloadModel];
        return;
    }
    
    if (_downloadModel.state == TYDownLoadStateRunning) {
        [manager suspendWithDownloadModel:_downloadModel];
        return;
    }
    
    [manager startWithDownloadModel:_downloadModel progress:^(TYDownloadProgress *progress) {
        self.progressView.progress = progress.progress;
        self.progressLabel.text = [self detailTextForDownloadProgress:progress];
        
    } state:^(TYDownLoadState state, NSString *filePath, NSError *error) {
        if (state == TYDownLoadStateCompleted) {
            self.progressView.progress = 1.0;
            self.progressLabel.text = [NSString stringWithFormat:@"progress %.2f",self.progressView.progress];
        }
        
        [self.downloadBtn setTitle:[self stateTitleWithState:state] forState:UIControlStateNormal];
        
        NSLog(@"state %ld error%@ filePath%@",state,error,filePath);
    }];
}

- (IBAction)download1:(id)sender {
    TYDownloadSessionManager *manager = [TYDownloadSessionManager manager];
    
    if (_downloadModel1.state == TYDownLoadStateReadying) {
        return;
    }
    
    if ([manager isDownloadCompletedWithDownloadModel:_downloadModel1]) {
//        _moviePlayerViewController=[[MPMoviePlayerViewController alloc]initWithContentURL:[NSURL fileURLWithPath:_downloadModel1.filePath]];
//        [self presentMoviePlayerViewControllerAnimated:_moviePlayerViewController];
        [manager deleteFileWithDownloadModel:_downloadModel1];
        return;
    }
    
    if (_downloadModel1.state == TYDownLoadStateRunning) {
        [manager suspendWithDownloadModel:_downloadModel1];
        return;
    }
    
    [manager startWithDownloadModel:_downloadModel1 progress:^(TYDownloadProgress *progress) {
        self.progressView1.progress = progress.progress;
        self.progressLabel1.text = [self detailTextForDownloadProgress:progress];
        
    } state:^(TYDownLoadState state, NSString *filePath, NSError *error) {
        if (state == TYDownLoadStateCompleted) {
            self.progressView1.progress = 1.0;
            self.progressLabel1.text = [NSString stringWithFormat:@"progress %.2f",self.progressView1.progress];
        }
        
        [self.downloadBtn1 setTitle:[self stateTitleWithState:state] forState:UIControlStateNormal];
        
        NSLog(@"state %ld error%@ filePath%@",state,error,filePath);
    }];
}

- (IBAction)download2:(id)sender {
    TYDownloadSessionManager *manager = [TYDownloadSessionManager manager];
    
    if (_downloadModel2.state == TYDownLoadStateReadying) {
        return;
    }
    
    if ([manager isDownloadCompletedWithDownloadModel:_downloadModel2]) {
        [manager deleteFileWithDownloadModel:_downloadModel2];
    }
    
    if (_downloadModel2.state == TYDownLoadStateRunning) {
        [manager suspendWithDownloadModel:_downloadModel2];
        return;
    }
    
    [manager startWithDownloadModel:_downloadModel2 progress:^(TYDownloadProgress *progress) {
        self.progressView2.progress = progress.progress;
        self.progressLabel2.text = [self detailTextForDownloadProgress:progress];
        
    } state:^(TYDownLoadState state, NSString *filePath, NSError *error) {
        if (state == TYDownLoadStateCompleted) {
            self.progressView2.progress = 1.0;
            self.progressLabel2.text = [NSString stringWithFormat:@"progress %.2f",self.progressView2.progress];
        }
        
        [self.downloadBtn2 setTitle:[self stateTitleWithState:state] forState:UIControlStateNormal];
        
        NSLog(@"state %ld error%@ filePath%@",state,error,filePath);
    }];
}


- (NSString *)detailTextForDownloadProgress:(TYDownloadProgress *)progress
{
    NSString *fileSizeInUnits = [NSString stringWithFormat:@"%.2f %@",
                                 [TYDownloadUtility calculateFileSizeInUnit:(unsigned long long)progress.totalBytesExpectedToWrite],
                                 [TYDownloadUtility calculateUnit:(unsigned long long)progress.totalBytesExpectedToWrite]];
    
    NSMutableString *detailLabelText = [NSMutableString stringWithFormat:@"File Size: %@\nDownloaded: %.2f %@ (%.2f%%)\nSpeed: %.2f %@/sec\n",fileSizeInUnits,
                                        [TYDownloadUtility calculateFileSizeInUnit:(unsigned long long)progress.totalBytesWritten],
                                        [TYDownloadUtility calculateUnit:(unsigned long long)progress.totalBytesWritten],progress.progress*100,
                                        [TYDownloadUtility calculateFileSizeInUnit:(unsigned long long) progress.speed],
                                        [TYDownloadUtility calculateUnit:(unsigned long long)progress.speed]
                                        ];
    return detailLabelText;
}

- (NSString *)stateTitleWithState:(TYDownLoadState)state
{
    switch (state) {
        case TYDownLoadStateReadying:
            return @"等待下载";
            break;
        case TYDownLoadStateRunning:
            return @"暂停下载";
            break;
        case TYDownLoadStateCompleted:
            return @"下载完成，重新下载";
            break;
        default:
            return @"开始下载";
            break;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
