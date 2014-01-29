//  BSKMainViewController.m
//  See included LICENSE file for the (MIT) license.
//  Created by Marco Arment on 1/17/14.

#import "BSKMainViewController.h"
#import "BugshotKit.h"
#import "BSKLogViewController.h"
#import "BSKScreenshotViewController.h"
#import "BSKToggleButton.h"
#import <QuartzCore/QuartzCore.h>
#import <unistd.h>
#include <sys/types.h>
#include <sys/sysctl.h>

static UIImage *rotateIfNeeded(UIImage *src);

@interface BSKMainViewController ()
@property (nonatomic) BSKToggleButton *includeScreenshotToggle;
@property (nonatomic) BSKToggleButton *includeLogToggle;
@property (nonatomic) UIButton *screenshotView;
@property (nonatomic) UIImageView *screenshotAccessoryView;
@property (nonatomic) UIButton *consoleView;
@property (nonatomic) UIImageView *consoleAccessoryView;
@property (nonatomic) UILabel *screenshotLabel;
@property (nonatomic) UILabel *consoleLabel;
@property (nonatomic) NSURLSession *urlSession;
@property (nonatomic) BOOL sendingToServer;
@end

@implementation BSKMainViewController

- (BOOL)shouldAutorotate { return NO; }

- (instancetype)init
{
    if ( (self = [super initWithStyle:UITableViewStyleGrouped]) ) {
        [BugshotKit.sharedManager addObserver:self forKeyPath:@"annotatedImage" options:0 context:NULL];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(updateLiveLog:) name:BSKNewLogMessageNotification object:nil];

        self.title = @"Bugshot";
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonTapped:)];
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    }
    return self;
}

- (void)dealloc
{
    [BugshotKit.sharedManager removeObserver:self forKeyPath:@"annotatedImage"];
    [NSNotificationCenter.defaultCenter removeObserver:self name:BSKNewLogMessageNotification object:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    CGSize chevronSize = CGSizeMake(15, 30);
    UIImage *chevronImage = BSKImageWithDrawing(chevronSize, ^{
        CGRect chevronBounds = CGRectMake(0, 0, chevronSize.width, chevronSize.height);
        chevronBounds = CGRectInset(chevronBounds, 3.0f, 6.0f);
        
        UIBezierPath *path = [UIBezierPath bezierPath];
        [path moveToPoint:CGPointMake(chevronBounds.origin.x, chevronBounds.origin.y)];
        [path addLineToPoint:CGPointMake(chevronBounds.origin.x + chevronBounds.size.width, chevronBounds.origin.y + (chevronBounds.size.height / 2.0f))];
        [path addLineToPoint:CGPointMake(chevronBounds.origin.x, chevronBounds.origin.y + chevronBounds.size.height)];
        [path setLineWidth:ceilf((float)chevronSize.width * 0.2f)];
        [BugshotKit.sharedManager.toggleOffColor setStroke];
        [path stroke];
    });

    UIImage *screenshotImage = (BugshotKit.sharedManager.annotatedImage ?: BugshotKit.sharedManager.snapshotImage);

    CGFloat maxHeaderHeight =
        UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? (UIInterfaceOrientationIsPortrait(self.interfaceOrientation) ? 570 : 480) :
        UIInterfaceOrientationIsPortrait(self.interfaceOrientation) ? (UIScreen.mainScreen.bounds.size.height < 568 ? 300 : 340) : 220
    ;
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, maxHeaderHeight)];
    
    UIView *screenshotContainer = [UIView new];
    screenshotContainer.translatesAutoresizingMaskIntoConstraints = NO;
    
    UIView *consoleContainer = [UIView new];
    consoleContainer.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.screenshotLabel = [UILabel new];
    self.screenshotLabel.text = @"SCREENSHOT";
    self.screenshotLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
    self.screenshotLabel.textColor = BugshotKit.sharedManager.annotationFillColor;
    self.screenshotLabel.textAlignment = NSTextAlignmentCenter;
    self.screenshotLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [screenshotContainer addSubview:self.screenshotLabel];
    
    self.consoleLabel = [UILabel new];
    self.consoleLabel.text = @"LOG";
    self.consoleLabel.font = self.screenshotLabel.font;
    self.consoleLabel.textAlignment = self.screenshotLabel.textAlignment;
    self.consoleLabel.textColor = self.screenshotLabel.textColor;
    self.consoleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [consoleContainer addSubview:self.consoleLabel];
    
    CGFloat toggleWidth = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && UIInterfaceOrientationIsLandscape(self.interfaceOrientation) ? 44 : 74;
    
    self.includeScreenshotToggle = [[BSKToggleButton alloc] initWithFrame:CGRectMake(0, 0, toggleWidth, toggleWidth)];
    self.includeScreenshotToggle.on = YES;
    [self.includeScreenshotToggle addTarget:self action:@selector(includeScreenshotToggled:) forControlEvents:UIControlEventValueChanged];
    self.includeScreenshotToggle.translatesAutoresizingMaskIntoConstraints = NO;
    self.includeScreenshotToggle.accessibilityLabel = @"Include screenshot";
    [screenshotContainer addSubview:self.includeScreenshotToggle];

    self.includeLogToggle = [[BSKToggleButton alloc] initWithFrame:CGRectMake(0, 0, toggleWidth, toggleWidth)];
    self.includeLogToggle.on = YES;
    [self.includeLogToggle addTarget:self action:@selector(includeLogToggled:) forControlEvents:UIControlEventValueChanged];
    self.includeLogToggle.translatesAutoresizingMaskIntoConstraints = NO;
    self.includeLogToggle.accessibilityLabel = @"Include log";
    [consoleContainer addSubview:self.includeLogToggle];
    
    self.screenshotView = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.screenshotView addTarget:self action:@selector(openScreenshotEditor:) forControlEvents:UIControlEventTouchUpInside];
    [self.screenshotView setBackgroundImage:screenshotImage forState:UIControlStateNormal];
    self.screenshotView.translatesAutoresizingMaskIntoConstraints = NO;
    self.screenshotView.layer.borderColor = BugshotKit.sharedManager.annotationFillColor.CGColor;
    self.screenshotView.layer.borderWidth = 1.0f;
    self.screenshotView.accessibilityLabel = @"Annotate screenshot";
    [screenshotContainer addSubview:self.screenshotView];

    self.consoleView = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.consoleView addTarget:self action:@selector(openConsoleViewer:) forControlEvents:UIControlEventTouchUpInside];
    self.consoleView.translatesAutoresizingMaskIntoConstraints = NO;
    self.consoleView.layer.borderColor = BugshotKit.sharedManager.annotationFillColor.CGColor;
    self.consoleView.layer.borderWidth = 1.0f;
    self.consoleView.accessibilityLabel = @"View log";
    self.consoleView.backgroundColor = UIColor.whiteColor;
    [consoleContainer addSubview:self.consoleView];
    
    self.screenshotAccessoryView = [[UIImageView alloc] initWithImage:chevronImage];
    self.screenshotAccessoryView.translatesAutoresizingMaskIntoConstraints = NO;
    self.screenshotAccessoryView.isAccessibilityElement = NO;
    [screenshotContainer addSubview:self.screenshotAccessoryView];

    self.consoleAccessoryView = [[UIImageView alloc] initWithImage:chevronImage];
    self.consoleAccessoryView.translatesAutoresizingMaskIntoConstraints = NO;
    self.consoleAccessoryView.isAccessibilityElement = NO;
    [consoleContainer addSubview:self.consoleAccessoryView];

    // Make both images match the screenshot's aspect ratio (and lock its ratio)
    CGSize imageSize = screenshotImage.size;
    CGFloat imageAspect = imageSize.width / imageSize.height;
    [screenshotContainer addConstraint:[NSLayoutConstraint
        constraintWithItem:self.screenshotView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.screenshotView attribute:NSLayoutAttributeHeight multiplier:imageAspect constant:0
    ]];
    [consoleContainer addConstraint:[NSLayoutConstraint
        constraintWithItem:self.consoleView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.consoleView attribute:NSLayoutAttributeHeight multiplier:imageAspect constant:0
    ]];
    
    void (^layoutScreenshotUnit)(UIView *container, NSDictionary *views) = ^(UIView *container, NSDictionary *views){
        NSDictionary *metrics = @{
            @"aw" : @(chevronSize.width), @"ah" : @(chevronSize.height), @"apad" : @(chevronSize.width + 5.0f),
            @"lfont" : @( ((UILabel *)views[@"label"]).font.pointSize ),
            @"padImageHeight" : @(384)
        };
    
        [container addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-15-[label(>=lfont)]-5-[image]-15-[toggle]" options:0 metrics:metrics views:views]];
        [container addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[accessory(==aw)]|" options:0 metrics:metrics views:views]];
        [container addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[accessory(==ah)]" options:0 metrics:metrics views:views]];
        [container addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[label]|" options:0 metrics:nil views:views]];
        [container addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-apad-[image]-apad-|" options:0 metrics:metrics views:views]];
        [container addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[toggle]-15-|" options:0 metrics:nil views:views]];

        // horizontally center toggle
        [container addConstraint:[NSLayoutConstraint
            constraintWithItem:views[@"toggle"] attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:container attribute:NSLayoutAttributeCenterX multiplier:1 constant:0
        ]];
        
        // vertically center accessory to image
        [container addConstraint:[NSLayoutConstraint
            constraintWithItem:views[@"accessory"] attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:views[@"image"] attribute:NSLayoutAttributeCenterY multiplier:1 constant:0
        ]];
        
        // toggle is always square
        [container addConstraint:[NSLayoutConstraint
            constraintWithItem:views[@"toggle"] attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:views[@"toggle"] attribute:NSLayoutAttributeWidth multiplier:1 constant:0
        ]];
    };
    
    layoutScreenshotUnit(screenshotContainer, @{
        @"label" : self.screenshotLabel,
        @"image" : self.screenshotView,
        @"accessory" : self.screenshotAccessoryView,
        @"toggle" : self.includeScreenshotToggle
    });

    layoutScreenshotUnit(consoleContainer, @{
        @"label" : self.consoleLabel,
        @"image" : self.consoleView,
        @"accessory" : self.consoleAccessoryView,
        @"toggle" : self.includeLogToggle
    });

    [headerView addSubview:screenshotContainer];
    [headerView addSubview:consoleContainer];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(screenshotContainer, consoleContainer);
    [headerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[screenshotContainer]|" options:0 metrics:nil views:views]];
    [headerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[consoleContainer]|" options:0 metrics:nil views:views]];
    
    [headerView addConstraint:[NSLayoutConstraint
        constraintWithItem:screenshotContainer attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationLessThanOrEqual toItem:headerView attribute:NSLayoutAttributeCenterX multiplier:1 constant:0
    ]];
    [headerView addConstraint:[NSLayoutConstraint
        constraintWithItem:consoleContainer attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationLessThanOrEqual toItem:headerView attribute:NSLayoutAttributeCenterX multiplier:1 constant:0
    ]];

    [headerView addConstraint:[NSLayoutConstraint
        constraintWithItem:screenshotContainer attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:consoleContainer attribute:NSLayoutAttributeWidth multiplier:1 constant:0
    ]];

    [headerView sizeToFit];
    self.tableView.tableHeaderView = headerView;

    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateLiveLog:nil];
    });
}

- (void)openScreenshotEditor:(id)sender
{
    [self.navigationController pushViewController:[[BSKScreenshotViewController alloc] initWithImage:BugshotKit.sharedManager.snapshotImage annotations:BugshotKit.sharedManager.annotations] animated:YES];
}

- (void)openConsoleViewer:(id)sender
{
    [self.navigationController pushViewController:[[BSKLogViewController alloc] init] animated:YES];
}

- (void)includeScreenshotToggled:(id)sender
{
    if (self.includeScreenshotToggle.on) {
        self.screenshotLabel.textColor = BugshotKit.sharedManager.annotationFillColor;
        self.screenshotView.layer.borderColor = BugshotKit.sharedManager.annotationFillColor.CGColor;
    } else {
        self.screenshotLabel.textColor = BugshotKit.sharedManager.toggleOffColor;
        self.screenshotView.layer.borderColor = BugshotKit.sharedManager.toggleOffColor.CGColor;
    }
}

- (void)includeLogToggled:(id)sender
{
    if (self.includeLogToggle.on) {
        self.consoleLabel.textColor = BugshotKit.sharedManager.annotationFillColor;
        self.consoleView.layer.borderColor = BugshotKit.sharedManager.annotationFillColor.CGColor;
    } else {
        self.consoleLabel.textColor = BugshotKit.sharedManager.toggleOffColor;
        self.consoleView.layer.borderColor = BugshotKit.sharedManager.toggleOffColor.CGColor;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (! self.isViewLoaded) return;
    [self.screenshotView setBackgroundImage:(BugshotKit.sharedManager.annotatedImage ?: BugshotKit.sharedManager.snapshotImage) forState:UIControlStateNormal];
}

- (void)cancelButtonTapped:(id)sender
{
    if (self.sendingToServer) {
        [self.urlSession invalidateAndCancel];
    } else {
        [self.navigationController.presentingViewController dismissViewControllerAnimated:YES completion:^{
            if (self.delegate) [self.delegate mainViewControllerDidClose:self];
        }];
    }
}

- (void)consoleButtonTapped:(id)sender
{
    [self.navigationController pushViewController:[[BSKLogViewController alloc] init] animated:YES];
}

- (void)sendButtonTapped:(id)sender
{
    if (self.includeLogToggle.on) {
        [BugshotKit.sharedManager currentConsoleLogWithDateStamps:YES withCompletion:^(NSString *result) {
            [self sendButtonTappedWithLog:result];
        }];
    }
    else {
        [self sendButtonTappedWithLog:nil];
    }
}

- (void)sendButtonTappedWithLog:(NSString *)log
{
    UIImage *screenshot = self.includeScreenshotToggle.on ? (BugshotKit.sharedManager.annotatedImage ?: BugshotKit.sharedManager.snapshotImage) : nil;
    if (log && ! log.length) log = nil;
    
    NSString *appNameString = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    NSString *appVersionString = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleVersion"];

    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0); 
    char *name = malloc(size);
    sysctlbyname("hw.machine", name, &size, NULL, 0);
    NSString *modelIdentifier = [NSString stringWithCString:name encoding:NSUTF8StringEncoding];
    free(name);

    NSDictionary *userInfo = @{
        @"appName" : appNameString,
        @"appVersion" : appVersionString,
        @"systemVersion" : UIDevice.currentDevice.systemVersion,
        @"deviceModel" : modelIdentifier,
    };
    
    NSDictionary *extraUserInfo = BugshotKit.sharedManager.extraInfoBlock ? BugshotKit.sharedManager.extraInfoBlock() : nil;
    if (extraUserInfo) {
        userInfo = userInfo.mutableCopy;
        [(NSMutableDictionary *)userInfo addEntriesFromDictionary:extraUserInfo];
    };
    
    NSData *userInfoJSON = [NSJSONSerialization dataWithJSONObject:userInfo options:NSJSONWritingPrettyPrinted error:NULL];
   
    if (BugshotKit.sharedManager.sendMode == BSKSendModeEmail) {
        
        MFMailComposeViewController *mf = [MFMailComposeViewController canSendMail] ? [[MFMailComposeViewController alloc] init] : nil;
        if (! mf) {
            NSString *msg = [NSString stringWithFormat:@"Mail is not configured on your %@.", UIDevice.currentDevice.localizedModel];
            [[[UIAlertView alloc] initWithTitle:@"Cannot Send Mail" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            return;
        }
        
        mf.toRecipients = [BugshotKit.sharedManager.destinationEmailAddress componentsSeparatedByString:@","];
        mf.subject = BugshotKit.sharedManager.emailSubjectBlock ? BugshotKit.sharedManager.emailSubjectBlock(userInfo) : [NSString stringWithFormat:@"%@ %@ Feedback", appNameString, appVersionString];
        [mf setMessageBody:BugshotKit.sharedManager.emailBodyBlock ? BugshotKit.sharedManager.emailBodyBlock(userInfo) : nil isHTML:NO];
        
        if (screenshot) [mf addAttachmentData:UIImagePNGRepresentation(rotateIfNeeded(screenshot)) mimeType:@"image/png" fileName:@"screenshot.png"];
        if (log) [mf addAttachmentData:[log dataUsingEncoding:NSUTF8StringEncoding] mimeType:@"text/plain" fileName:@"log.txt"];
        if (userInfoJSON) [mf addAttachmentData:userInfoJSON mimeType:@"application/json" fileName:@"info.json"];
        
        mf.mailComposeDelegate = self;
        [self presentViewController:mf animated:YES completion:NULL];
       
        
    } else if (BugshotKit.sharedManager.sendMode == BSKSendModeURL) {
        
        self.sendingToServer = YES;
        
        NSError *error;
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        if (self.urlSession) self.urlSession = nil;
        self.urlSession = [NSURLSession sessionWithConfiguration:configuration];
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:BugshotKit.sharedManager.destinationURL
                                                               cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                           timeoutInterval:60.0];
        
        for (NSString *key in BugshotKit.sharedManager.destinationURLHeaderFields.allKeys) {
            NSString *value = [BugshotKit.sharedManager.destinationURLHeaderFields valueForKey:key];
            [request addValue:value forHTTPHeaderField:key];
        }
        [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setHTTPMethod:@"POST"];
        
        if (screenshot) {
            NSData *screenshotData = UIImageJPEGRepresentation(rotateIfNeeded(screenshot), 1.0);
            NSString *screenshotDataString = [self base64forData:screenshotData];
            NSDictionary *screenshotInfo = @{@"screenshot": screenshotDataString};
            userInfo = userInfo.mutableCopy;
            [(NSMutableDictionary *)userInfo addEntriesFromDictionary:screenshotInfo];
        }

        if (log) {
            NSDictionary *logInfo = @{@"log": log};
            userInfo = userInfo.mutableCopy;
            [(NSMutableDictionary *)userInfo addEntriesFromDictionary:logInfo];
        }

        NSData *postData = [NSJSONSerialization dataWithJSONObject:userInfo options:0 error:&error];
        [request setHTTPBody:postData];
        
        NSURLSessionDataTask *postDataTask = [self.urlSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            
            self.sendingToServer = NO;
            if (!error) {
                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                int code = (int)httpResponse.statusCode;
                
                if (code >= 200 && code <= 299) {
                    [self cancelButtonTapped:nil];
                } else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSString *responseString = [NSHTTPURLResponse localizedStringForStatusCode:httpResponse.statusCode];
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:responseString delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                        [alert show];
                    });
                }
                
            } else {
                NSString *errorString = error.localizedDescription;
                if (![errorString isEqualToString:@"cancelled"]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:error.localizedDescription delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                        [alert show];
                    });
                }
            }
        }];
        [postDataTask resume];
    }
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    [self dismissViewControllerAnimated:YES completion:^{
        if (result == MFMailComposeResultSaved || result == MFMailComposeResultSent) [self cancelButtonTapped:nil];
    }];
}

- (void)setSendingToServer:(BOOL)sendingToServer
{
    dispatch_async(dispatch_get_main_queue(), ^{
        _sendingToServer = sendingToServer;
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForItem:0 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
    });
}


#pragma mark - Table junk

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 1; }

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return 1; }

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    cell.textLabel.textColor = BugshotKit.sharedManager.annotationFillColor;
    
    switch (BugshotKit.sharedManager.sendMode) {
        case BSKSendModeEmail:
            cell.textLabel.text = @"Compose Email…";
            break;
        case BSKSendModeURL:
            cell.textLabel.text = [NSString stringWithFormat:@"%@", self.sendingToServer ? @"Sending..." : @"Send"];
            break;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.sendingToServer) return;
    [self sendButtonTapped:nil];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Live console image

- (void)updateLiveLog:(NSNotification *)n
{
    if (! self.isViewLoaded) return;
    [BugshotKit.sharedManager consoleImageWithSize:self.consoleView.bounds.size fontSize:7 emptyBottomLine:NO withCompletion:^(UIImage *image) {
        [self.consoleView setBackgroundImage:image forState:UIControlStateNormal];
    }];
}


#pragma mark - Encoding

- (NSString*)base64forData:(NSData*)theData
{
    const uint8_t* input = (const uint8_t*)[theData bytes];
    NSInteger length = [theData length];
    
    static char table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";
    
    NSMutableData* data = [NSMutableData dataWithLength:((length + 2) / 3) * 4];
    uint8_t* output = (uint8_t*)data.mutableBytes;
    
    NSInteger i;
    for (i=0; i < length; i += 3) {
        NSInteger value = 0;
        NSInteger j;
        for (j = i; j < (i + 3); j++) {
            value <<= 8;
            
            if (j < length) {
                value |= (0xFF & input[j]);
            }
        }
        
        NSInteger theIndex = (i / 3) * 4;
        output[theIndex + 0] =                    table[(value >> 18) & 0x3F];
        output[theIndex + 1] =                    table[(value >> 12) & 0x3F];
        output[theIndex + 2] = (i + 1) < length ? table[(value >> 6)  & 0x3F] : '=';
        output[theIndex + 3] = (i + 2) < length ? table[(value >> 0)  & 0x3F] : '=';
    }
    
    return [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
}

@end


// By Matteo Gavagnin on 21/01/14.
static UIImage *rotateIfNeeded(UIImage *src)
{
    if (src.imageOrientation == UIImageOrientationDown && src.size.width < src.size.height) {
        UIGraphicsBeginImageContext(src.size);
        [src drawAtPoint:CGPointMake(0, 0)];
        return UIGraphicsGetImageFromCurrentImageContext();
    } else if ((src.imageOrientation == UIImageOrientationLeft || src.imageOrientation == UIImageOrientationRight) && src.size.width > src.size.height) {
        UIGraphicsBeginImageContext(src.size);
        [src drawAtPoint:CGPointMake(0, 0)];
        return UIGraphicsGetImageFromCurrentImageContext();
    } else {
        return src;
    }
}
