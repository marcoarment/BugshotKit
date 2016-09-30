//  BSKWindow.m
//  See included LICENSE file for the (MIT) license.
//  Created by Bryan Irace on 1/21/14.

#import "BSKWindow.h"
#import "BugshotKit.h"


@interface BSKWindow ()
@property (nonatomic) NSTimeInterval applicationActivatedAtTime;
@end

@implementation BSKWindow

#pragma mark - UIResponder

- (instancetype)initWithFrame:(CGRect)frame
{
    if ( (self = [super initWithFrame:frame]) ) {
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [NSNotificationCenter.defaultCenter removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)applicationWillEnterForeground:(NSNotification *)n
{
    [BugshotKit dismissAninmated:NO completion:NULL];
}

- (void)applicationDidBecomeActive:(NSNotification *)n
{
    self.applicationActivatedAtTime = NSDate.date.timeIntervalSince1970;
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    [super motionEnded:motion withEvent:event];

    if (event.subtype == UIEventSubtypeMotionShake &&
        UIApplication.sharedApplication.applicationState == UIApplicationStateActive &&
        NSDate.date.timeIntervalSince1970 - self.applicationActivatedAtTime > 1.5
    ) {
        [BugshotKit show];
    }
}

@end
