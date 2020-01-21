//
//  localVideoViewController.m
//  视频倒放
//
//  Created by cc on 2020/1/19.
//  Copyright © 2020 mac. All rights reserved.
//

#import "localVideoViewController.h"
#import "ccAssetWriterManager.h"
#import "ccAssetReaderManager.h"
#import <UIKit/UIKit.h>
#import <AVKit/AVKit.h>

@interface localVideoViewController ()

@property (nonatomic,strong) UIActivityIndicatorView* activityIndicator;

@end

@implementation localVideoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
        
    for (int i = 0; i<4; i++) {
        
        UIButton* btn = [[UIButton alloc] initWithFrame:CGRectMake(60 * i, self.view.frame.size.height - 40 - self.navigationController.navigationBar.frame.size.height, 40, 40)];
        btn.backgroundColor = [UIColor redColor];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(clickAction:) forControlEvents:UIControlEventTouchUpInside];
        btn.tag = i;
        switch (i) {
            case 0:
                [btn setTitle:@"倒放" forState:UIControlStateNormal];
                break;
            case 1:
                [btn setTitle:@"正常" forState:UIControlStateNormal];
                break;
            case 2:
                [btn setTitle:@"0.5" forState:UIControlStateNormal];
                break;
            case 3:
                [btn setTitle:@"2.0" forState:UIControlStateNormal];
                break;
            default:
                break;
        }
        
        [self.view addSubview:btn];
    }
}

- (void)clickAction:(UIButton*)sender{
    
    NSString* videoPath = [[NSBundle mainBundle] pathForResource:@"1.mp4" ofType:nil];
    NSString* outPath = [NSString stringWithFormat:@"%@/cache.mp4",[self dirDoc]];
    [[NSFileManager defaultManager] removeItemAtPath:outPath error:nil];

    switch (sender.tag) {
        case 0:
        {
            //倒序
            [self reserseWrite:videoPath outputPath:outPath];
        }
            break;
            
        case 1:
            [self playVideoWithUrl:[NSURL fileURLWithPath:videoPath]];
            break;
            
            case 2:
        {
            [self speedChangeWriteFromValue:0.5 :videoPath outputPath:outPath];

        }
              case 3:
            {
                [self speedChangeWriteFromValue:2.0 :videoPath outputPath:outPath];

            }
            break;
        default:
            break;
    }
}

//倒序
- (void)reserseWrite:(NSString*)inputPath outputPath:(NSString*)outputPath{
    
    //初始化
    ccAssetReaderManager* manager_reader = [ccAssetReaderManager initReader:inputPath];
    ccAssetWriterManager* manager_writer = [ccAssetWriterManager initWriter:outputPath inputPath:inputPath];
    
    [manager_reader setclipTimeRangeArray];
    
    //倒序读取
    [manager_reader nextReverseVideoSample:^(CMSampleBufferRef  _Nonnull buffer, CMTime pts_reverse) {
        
        CVImageBufferRef CVPixelBuffer = CMSampleBufferGetImageBuffer(buffer);
        [manager_writer pushVideoBuffer:CVPixelBuffer pts:pts_reverse];
    }];
    
    [manager_writer videoFinish];

    [manager_writer finishHandle:^(bool success) {
        if (success) {
            [manager_reader cancel];
            [manager_writer cancel];
            [self playVideoWithUrl:[NSURL fileURLWithPath:outputPath]];
        }
    }];
    
}
//慢速
- (void)speedChangeWriteFromValue:(float)value :(NSString*)inputPath outputPath:(NSString*)outputPath{
    
    //初始化
    ccAssetReaderManager* manager_reader = [ccAssetReaderManager initReader:inputPath];
    ccAssetWriterManager* manager_writer = [ccAssetWriterManager initWriter:outputPath inputPath:inputPath];
    
    [manager_reader setclipTimeRangeArray];
    
    [manager_reader nextSpeedChangeFromValue:value VideoSample:^(CMSampleBufferRef  _Nonnull buffer, CMTime pts_reverse) {
        CVImageBufferRef CVPixelBuffer = CMSampleBufferGetImageBuffer(buffer);
        [manager_writer pushVideoBuffer:CVPixelBuffer pts:pts_reverse];
    }];
    [manager_writer videoFinish];

    [manager_writer finishHandle:^(bool success) {
        if (success) {
            [manager_reader cancel];
            [manager_writer cancel];
            [self playVideoWithUrl:[NSURL fileURLWithPath:outputPath]];
        }
    }];
}

-(void)playVideoWithUrl:(NSURL *)url{
    AVPlayerViewController *playerViewController = [[AVPlayerViewController alloc]init];
    playerViewController.player = [[AVPlayer alloc]initWithURL:url];
    playerViewController.view.frame = self.view.frame;
    [playerViewController.player play];
    [self presentViewController:playerViewController animated:YES completion:nil];
}

//获取Documents目录
-(NSString *)dirDoc{
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
}

@end
