//
//  ccAssetReaderManager.m
//  视频流
//
//  Created by cc on 2019/12/25.
//  Copyright © 2019 cc. All rights reserved.
//

#import "ccAssetReaderManager.h"

@interface ccAssetReaderManager ()

@property (nonatomic,strong) AVAsset *videoAsset;
//媒体读取对象
@property (nonatomic,strong) AVAssetReader *reader;
//加载轨道及配置
@property (nonatomic,strong) AVAssetReaderTrackOutput *readerTrackOutput_video;
@property (nonatomic,strong) AVAssetReaderTrackOutput *readerTrackOutput_audio;
//资源配置
@property (nonatomic,strong) NSDictionary *videoSetting;
@property (nonatomic,strong) NSDictionary *audioSetting;

@property (nonatomic,strong) NSMutableArray *clipTimeRangeArray;
@property (nonatomic,strong) NSMutableArray<NSValue*> *sampleTimeArray;

@end

@implementation ccAssetReaderManager

+ (instancetype)initReader:(NSString *)videoPath{
    
    ccAssetReaderManager* manager = [[ccAssetReaderManager alloc] init];
    manager.videoAsset = [AVAsset assetWithURL:[NSURL fileURLWithPath:videoPath]];
    
    if ([manager.reader canAddOutput:manager.readerTrackOutput_video]) {
        [manager.reader addOutput:manager.readerTrackOutput_video];
    }
    if ([manager.reader canAddOutput:manager.readerTrackOutput_audio]) {
        [manager.reader addOutput:manager.readerTrackOutput_audio];
    }
    [manager.reader startReading];
    return manager;
}

- (void)setclipTimeRangeArray{
    CMSampleBufferRef sample;
    CMTime presentationTime = kCMTimeZero;
    CMTime startTime = kCMTimeZero;
    CMTime endTime = kCMTimeZero;
    NSUInteger processIndex = 0;
    
    self.clipTimeRangeArray = [NSMutableArray array];
    self.sampleTimeArray = [NSMutableArray array];
    
    //每10片确定一个帧组范围
    while((sample = [self nextVideoSample])) {
        //时间点
        presentationTime = CMSampleBufferGetPresentationTimeStamp(sample);
        NSValue *presentationValue = [NSValue valueWithBytes:&presentationTime objCType:@encode(CMTime)];
        [self.sampleTimeArray addObject:presentationValue];
        
        CFRelease(sample);
        sample = NULL;
                
        if (processIndex == 0) {
//            startTime = presentationTime;
            processIndex ++;
            
        } else if (processIndex == 9) {
            endTime = presentationTime;
            
            CMTimeRange timeRange = CMTimeRangeMake(startTime, CMTimeSubtract(endTime, startTime));
            NSValue *timeRangeValue = [NSValue valueWithCMTimeRange:timeRange];
            [self.clipTimeRangeArray addObject:timeRangeValue];
            
            processIndex = 0;
            startTime = presentationTime;
            endTime = kCMTimeZero;
            
        } else {
            processIndex ++;
        }
    }
    //处理不够kClipMaxContainCount数量的帧的timerange
    if (CMTIME_COMPARE_INLINE(kCMTimeZero, !=, startTime) && CMTIME_COMPARE_INLINE(kCMTimeZero, ==, endTime)) {
        
        endTime = presentationTime;
        
        //单独处理最后只剩一帧的情况
        if (CMTIME_COMPARE_INLINE(endTime, ==, startTime) &&
            processIndex == 1) {
            startTime = CMTimeSubtract(startTime, CMTimeMake(1, self.videoAsset.tracks[0].nominalFrameRate));
        }
        
        CMTimeRange timeRange = CMTimeRangeMake(startTime, CMTimeSubtract(endTime, startTime));
        NSValue *timeRangeValue = [NSValue valueWithCMTimeRange:timeRange];
        [self.clipTimeRangeArray addObject:timeRangeValue];
    }
}

//倒序读取
- (void)nextReverseVideoSample:(void(^)(CMSampleBufferRef buffer,CMTime pts_reverse))block{
    
    __block NSInteger index = 0;
    __block NSMutableArray* bufferCaches = [NSMutableArray array];
    __block NSMutableArray<NSValue*>* ptsCaches = [NSMutableArray array];
    
    [self.clipTimeRangeArray enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {

        CMSampleBufferRef buffer;
        [_readerTrackOutput_video resetForReadingTimeRanges:@[obj]];

        while ((buffer = [self nextVideoSample])) {

            [bufferCaches addObject:(__bridge id _Nonnull)(buffer)];
            [ptsCaches addObject:self.sampleTimeArray[index]];
            index++;
        }
        [bufferCaches enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {

            CMTime pts = ptsCaches[ptsCaches.count - idx - 1].CMTimeValue;
            NSLog(@"==%f",CMTimeGetSeconds(pts));

            block((__bridge CMSampleBufferRef)(obj),pts);
        }];
        [bufferCaches removeAllObjects];
        [ptsCaches removeAllObjects];
    }];
}

- (void)nextSpeedChangeFromValue:(float)slowValue VideoSample:(void(^)(CMSampleBufferRef buffer,CMTime pts_reverse))block{
    __block NSInteger index = 0;
    __block NSMutableArray* bufferCaches = [NSMutableArray array];
    __block NSMutableArray<NSValue*>* ptsCaches = [NSMutableArray array];
    
    [self.clipTimeRangeArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CMSampleBufferRef buffer;
        [_readerTrackOutput_video resetForReadingTimeRanges:@[obj]];

        while ((buffer = [self nextVideoSample])) {

            [bufferCaches addObject:(__bridge id _Nonnull)(buffer)];
            [ptsCaches addObject:self.sampleTimeArray[index]];
            index++;
        }
             
        [bufferCaches enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            CMTime pts = ptsCaches[idx].CMTimeValue;
            
            pts = CMTimeMultiplyByFloat64(pts, 1/slowValue);
            block((__bridge CMSampleBufferRef)(obj),pts);
            
        }];
        [bufferCaches removeAllObjects];
        [ptsCaches removeAllObjects];
    }];
}

- (CMSampleBufferRef)nextVideoSample{
    if (!_readerTrackOutput_video) {
        return nil;
    }
    return [_readerTrackOutput_video copyNextSampleBuffer];
}
- (CMSampleBufferRef)nextAudioSample{
    if (!_readerTrackOutput_audio) {
        return nil;
    }
    return [_readerTrackOutput_audio copyNextSampleBuffer];
}

- (void)cancel{
    [self.reader cancelReading];
}

-(AVAssetReader *)reader{
    if (!_reader) {
        _reader = [[AVAssetReader alloc] initWithAsset:self.videoAsset error:nil];
    }
    return _reader;
}
//resetForReadingTimeRanges
-(AVAssetReaderTrackOutput *)readerTrackOutput_video{
    if (!_readerTrackOutput_video) {
        AVAssetTrack *videoTrack = [[self.videoAsset tracksWithMediaType:AVMediaTypeVideo] firstObject];
        _readerTrackOutput_video = [[AVAssetReaderTrackOutput alloc] initWithTrack:videoTrack outputSettings:self.videoSetting];
        _readerTrackOutput_video.alwaysCopiesSampleData = NO;
        _readerTrackOutput_video.supportsRandomAccess = YES;//不按照顺序读取

    }
    return _readerTrackOutput_video;
}
-(AVAssetReaderTrackOutput *)readerTrackOutput_audio{
    if (!_readerTrackOutput_audio) {
        AVAssetTrack *audioTrack = [[self.videoAsset tracksWithMediaType:AVMediaTypeAudio] firstObject];
        _readerTrackOutput_audio = [[AVAssetReaderTrackOutput alloc] initWithTrack:audioTrack outputSettings:self.audioSetting];
        _readerTrackOutput_audio.alwaysCopiesSampleData = NO;
        _readerTrackOutput_audio.supportsRandomAccess = YES;//不按照顺序读取

    }
    return _readerTrackOutput_audio;
}
-(NSDictionary *)videoSetting{
    if (!_videoSetting) {
        _videoSetting = @{
            (id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA),
        };
    }
    return _videoSetting;
}
-(NSDictionary *)audioSetting{
    if (!_audioSetting) {
        _audioSetting = @{
            AVFormatIDKey : [NSNumber numberWithUnsignedInt:kAudioFormatLinearPCM]
        };
    }
    return _audioSetting;
}

@end
