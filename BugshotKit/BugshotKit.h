//  BugshotKit.h
//  See included LICENSE file for the (MIT) license.
//  Created by Marco Arment on 1/15/14.

#import <UIKit/UIKit.h>
#import "BSKMainViewController.h"
#import "BSKWindow.h"

#if ! DEBUG
#warning BugshotKit is being included in a non-debug build.
#endif

extern NSString * const BSKNewLogMessageNotification;


typedef enum : NSUInteger {
    BSKInvocationGestureNone        = 0,
    BSKInvocationGestureSwipeUp     = 1,
    BSKInvocationGestureSwipeDown   = (1 << 1),
    BSKInvocationGestureSwipeFromRightEdge = (1 << 2), // For whatever reason, this gesture recognizer always only needs one touch, regardless of your numberOfTouches setting.
    BSKInvocationGestureDoubleTap = (1 << 3),
    BSKInvocationGestureTripleTap = (1 << 4),
	BSKInvocationGestureLongPress = (1 << 5),
} BSKInvocationGestureMask;

@interface BugshotKit : NSObject <UIGestureRecognizerDelegate, BSKMainViewControllerDelegate>

/*
    Call this from your UIApplication didFinishLaunching:... method.
    
    Optionally, multiple email addresses can be specified, separated by commas in the string.
*/
+ (void)enableWithNumberOfTouches:(NSUInteger)fingerCount performingGestures:(BSKInvocationGestureMask)invocationGestures feedbackEmailAddress:(NSString *)toEmailAddress;

/* You can also always show it manually */
+ (void)show;

+ (instancetype)sharedManager;
- (void)clearLog;

+ (void)addLogMessage:(NSString *)message;
+ (UIFont *)consoleFontWithSize:(CGFloat)size;

@property (nonatomic, copy) NSString *destinationEmailAddress;
@property (nonatomic) NSUInteger consoleLogMaxLines;

/*
    Every email has an info.json attachment with a serialized dictionary containing at least these keys:

    @{
        @"appName" : @"Your App",
        @"appVersion" : @"1.0",
        @"systemVersion" : @"7.0.4",
        @"deviceModel" : @"iPhone6,1"
    }

    To add more keys to get merged into this dictionary, return them from a custom extraInfoBlock:
*/
+ (void)setExtraInfoBlock:(NSDictionary *(^)())extraInfoBlock;


/*
    You can optionally customize the email subject line by setting an emailSubjectBlock.

    info is the app-info dictionary from above (including anything you provided with extraInfoBlock)
*/
+ (void)setEmailSubjectBlock:(NSString *(^)(NSDictionary *))emailSubjectBlock;


// feel free to mess with these if you want

- (NSString *)currentConsoleLogWithDateStamps:(BOOL)dateStamps;

@property (nonatomic) UIColor *annotationFillColor;
@property (nonatomic) UIColor *annotationStrokeColor;
@property (nonatomic) UIColor *toggleOnColor;
@property (nonatomic) UIColor *toggleOffColor;


// don't mess with these
@property (nonatomic) UIImage *snapshotImage;
@property (nonatomic, copy) NSArray *annotations;
@property (nonatomic) UIImage *annotatedImage;
@property (nonatomic, copy) NSDictionary *(^extraInfoBlock)();
@property (nonatomic, copy) NSString *(^emailSubjectBlock)(NSDictionary *info);

@end

UIImage *BSKImageWithDrawing(CGSize size, void (^drawingCommands)());
