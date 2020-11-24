//
//  IVMacros.h
//  IoTVideo
//
//  Created by JonorZhang on 2020/11/2.
//  Copyright © 2020 Tencentcs. All rights reserved.
//

#ifndef IVMacros_h
#define IVMacros_h

#import <Foundation/Foundation.h>

// usage: @weakify(target)
#ifndef weakify
    #if DEBUG
        #if __has_feature(objc_arc)
            #define weakify(object) autoreleasepool{} __weak __typeof__(object) weak##_##object = object;
        #else
            #define weakify(object) autoreleasepool{} __block __typeof__(object) block##_##object = object;
        #endif
    #else
        #if __has_feature(objc_arc)
            #define weakify(object) try{} @finally{} {} __weak __typeof__(object) weak##_##object = object;
        #else
            #define weakify(object) try{} @finally{} {} __block __typeof__(object) block##_##object = object;
        #endif
    #endif
#endif

// usage: @strongify(target)
#ifndef strongify
    #if DEBUG
        #if __has_feature(objc_arc)
            #define strongify(object) autoreleasepool{} __typeof__(object) object = weak##_##object;
        #else
            #define strongify(object) autoreleasepool{} __typeof__(object) object = block##_##object;
        #endif
    #else
        #if __has_feature(objc_arc)
            #define strongify(object) try{} @finally{} __typeof__(object) object = weak##_##object;
        #else
            #define strongify(object) try{} @finally{} __typeof__(object) object = block##_##object;
        #endif
    #endif
#endif


NS_INLINE
void dispatch_async_safe(dispatch_queue_t queue, dispatch_block_t block) {
    if (strcmp(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL), dispatch_queue_get_label(queue)) == 0) {
        block();
    } else {
        dispatch_async(queue, ^{
            block();
        });
    }
}

NS_INLINE
void dispatch_sync_safe(dispatch_queue_t queue, DISPATCH_NOESCAPE dispatch_block_t block) {
    if (strcmp(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL), dispatch_queue_get_label(queue)) == 0) {
        block();
    } else {
        dispatch_sync(queue, ^{
            block();
        });
    }
}

NS_INLINE
void dispatch_main_async_safe(dispatch_block_t block) {
    dispatch_async_safe(dispatch_get_main_queue(), block);
}

NS_INLINE
void dispatch_main_sync_safe(DISPATCH_NOESCAPE dispatch_block_t block) {
    dispatch_sync_safe(dispatch_get_main_queue(), block);
}


#define exec_safe(block, ...) if (block) { block(__VA_ARGS__); };

#define exec_main_async_safe(block, ...) if (block) { dispatch_async_safe(dispatch_get_main_queue(), ^{block(__VA_ARGS__);}); }
#define exec_main_sync_safe(block, ...) if (block) { dispatch_sync_safe(dispatch_get_main_queue(), ^{block(__VA_ARGS__);}); }

#endif /* IVMacros_h */
