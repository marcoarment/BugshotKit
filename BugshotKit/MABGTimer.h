//
//  MABGTimer.h
//  BackgroundTimer
//
//  Created by Michael Ash on 6/23/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <dispatch/dispatch.h>
#import <Foundation/Foundation.h>


#ifndef mt_dispatch_strong
    #if TARGET_OS_IPHONE
        #if __IPHONE_OS_VERSION_MIN_REQUIRED >= 60000
            #define mt_dispatch_release(__v)
            #define mt_dispatch_strong strong
        #else
            #define mt_dispatch_release(__v) (dispatch_release(__v));
            #define mt_dispatch_strong assign
        #endif
    #else
        #if MAC_OS_X_VERSION_MIN_REQUIRED >= 1080
            #define mt_dispatch_release(__v)
            #define mt_dispatch_strong strong
        #else
            #define mt_dispatch_release(__v) (dispatch_release(__v));
            #define mt_dispatch_strong assign
        #endif
    #endif
#endif

typedef enum
{
    BSK_MABGTimerCoalesce, // subsequent calls with charged timer can only reduce the time until firing, not extend; default value
    BSK_MABGTimerDelay // subsequent calls replace the existing time, potentially extending it
} BSK_MABGTimerBehavior;

@interface BSK_MABGTimer : NSObject
{
    __unsafe_unretained id _obj;
    dispatch_queue_t _queue;
    dispatch_source_t _timer;
    BSK_MABGTimerBehavior _behavior;
    NSTimeInterval _nextFireTime;
}

@property (assign) id obj;
@property (mt_dispatch_strong, readonly) dispatch_queue_t queue;

- (id)initWithObject:(id)obj;
- (id)initWithObject:(id)obj behavior:(BSK_MABGTimerBehavior)behavior queueLabel:(char const *)queueLabel;

- (void)setTargetQueue: (dispatch_queue_t)target;
- (void)afterDelay: (NSTimeInterval)delay do: (void (^)(id self))block;
- (void)performWhileLocked: (void (^)(void))block;
- (void)cancel;

@end
