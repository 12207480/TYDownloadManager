//
//  TYDownloadDelegate.h
//  TYDownloadManagerDemo
//
//  Created by tany on 16/6/24.
//  Copyright © 2016年 tany. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TYDownloadModel.h"

@protocol TYDownloadDelegate <NSObject>

- (void)downloadModel:(TYDownloadModel *)downloadModel updateProgress:(TYDownloadProgress *)progress;

- (void)downloadModel:(TYDownloadModel *)downloadModel didChangeState:(TYDownloadState)state filePath:(NSString *)filePath error:(NSError *)error;

@end
