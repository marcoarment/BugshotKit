//  BSKAnnotationView.m
//  See included LICENSE file for the (MIT) license.
//  Created by Marco Arment on 6/28/13.

#import "BSKAnnotationView.h"
#import <QuartzCore/QuartzCore.h>

@interface BSKAnnotationView () {
    CGSize sizeAtPinchStart;
    CGSize previousFrameSize;
}
@end

@implementation BSKAnnotationView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        previousFrameSize = CGSizeZero;
        self.doubleTapDeleteGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapped:)];
        self.doubleTapDeleteGestureRecognizer.numberOfTapsRequired = 2;
        self.doubleTapDeleteGestureRecognizer.delegate = self;
        [self addGestureRecognizer:self.doubleTapDeleteGestureRecognizer];
        
        if ([self canScale]) {
            UIPinchGestureRecognizer *pinchGR = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinched:)];
            pinchGR.delegate = self;
            [self addGestureRecognizer:pinchGR];
        }

        UIPanGestureRecognizer *panGR = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panned:)];
        panGR.delegate = self;
        [self addGestureRecognizer:panGR];

        sizeAtPinchStart = frame.size;
        self.startedDrawingAtPoint = frame.origin;
    }
    return self;
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];

    if (! CGSizeEqualToSize(frame.size, previousFrameSize)) {
        previousFrameSize = frame.size;
        [self setNeedsDisplay];
    }
}

- (BOOL)canScale { return YES; }

- (void)initialScaleDone
{
    sizeAtPinchStart = self.bounds.size;
}

- (void)doubleTapped:(UITapGestureRecognizer *)doubleTapGR
{
    [self removeFromSuperview];
}

- (void)pinchBegan { }
- (void)pinchEnded { }

- (void)pinched:(UIPinchGestureRecognizer *)pinchGR
{
    if (pinchGR.state == UIGestureRecognizerStateBegan) [self pinchBegan];
    else if (pinchGR.state == UIGestureRecognizerStateEnded || pinchGR.state == UIGestureRecognizerStateFailed) [self pinchEnded];

    if (pinchGR.state == UIGestureRecognizerStateBegan || pinchGR.state == UIGestureRecognizerStateChanged) {
        CGRect frame = [self.superview convertRect:self.bounds fromView:self];
        CGPoint center = CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame));
        
        CGSize newSize = CGSizeMake(sizeAtPinchStart.width * pinchGR.scale, sizeAtPinchStart.height * pinchGR.scale);
        self.frame = CGRectMake(center.x - (newSize.width / 2), center.y - (newSize.width / 2), newSize.width, newSize.height);
        self.center = center;
    } else if (pinchGR.state == UIGestureRecognizerStateEnded) {
        sizeAtPinchStart = self.bounds.size;
    }
}

- (void)panBegan { }
- (void)panEnded { }

- (void)panned:(UIPanGestureRecognizer *)panGR
{
    if (panGR.state == UIGestureRecognizerStateBegan) [self panBegan];
    else if (panGR.state == UIGestureRecognizerStateEnded || panGR.state == UIGestureRecognizerStateFailed) [self panEnded];

    CGRect frame = [self.superview convertRect:self.bounds fromView:self];
    CGPoint translation = [panGR translationInView:self.superview];
    frame.origin.x += translation.x;
    frame.origin.y += translation.y;
    self.frame = frame;
    [panGR setTranslation:CGPointZero inView:self.superview];
}


- (BOOL)gestureRecognizer:(UIGestureRecognizer *)g1 shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)g2 { return YES; }


@end
