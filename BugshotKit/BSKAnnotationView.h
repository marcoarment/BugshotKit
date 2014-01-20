//  BSKAnnotationView.h
//  See included LICENSE file for the (MIT) license.
//  Created by Marco Arment on 6/28/13.

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface BSKAnnotationView : UIView <UIGestureRecognizerDelegate>

// Useful for subclasses:
- (void)initialScaleDone;
- (BOOL)canScale;
- (void)panBegan;
- (void)panEnded;
- (void)pinchBegan;
- (void)pinchEnded;


@property (nonatomic, assign) CGPoint startedDrawingAtPoint;
@property (nonatomic, strong) UIColor *annotationFillColor;
@property (nonatomic, strong) UIColor *annotationStrokeColor;
@property (nonatomic, strong) UITapGestureRecognizer *doubleTapDeleteGestureRecognizer;
@end
