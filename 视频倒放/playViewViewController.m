//
//  playViewViewController.m
//  视频倒放
//
//  Created by cc on 2020/1/19.
//  Copyright © 2020 mac. All rights reserved.
//

#import "playViewViewController.h"
#import <AVKit/AVKit.h>

@interface playViewViewController ()

@property (nonatomic,strong) AVPlayerLayer *playerlayer;
@property (nonatomic,strong) AVPlayer * avplayer;
@property (nonatomic,strong) AVPlayerItem * avplayerItem;

@end

@implementation playViewViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString* videoPath = [[NSBundle mainBundle] pathForResource:@"1.mp4" ofType:nil];
    
    self.avplayerItem = [[AVPlayerItem alloc] initWithURL:[NSURL fileURLWithPath:videoPath]];
    self.avplayer = [AVPlayer playerWithPlayerItem:self.avplayerItem];
    
    self.playerlayer = [AVPlayerLayer playerLayerWithPlayer:self.avplayer];
    self.playerlayer.frame = CGRectMake(0, self.navigationController.navigationBar.frame.size.height, self.view.frame.size.width, self.view.frame.size.height - self.navigationController.navigationBar.frame.size.height);
    
    [self.view.layer addSublayer:self.playerlayer];
    
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
    
    [self.avplayer seekToTime:kCMTimeZero];
    [self.avplayer play];
    
    switch (sender.tag) {
        case 0:
            if ([self.avplayer.currentItem canPlaySlowReverse]) {
                self.avplayer.rate = -1.0;
                [self.avplayer seekToTime:self.avplayer.currentItem.duration];
            }else{
                [self showAlert:@"不支持倒叙播放"];
            }
            break;
        case 1:
            self.avplayer.rate = 1;
            break;
        case 2:
            if ([self.avplayer.currentItem canPlaySlowForward]) {
                self.avplayer.rate = 0.5;
            }else{
                [self showAlert:@"不支持0.5倍速播放"];
            }
            break;
        case 3:
            if ([self.avplayer.currentItem canPlayFastForward]) {
                self.avplayer.rate = 2.0;
            }else{
                [self showAlert:@"不支持2倍速播放"];
            }
            break;
            
        default:
            break;
    }
}

- (void)showAlert:(NSString*)message{
    UIAlertController* alertVc = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:nil];
    [alertVc addAction:action];
    [self presentViewController:alertVc animated:YES completion:nil];
}

@end
