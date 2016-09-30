//  BSKScreenshotViewController.m
//  See included LICENSE file for the (MIT) license.
//  Created by Marco Arment on 6/28/13.

#import "BSKScreenshotViewController.h"
#import "BugshotKit.h"
#import "BSKAnnotationBoxView.h"
#import "BSKAnnotationArrowView.h"
#import "BSKAnnotationBlurView.h"
#import <QuartzCore/QuartzCore.h>
#import "BSKCheckerboardView.h"

#define kAnnotationToolArrow 0
#define kAnnotationToolBox   1
#define kAnnotationToolBlur  2

#define kMaxAnnotationToolIndex 2

#define kGridOverlayOpacity 0.2f


@interface BSKScreenshotViewController () {
    BSKAnnotationView *annotationInProgress;
    int annotationToolChosen;
}

@property (nonatomic, retain) UIImage *screenshotImage;
@property (nonatomic, strong) UITapGestureRecognizer *contentAreaTapGestureRecognizer;
@property (nonatomic, strong) UIView *gridOverlay;
@property (nonatomic, copy) NSArray *annotationsToImport;

@end

@implementation BSKScreenshotViewController

- (id)initWithImage:(UIImage *)image annotations:(NSArray *)annotations
{
    if ( (self = [super init]) ) {
        self.screenshotImage = image;
        self.annotationsToImport = annotations;
        annotationInProgress = nil;
        
        CGSize arrowIconSize = CGSizeMake(19, 19);
        UIImage *arrowIcon = BSKImageWithDrawing(arrowIconSize, ^{
            [UIColor.blackColor setStroke];
            CGRect arrowRect = CGRectMake(0, 0, arrowIconSize.width, arrowIconSize.height);
            arrowRect = CGRectInset(arrowRect, 1.5f, 1.5f);
            
            UIBezierPath *path = [UIBezierPath bezierPath];
            [path moveToPoint:CGPointMake(arrowRect.origin.x, arrowRect.origin.y + arrowRect.size.height / 2.0f)];
            [path addLineToPoint:CGPointMake(arrowRect.origin.x + arrowRect.size.width, arrowRect.origin.y + arrowRect.size.height / 2.0f)];
            [path moveToPoint:CGPointMake(arrowRect.origin.x + 0.75f * arrowRect.size.width, arrowRect.origin.y + 0.25f * arrowRect.size.height)];
            [path addLineToPoint:CGPointMake(arrowRect.origin.x + arrowRect.size.width, arrowRect.origin.y + arrowRect.size.height / 2.0f)];
            [path addLineToPoint:CGPointMake(arrowRect.origin.x + 0.75f * arrowRect.size.width, arrowRect.origin.y + 0.75f * arrowRect.size.height)];
            [path stroke];
        });
        
        CGSize boxIconSize = CGSizeMake(19, 19);
        UIImage *boxIcon = BSKImageWithDrawing(boxIconSize, ^{
            [UIColor.blackColor setStroke];

            CGRect boxRect = CGRectMake(0, 0, boxIconSize.width, boxIconSize.height);
            boxRect = CGRectInset(boxRect, 2.5f, 2.5f);
            [[UIBezierPath bezierPathWithRoundedRect:boxRect cornerRadius:4.0f] stroke];
        });
        
        CGSize blurIconSize = CGSizeMake(20, 20);
        UIImage *blurIcon = BSKImageWithDrawing(blurIconSize, ^{
            [UIColor.blackColor setStroke];
            [UIColor.blackColor setFill];

            CGRect blurRect = CGRectMake(0, 0, blurIconSize.width, blurIconSize.height);
            blurRect = CGRectInset(blurRect, 2.5f, 2.5f);
            
            [[UIBezierPath bezierPathWithRect:blurRect] stroke];
            
            CGRect quarterRect = CGRectMake(blurRect.origin.x, blurRect.origin.y, blurRect.size.width / 2.0f, blurRect.size.height / 2.0f);
            [[UIBezierPath bezierPathWithRect:quarterRect] fill];
            quarterRect.origin.x += blurRect.size.width / 2.0f;
            quarterRect.origin.y += blurRect.size.width / 2.0f;
            [[UIBezierPath bezierPathWithRect:quarterRect] fill];
        });
        
        arrowIcon.accessibilityLabel = @"Arrow";
        boxIcon.accessibilityLabel   = @"Box";
        boxIcon.accessibilityLabel   = @"Blur";
        
        UISegmentedControl *annotationPicker = [[UISegmentedControl alloc] initWithItems:@[ arrowIcon, boxIcon, blurIcon ]];
        annotationPicker.accessibilityLabel = @"Drawing tool";
        annotationPicker.tintColor = BugshotKit.sharedManager.annotationFillColor;
        
        annotationToolChosen = kAnnotationToolArrow;
        annotationPicker.selectedSegmentIndex = annotationToolChosen;
        
        [annotationPicker setWidth:65.0f forSegmentAtIndex:kAnnotationToolArrow];
        [annotationPicker setWidth:65.0f forSegmentAtIndex:kAnnotationToolBox];
        [annotationPicker setWidth:65.0f forSegmentAtIndex:kAnnotationToolBlur];
        
        [self annotationPickerPicked:annotationPicker];
        [annotationPicker addTarget:self action:@selector(annotationPickerPicked:) forControlEvents:UIControlEventValueChanged];
        self.navigationItem.titleView = annotationPicker;

        self.contentAreaTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(contentAreaTapped:)];
    }
    return self;
}

- (void)loadView
{
    CGRect frame = UIScreen.mainScreen.applicationFrame;
    frame.origin = CGPointZero;
    UIView *view = [[UIView alloc] initWithFrame:frame];
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    view.autoresizesSubviews = YES;
    
    self.screenshotImageView = [[UIImageView alloc] initWithFrame:frame];
    self.screenshotImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.screenshotImageView.image = self.screenshotImage;
    [view addSubview:self.screenshotImageView];
    
    view.tintColor = BugshotKit.sharedManager.annotationFillColor;

    self.gridOverlay = [[BSKCheckerboardView alloc] initWithFrame:frame checkerSquareWidth:16.0f];
    _gridOverlay.opaque = NO;
    _gridOverlay.alpha = kGridOverlayOpacity;
    _gridOverlay.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    _gridOverlay.userInteractionEnabled = NO;
    [view addSubview:_gridOverlay];
    
    if (self.annotationsToImport) {
        for (UIView *annotation in self.annotationsToImport) [view addSubview:annotation];
    }
    
    view.multipleTouchEnabled = YES;
    [view addGestureRecognizer:self.contentAreaTapGestureRecognizer];
    
    self.view = view;
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.gridOverlay.hidden = YES;

    UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, YES, UIScreen.mainScreen.scale);
    // [self.view drawViewHierarchyInRect:self.view.bounds afterScreenUpdates:YES]; // doesn't work to hide the overlay; I guess I need renderInContext:. Ugh.
    [self.view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *annotatedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    self.gridOverlay.hidden = NO;

    NSMutableArray *savedAnnotations = [NSMutableArray array];
    for (UIView *annotation in self.view.subviews) {
        if ([annotation isKindOfClass:BSKAnnotationView.class]) [savedAnnotations addObject:annotation];
    }

    BugshotKit.sharedManager.annotations = savedAnnotations;
    BugshotKit.sharedManager.annotatedImage = annotatedImage;

    [super viewWillDisappear:animated];    
}

- (void)contentAreaTapped:(UITapGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateRecognized && ! UIAccessibilityIsVoiceOverRunning()) {
        BOOL hidden = ! self.navigationController.navigationBarHidden;
        [self.navigationController setNavigationBarHidden:hidden animated:YES];
        [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
            self.gridOverlay.alpha = hidden ? 0.0f : kGridOverlayOpacity;
        }];
    }
}

- (void)annotationPickerPicked:(UISegmentedControl *)sender
{
    annotationToolChosen = (int) sender.selectedSegmentIndex;
}

#pragma mark - Touch handling

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (touches.count == 1) {        
        UITouch *touch = touches.anyObject;
        
        if ([touch.view isKindOfClass:BSKAnnotationView.class]) {
            // Resizing or moving an existing annotation
        } else {
            // Creating a new annotation
            CGRect annotationFrame = {[touch locationInView:self.view], CGSizeMake(1, 1)};
            
            BOOL insertBelowCheckerboard = NO;
            
            if (annotationToolChosen == kAnnotationToolBox) {
                annotationInProgress = [[BSKAnnotationBoxView alloc] initWithFrame:annotationFrame];
            } else if (annotationToolChosen == kAnnotationToolArrow) {
                annotationInProgress = [[BSKAnnotationArrowView alloc] initWithFrame:annotationFrame];
            } else if (annotationToolChosen == kAnnotationToolBlur) {
                annotationInProgress = [[BSKAnnotationBlurView alloc] initWithFrame:annotationFrame baseImage:self.screenshotImage];
                insertBelowCheckerboard = YES;
            } else {
                NSAssert1(0, @"Unknown tool %d chosen", annotationToolChosen);
            }
            
            annotationInProgress.annotationStrokeColor = BugshotKit.sharedManager.annotationStrokeColor;
            annotationInProgress.annotationFillColor = BugshotKit.sharedManager.annotationFillColor;
            
            if (insertBelowCheckerboard) {
                [self.view insertSubview:annotationInProgress belowSubview:self.gridOverlay];
            } else {
                [self.view addSubview:annotationInProgress];
            }
            annotationInProgress.startedDrawingAtPoint = annotationFrame.origin;
        }
    } else if (annotationInProgress) {
        [annotationInProgress removeFromSuperview];
        annotationInProgress = nil;
    } else {
        [super touchesBegan:touches withEvent:event];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (touches.count == 1 && annotationInProgress) {
        UITouch *touch = touches.anyObject;
        CGPoint p1 = [touch locationInView:self.view], p2 = annotationInProgress.startedDrawingAtPoint;
        
        CGRect bounding = CGRectMake(MIN(p1.x, p2.x), MIN(p1.y, p2.y), ABS(p1.x - p2.x), ABS(p1.y - p2.y));
        
        if (bounding.size.height < 40) bounding.size.height = 40;
        if (bounding.size.width < 40) bounding.size.width = 40;
        annotationInProgress.frame = bounding;
        
        if ([annotationInProgress isKindOfClass:[BSKAnnotationArrowView class]]) {
            ((BSKAnnotationArrowView *)annotationInProgress).arrowEnd = p1;
        }
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (annotationInProgress) {
        CGSize annotationSize = annotationInProgress.bounds.size;
        if (MIN(annotationSize.width, annotationSize.height) < 5.0f ||
            (annotationSize.width < 32.0f && annotationSize.height < 32.0f)
        ) {
            // Too small, probably accidental
            [annotationInProgress removeFromSuperview];
        } else {
            [self.contentAreaTapGestureRecognizer requireGestureRecognizerToFail:annotationInProgress.doubleTapDeleteGestureRecognizer];
            [annotationInProgress initialScaleDone];
        }
    
        annotationInProgress = nil;
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (annotationInProgress) {
        [annotationInProgress removeFromSuperview];
        annotationInProgress = nil;
    }
}

@end
