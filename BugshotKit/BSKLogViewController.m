//  BSKLogViewController.m
//  See included LICENSE file for the (MIT) license.
//  Created by Marco Arment on 1/17/14.

#import "BSKLogViewController.h"
#import "BugshotKit.h"

@interface BSKLogViewController ()
@property (nonatomic) UIImageView *consoleView;
@end

static int markerNumber = 0;

@implementation BSKLogViewController

- (instancetype)init
{
    if ( (self = [super init]) ) {
        self.title = @"Debug Log";
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addMarkerButtonTapped:)];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(updateLiveLog:) name:BSKNewLogMessageNotification object:nil];
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

    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[c]|" options:0 metrics:nil views:@{ @"c" : self.consoleView }]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[top][c]|" options:0 metrics:nil views:@{ @"c" : self.consoleView, @"top" : self.topLayoutGuide }]];

    dispatch_async(dispatch_get_main_queue(), ^{ [self updateLiveLog:nil]; });
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
    
    self.consoleView = [[UIImageView alloc] initWithFrame:frame];
    self.consoleView.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:self.consoleView];
    
    self.view = view;
}

- (void)updateLiveLog:(NSNotification *)n
{
    if (! self.isViewLoaded) return;
    [BugshotKit.sharedManager consoleImageWithSize:self.consoleView.bounds.size fontSize:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 13.0f : 9.0f) emptyBottomLine:YES withCompletion:^(UIImage *image) {
        self.consoleView.image = image;
    }];
}


@end
