//
//  NSURLSession+TYCorrectedResumeData.h
//  TYDownloadManagerDemo
//
//  Created by tanyang on 2016/10/7.
//  Copyright © 2016年 tany. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURLSession (TYCorrectedResumeData)

- (NSURLSessionDownloadTask *)downloadTaskWithCorrectResumeData:(NSData *)resumeData;

@end
