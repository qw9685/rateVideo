//
//  ccAssetReaderManager.h
//  视频流
//
//  Created by cc on 2019/12/25.
//  Copyright © 2019 cc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ccAssetReaderManager : NSObject

+ (instancetype)initReader:(NSString*)videoPath;

//必须实现读取
- (void)setclipTimeRangeArray;

//倒序读取
- (void)nextReverseVideoSample:(void(^)(CMSampleBufferRef buffer,CMTime pts_reverse))block;

//改变速度读取
- (void)nextSpeedChangeFromValue:(float)slowValue VideoSample:(void(^)(CMSampleBufferRef buffer,CMTime pts_reverse))block;

- (void)cancel;//停止

@end

NS_ASSUME_NONNULL_END
