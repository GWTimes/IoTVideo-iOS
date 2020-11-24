//
//  IVTimer.h
//  IoTVideo
//
//  Created by JonorZhang on 2020/11/6.
//  Copyright © 2020 Tencentcs. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 用于解决计时器循环引用的类
 */
@interface IVTimer : NSTimer

/**
 用block的形式添加计时器要执行的操作，当block里使用弱引用时，不会对对象造成强引用，从而解决计时器的循环引用的问题

 @param interval 重复触发的时间间隔
 @param repeats  是否重复触发
 @param block    计时器要执行的操作，注意：此block中使用引用了计时器的对象时，要用弱引用操作才能解决循环引用的问题

 @return 新创建的计时器对象
 */
+ (IVTimer *)weak_scheduledTimerWithTimeInterval:(NSTimeInterval)interval
                                         repeats:(BOOL)repeats
                                           block:(void(^)(IVTimer *timer))block;

/**
 用block的形式添加计时器要执行的操作，当block里使用弱引用时，不会对对象造成强引用，从而解决计时器的循环引用的问题

 @param interval 重复触发的时间间隔
 @param repeats  是否重复触发
 @param block    计时器要执行的操作，注意：此block中使用引用了计时器的对象时，要用弱引用操作才能解决循环引用的问题

 @return 新创建的计时器对象
 */
+ (IVTimer *)weak_timerWithTimeInterval:(NSTimeInterval)interval
                                repeats:(BOOL)repeats
                                  block:(void (^)(IVTimer *timer))block;

@end

NS_ASSUME_NONNULL_END
