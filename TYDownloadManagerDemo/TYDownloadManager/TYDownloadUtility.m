//
//  TYDownloadUtility.m
//  TYDownloadManagerDemo
//
//  Created by tany on 16/6/12.
//  Copyright © 2016年 tany. All rights reserved.
//

#import "TYDownloadUtility.h"

@implementation TYDownloadUtility

+ (float)calculateFileSizeInUnit:(unsigned long long)contentLength
{
    if(contentLength >= pow(1024, 3))
        return (float) (contentLength / (float)pow(1024, 3));
    else if(contentLength >= pow(1024, 2))
        return (float) (contentLength / (float)pow(1024, 2));
    else if(contentLength >= 1024)
        return (float) (contentLength / (float)1024);
    else
        return (float) (contentLength);
}
+ (NSString *)calculateUnit:(unsigned long long)contentLength
{
    if(contentLength >= pow(1024, 3))
        return @"GB";
    else if(contentLength >= pow(1024, 2))
        return @"MB";
    else if(contentLength >= 1024)
        return @"KB";
    else
        return @"Bytes";
}

@end
