//  BSKLogViewController.m
//  See included LICENSE file for the (MIT) license.
//  Created by Marco Arment on 1/17/14.

#import "BSKLogViewController.h"
#import "BugshotKit.h"

@interface BSKLogViewController ()
@property (nonatomic) UITextView *textView;
@end

static int markerNumber = 0;

@implementation BSKLogViewController

- (instancetype)init
{
    if ( (self = [super init]) ) {
        self.title = @"Debug Log";
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addMarkerButtonTapped:)];
    }
    return self;
}

- (void)addMarkerButtonTapped:(id)sender
{
    [BugshotKit addLogMessage:[NSString stringWithFormat:@"----------- marker #%d -----------", markerNumber]];
    markerNumber++;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self updateText:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(updateText:) name:BSKNewLogMessageNotification object:nil];
}

- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self name:BSKNewLogMessageNotification object:nil];
}

- (void)loadView
{
    CGRect frame = UIScreen.mainScreen.applicationFrame;
    frame.origin = CGPointZero;
    UIView *view = [[UIView alloc] initWithFrame:frame];
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    view.autoresizesSubviews = YES;
    
    self.textView = [[UITextView alloc] initWithFrame:frame];
    self.textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.textView.font = [BugshotKit consoleFontWithSize:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 13.0f : 9.0f)];
    self.textView.editable = NO;
    [view addSubview:self.textView];
    
    self.view = view;
}

- (void)updateText:(NSNotification *)n
{
    NSMutableString *text = [[BugshotKit.sharedManager currentConsoleLogWithDateStamps:NO] mutableCopy];
    [text appendString:@"\n\n"];
    self.textView.text = text;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.textView scrollRangeToVisible:NSMakeRange(self.textView.text.length - 1, 1)];
    });
}

@end
