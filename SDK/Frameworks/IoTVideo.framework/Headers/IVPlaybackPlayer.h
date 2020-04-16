//
//  IVPlaybackPlayer.h
//  IoTVideo
//
//  Created by JonorZhang on 2019/11/20.
//  Copyright © 2019 Tencentcs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IVPlayer.h"
#import <AVFoundation/AVFoundation.h>
NS_ASSUME_NONNULL_BEGIN

/// 回放文件
@interface IVPlaybackItem: NSObject
/// 回放文件起始时间（秒）
@property (nonatomic, assign) NSTimeInterval startTime;
/// 回放文件结束时间（秒）
@property (nonatomic, assign) NSTimeInterval endTime;
/// 回放文件持续时间（秒）
@property (nonatomic, assign) NSTimeInterval duration;
/// 回放文件类型（例如手动录像、人形侦测等）
@property (nonatomic, strong) NSString      *type;
@end

/// 回放文件分页
@interface IVPlaybackPage: NSObject
/// 当前页码索引
@property (nonatomic, assign) uint32_t  pageIndex;
/// 总页数
@property (nonatomic, assign) uint32_t  totalPage;
// /回放文件数组
@property (nonatomic, strong) NSArray<IVPlaybackItem *> *items;
@end

/// 回放文件获取回调
typedef void (^PlaybackListCallback)(IVPlaybackPage *_Nullable page, NSError *_Nullable error);

/// 回放播放器
@interface IVPlaybackPlayer : IVPlayer

/// 创建空播放器
/// @param deviceId 设备ID
- (instancetype)initWithDeviceId:(NSString *)deviceId;

/// 创建播放器同时设置回放参数
/// @param deviceId 设备ID
/// @param item 播放的文件(可跨文件)
/// @param time 指定播放起始时间点（秒），取值范围`playbackItem.startTime >= time <= playbackItem.endTime`
- (instancetype)initWithDeviceId:(NSString *)deviceId playbackItem:(IVPlaybackItem *)item seekToTime:(NSTimeInterval)time;;

/// 获取一页回放文件列表
/// 请根据实际情况合理设置查询时间范围和分页，时间跨度太大可能会增加设备查询时间（一般建议设置为三天以内, 即当天、前一天和后一天）
/// @param deviceId 设备ID
/// @param pageIndex 页码索引，获取指定页码的回放文件（ pageIndex从0开始递增）
/// @param countPerPage 在[startTime, endTime]时间范围内按每页countPerPage个文件查询，每次返回一页的数据
/// @param startTime 开始时间戳（秒）
/// @param endTime 结束时间戳（秒）
/// @param completionHandler 结果回调
+ (void)getPlaybackListOfDevice:(NSString *)deviceId
                      pageIndex:(uint32_t)pageIndex
                   countPerPage:(uint32_t)countPerPage
                      startTime:(NSTimeInterval)startTime
                        endTime:(NSTimeInterval)endTime
              completionHandler:(PlaybackListCallback)completionHandler;

/// (未播放前)设置回放参数
/// @note 文件尚未播放时使用，`setPlaybackItem:seekToTime:` 后需手动调用`play`开始播放
/// @param item 播放的文件(可跨文件)
/// @param time 指定播放起始时间点（秒），取值范围`playbackItem.startTime >= time <= playbackItem.endTime`
- (void)setPlaybackItem:(IVPlaybackItem *)item seekToTime:(NSTimeInterval)time;

/// (已播放后)跳到指定文件和时间播放
/// @note 文件正在播放时使用, `seekToTime:playbackItem:`后无需再手动调用`play`开始播放
/// @param time 指定播放起始时间点（秒），取值范围`playbackItem.startTime >= time <= playbackItem.endTime`
/// @param item 播放的文件(可跨文件)
- (void)seekToTime:(NSTimeInterval)time playbackItem:(IVPlaybackItem *)item;

/// 当前回放的文件。
/// @note 时间通过`-[IVPlayer pts]`获取
@property (nonatomic, strong, nullable, readonly) IVPlaybackItem *playbackItem;

/// 暂停
- (void)pause;

/// 恢复播放
- (void)resume;

@end

NS_ASSUME_NONNULL_END
