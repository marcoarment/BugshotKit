//  BugshotKit.h
//  See included LICENSE file for the (MIT) license.
//  Created by Marco Arment on 1/15/14.

#import <UIKit/UIKit.h>
#import "BSKMainViewController.h"

#if ! DEBUG
#warning BugshotKit is being included in a non-debug build.
#endif

extern NSString * const BSKNewLogMessageNotification;

typedef NS_ENUM(NSInteger, BSKInvocationGesture) {
    BSKInvocationGestureNone        = 0,
    BSKInvocationGestureSwipeUp     = 1,
    BSKInvocationGestureSwipeDown   = (1 << 1),
    BSKInvocationGestureSwipeFromRightEdge = (1 << 2), // For whatever reason, this gesture recognizer always only needs one touch, regardless of your numberOfTouches setting.
    BSKInvocationGestureDoubleTap = (1 << 3),
    BSKInvocationGestureTripleTap = (1 << 4),
};

@interface BugshotKit : NSObject <UIGestureRecognizerDelegate, BSKMainViewControllerDelegate>

/*
    The optional extraInfoBlock() returns an NSDictionary or nil. It's called just before email composition for each report,
    and can be used to supply any additional info that might improve the report's usefulness (user ID, important object states, etc.).

    If a non-empty dictionary is returned, its contents are serialized into a JSON attachment named "info.json".
*/
+ (void)enableWithNumberOfTouches:(NSUInteger)fingerCount performingGestures:(BSKInvocationGesture)invocationGestures feedbackEmailAddress:(NSString *)toEmailAddress extraInfoBlock:(NSDictionary *(^)())extraInfoBlock;

/* You can also always show it manually */
+ (void)show;

+ (instancetype)sharedManager;
- (void)clearLog;

+ (void)addLogMessage:(NSString *)message;

+ (UIFont *)consoleFontWithSize:(CGFloat)size;

@property (nonatomic) UIColor *annotationFillColor;
@property (nonatomic) UIColor *annotationStrokeColor;
@property (nonatomic) UIColor *toggleOnColor;
@property (nonatomic) UIColor *toggleOffColor;
@property (nonatomic, copy) NSString *destinationEmailAddress;
@property (nonatomic, copy) NSDictionary * (^extraInfoBlock)();

@property (nonatomic) NSUInteger consoleLogMaxLines;
- (NSString *)currentConsoleLogWithDateStamps:(BOOL)dateStamps;

@property (nonatomic) UIImage *snapshotImage;
@property (nonatomic, copy) NSArray *annotations;
@property (nonatomic) UIImage *annotatedImage;

@end
