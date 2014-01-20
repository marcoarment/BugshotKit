//  BugshotKit.m
//  See included LICENSE file for the (MIT) license.
//  Created by Marco Arment on 1/15/14.

#import "BugshotKit.h"
#include "TargetConditionals.h"
#import <asl.h>
@import CoreText;

#define BSKLogMessageLengthLimit 65536

NSString * const BSKNewLogMessageNotification = @"BSKNewLogMessageNotification";

@interface BSKLogMessage : NSObject
@property (nonatomic) NSTimeInterval timestamp;
@property (nonatomic, copy) NSString *message;
@end

@implementation BSKLogMessage
@end


@interface BugshotKit () {
    BOOL isShowing;
    BOOL consoleMessagesNeedSorting;
    dispatch_source_t source;
    int sourceCalls;
}
@property (nonatomic) BOOL isDisabled;
@property (nonatomic, weak) UIWindow *window;

@property (nonatomic) NSMutableSet *collectedASLMessageIDs;
@property (nonatomic) NSMutableArray *consoleMessages;

@property (nonatomic) dispatch_queue_t logQueue;
@end

@implementation BugshotKit

+ (instancetype)sharedManager
{
    static dispatch_once_t onceToken;
    static BugshotKit *sharedManager;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

+ (void)enableWithNumberOfTouches:(NSUInteger)fingerCount performingGestures:(BSKInvocationGesture)invocationGestures feedbackEmailAddress:(NSString *)toEmailAddress extraInfoBlock:(NSDictionary *(^)())extraInfoBlock;
{
    [BugshotKit.sharedManager attachWithumberOfTouches:fingerCount invocationGestures:invocationGestures];
    BugshotKit.sharedManager.destinationEmailAddress = toEmailAddress;
    BugshotKit.sharedManager.extraInfoBlock = extraInfoBlock;
}

+ (void)show
{
    [BugshotKit.sharedManager handleOpenGesture:nil];
}

+ (UIFont *)consoleFontWithSize:(CGFloat)size
{
    static dispatch_once_t onceToken;
    static NSString *consoleFontName;
    dispatch_once(&onceToken, ^{
        consoleFontName = nil;

        NSData *inData = [NSData dataWithContentsOfFile:[NSBundle.mainBundle.resourcePath stringByAppendingPathComponent:@"Inconsolata.otf"]];
        CFErrorRef error;
        CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)inData);
        CGFontRef font = CGFontCreateWithDataProvider(provider);
        if (CTFontManagerRegisterGraphicsFont(font, &error)) {
            if ([UIFont fontWithName:@"Inconsolata" size:size]) consoleFontName = @"Inconsolata";
            else NSLog(@"[BugshotKit] failed to instantiate console font");
        } else {
            CFStringRef errorDescription = CFErrorCopyDescription(error);
            NSLog(@"[BugshotKit] failed to load console font: %@", errorDescription);
            CFRelease(errorDescription);
        }
        CFRelease(font);
        CFRelease(provider);

        if (! consoleFontName) consoleFontName = @"CourierNewPSMT";
    });
    
    return [UIFont fontWithName:consoleFontName size:size];
}

- (instancetype)init
{
    if ( (self = [super init]) ) {

#if ! (TARGET_IPHONE_SIMULATOR)
        if ([self.class isProbablyAppStoreBuild]) {
            self.isDisabled = YES;
            NSLog(@"[BugshotKit] App Store build detected. BugshotKit is disabled.");
            return self;
        }
#endif

        self.annotationFillColor = [UIColor colorWithRed:1.0f green:0.2196f blue:0.03922f alpha:1.0f]; // Bugshot red-orange
        self.annotationStrokeColor = [UIColor whiteColor];
        
        self.toggleOnColor = [UIColor colorWithRed:0.533f green:0.835f blue:0.412f alpha:1.0f]; // iOS 7 green
        self.toggleOffColor = [UIColor colorWithRed:184/255.0f green:184/255.0f blue:191/255.0f alpha:1.0f]; // iOS 7ish light gray
        
        self.collectedASLMessageIDs = [NSMutableSet set];
        self.consoleMessages = [NSMutableArray array];
        self.logQueue = dispatch_queue_create("BugshotKit logging", NULL);
        
        self.consoleLogMaxLines = 500;
        
        // Notify on every write to stderr (so we can track NSLog real-time, without polling, when a console is showing)
        source = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE, fileno(stderr), DISPATCH_VNODE_WRITE, dispatch_get_main_queue());
        __weak BugshotKit *weakSelf = self;
        dispatch_source_set_event_handler(source, ^{
            if (weakSelf.isShowing) {
                dispatch_async(dispatch_get_main_queue(),^{
                    [weakSelf updateFromASL];
                });
            }
        });
        dispatch_resume(source);
    }
    return self;
}

- (void)dealloc
{
    if (! self.isDisabled) {
        dispatch_source_cancel(source);
    }
}

- (BOOL)isShowing { return isShowing; }

- (void)attachWithumberOfTouches:(NSUInteger)fingerCount invocationGestures:(BSKInvocationGesture)invocationGestures
{
    if (self.isDisabled) return;
    
    // dispatched to next main-thread loop so the app delegate has a chance to set up its window
    dispatch_async(dispatch_get_main_queue(), ^{
        self.window = UIApplication.sharedApplication.keyWindow;
        if (! self.window) self.window = UIApplication.sharedApplication.windows.lastObject;
        if (! self.window) [[NSException exceptionWithName:NSGenericException reason:@"BugshotKit cannot find any application windows" userInfo:nil] raise];
        if (! self.window.rootViewController) [[NSException exceptionWithName:NSGenericException reason:@"BugshotKit requires a rootViewController set on the window" userInfo:nil] raise];

        if (invocationGestures & BSKInvocationGestureSwipeUp) {
            UISwipeGestureRecognizer *sgr = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleOpenGesture:)];
            sgr.numberOfTouchesRequired = fingerCount;
            sgr.direction = UISwipeGestureRecognizerDirectionUp;
            sgr.delegate = self;
            [self.window addGestureRecognizer:sgr];
            NSLog(@"[BugshotKit] Enabled for %d-finger swipe up.", (int) fingerCount);
        }

        if (invocationGestures & BSKInvocationGestureSwipeDown) {
            UISwipeGestureRecognizer *sgr = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleOpenGesture:)];
            sgr.numberOfTouchesRequired = fingerCount;
            sgr.direction = UISwipeGestureRecognizerDirectionDown;
            sgr.delegate = self;
            [self.window addGestureRecognizer:sgr];
            NSLog(@"[BugshotKit] Enabled for %d-finger swipe down.", (int) fingerCount);
        }

        if (invocationGestures & BSKInvocationGestureSwipeFromRightEdge) {
            UIScreenEdgePanGestureRecognizer *egr = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(handleOpenGesture:)];
            egr.edges = UIRectEdgeRight;
            egr.minimumNumberOfTouches = fingerCount;
            egr.maximumNumberOfTouches = fingerCount;
            egr.delegate = self;
            [self.window addGestureRecognizer:egr];
            NSLog(@"[BugshotKit] Enabled for swipe from right edge.");
        }

        if (invocationGestures & BSKInvocationGestureDoubleTap) {
            UITapGestureRecognizer *tgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleOpenGesture:)];
            tgr.numberOfTouchesRequired = fingerCount;
            tgr.numberOfTapsRequired = 2;
            tgr.delegate = self;
            [self.window addGestureRecognizer:tgr];
            NSLog(@"[BugshotKit] Enabled for %d-finger double-tap.", (int) fingerCount);
        }

        if (invocationGestures & BSKInvocationGestureTripleTap) {
            UITapGestureRecognizer *tgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleOpenGesture:)];
            tgr.numberOfTouchesRequired = fingerCount;
            tgr.numberOfTapsRequired = 3;
            tgr.delegate = self;
            [self.window addGestureRecognizer:tgr];
            NSLog(@"[BugshotKit] Enabled for %d-finger triple-tap.", (int) fingerCount);
        }
    });
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer { return YES; }

- (void)handleOpenGesture:(UIGestureRecognizer *)sender
{
    if (isShowing) return;
    if (sender && [sender isKindOfClass:UIPanGestureRecognizer.class] && [((UIPanGestureRecognizer *)sender) translationInView:self.window].x > -60) return;

    isShowing = YES;

    UIGraphicsBeginImageContextWithOptions(self.window.bounds.size, YES, UIScreen.mainScreen.scale);
    [self.window drawViewHierarchyInRect:self.window.bounds afterScreenUpdates:NO];
    self.snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    BSKMainViewController *mvc = [[BSKMainViewController alloc] init];
    mvc.delegate = self;
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:mvc];
    nc.navigationBar.tintColor = BugshotKit.sharedManager.annotationFillColor;
    
    UIViewController *presentingViewController = self.window.rootViewController;
    while (presentingViewController.presentedViewController) presentingViewController = presentingViewController.presentedViewController;
    
    [presentingViewController presentViewController:nc animated:YES completion:NULL];
}

- (void)mainViewControllerDidClose:(BSKMainViewController *)mainViewController
{
    isShowing = NO;
    self.snapshotImage = nil;
    self.annotatedImage = nil;
    self.annotations = nil;
}

#pragma mark - Console logging

- (NSString *)currentConsoleLogWithDateStamps:(BOOL)dateStamps
{
    NSMutableString *string = [NSMutableString string];

    dispatch_sync(self.logQueue, ^{
        [self updateFromASL];

        if (consoleMessagesNeedSorting) {
            [self.consoleMessages sortUsingComparator:^NSComparisonResult(BSKLogMessage *m1, BSKLogMessage *m2) {
                if (m1.timestamp == m2.timestamp) return NSOrderedSame;
                return m1.timestamp < m2.timestamp ? NSOrderedAscending : NSOrderedDescending;
            }];
            consoleMessagesNeedSorting = NO;
        }
        
        char fdate[24];
        for (BSKLogMessage *msg in self.consoleMessages) {
            if (dateStamps) {
                time_t timestamp = (time_t) msg.timestamp;
                struct tm *lt = localtime(&timestamp);
                strftime(fdate, 24, "%Y-%m-%d %T", lt);
                [string appendFormat:@"%s.%03d %@\n", fdate, (int) (1000.0 * (msg.timestamp - floor(msg.timestamp))), msg.message];
            } else {
                [string appendFormat:@"%@\n", msg.message];
            }
        }
    });
    
    return string;
}

- (void)clearLog
{
    if (self.isDisabled) return;
    
    [self.consoleMessages removeAllObjects];
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSNotificationCenter.defaultCenter postNotificationName:BSKNewLogMessageNotification object:nil];
    });
}

+ (void)addLogMessage:(NSString *)message
{
    BugshotKit *manager = BugshotKit.sharedManager;
    if (manager.isDisabled) return;
    
    dispatch_async(manager.logQueue, ^{
        [manager addLogMessage:message timestamp:[NSDate date].timeIntervalSince1970 fromASL:NO];
        dispatch_async(dispatch_get_main_queue(), ^{
            [NSNotificationCenter.defaultCenter postNotificationName:BSKNewLogMessageNotification object:nil];
        });
    });
}

// assumed to always be in logQueue
- (void)addLogMessage:(NSString *)message timestamp:(NSTimeInterval)timestamp fromASL:(BOOL)fromASL
{
    BSKLogMessage *msg = [BSKLogMessage new];
    msg.message = message;
    msg.timestamp = timestamp;
    [self.consoleMessages addObject:msg];
    
    // once the log has exceeded the length limit by 25%, prune it to the length limit
    if (self.consoleMessages.count > self.consoleLogMaxLines * 1.25) {
        [self.consoleMessages removeObjectsInRange:NSMakeRange(0, self.consoleMessages.count - self.consoleLogMaxLines)];
    }
    
    if (! fromASL) consoleMessagesNeedSorting = YES;
}

// assumed to always be in logQueue
- (void)updateFromASL
{
    pid_t myPID = getpid();

    // thanks http://www.cocoanetics.com/2011/03/accessing-the-ios-system-log/
    
    aslmsg q, m;
    q = asl_new(ASL_TYPE_QUERY);
    aslresponse r = asl_search(NULL, q);
    BOOL foundNewEntries = NO;
    
    while ( (m = aslresponse_next(r)) ) {
        if (myPID != atol(asl_get(m, ASL_KEY_PID))) continue;

        // dupe checking
        NSNumber *msgID = @( atoll(asl_get(m, ASL_KEY_MSG_ID)) );
        if ([_collectedASLMessageIDs containsObject:msgID]) continue;
        [_collectedASLMessageIDs addObject:msgID];
        foundNewEntries = YES;
        
        NSTimeInterval msgTime = (NSTimeInterval) atol(asl_get(m, ASL_KEY_TIME)) + ((NSTimeInterval) atol(asl_get(m, ASL_KEY_TIME_NSEC)) / 1000000000.0);
        [self addLogMessage:[NSString stringWithUTF8String:asl_get(m, ASL_KEY_MSG)] timestamp:msgTime fromASL:YES];
    }
    
    aslresponse_free(r);
    asl_free(q);

    if (foundNewEntries) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [NSNotificationCenter.defaultCenter postNotificationName:BSKNewLogMessageNotification object:nil];
        });
    }
}

#pragma mark - App Store build detection

+ (BOOL)isProbablyAppStoreBuild
{
    // Adapted from https://github.com/blindsightcorp/BSMobileProvision
    
    NSString *binaryMobileProvision = [NSString stringWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"embedded" ofType:@"mobileprovision"] encoding:NSISOLatin1StringEncoding error:NULL];
    if (! binaryMobileProvision) return YES; // no provision

    NSScanner *scanner = [NSScanner scannerWithString:binaryMobileProvision];
    NSString *plistString;
    if (! [scanner scanUpToString:@"<plist" intoString:nil] || ! [scanner scanUpToString:@"</plist>" intoString:&plistString]) return YES; // no XML plist found in provision
    plistString = [plistString stringByAppendingString:@"</plist>"];

    NSData *plistdata_latin1 = [plistString dataUsingEncoding:NSISOLatin1StringEncoding];
    NSError *error = nil;
    NSDictionary *mobileProvision = [NSPropertyListSerialization propertyListWithData:plistdata_latin1 options:NSPropertyListImmutable format:NULL error:&error];
    if (error) return YES; // unknown plist format

    if (! mobileProvision || ! mobileProvision.count) return YES; // no entitlements
    
    if (mobileProvision[@"ProvisionsAllDevices"]) return NO; // enterprise provisioning
    
    if (mobileProvision[@"ProvisionedDevices"] && ((NSDictionary *)mobileProvision[@"ProvisionedDevices"]).count) return NO; // development or ad-hoc

    return YES; // expected development/enterprise/ad-hoc entitlements not found
}


@end
