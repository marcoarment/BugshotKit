//  BSKAnnotationArrowView.m
//  See included LICENSE file for the (MIT) license.
//  Created by Marco Arment on 6/29/13.

#import "BSKAnnotationArrowView.h"
#import <QuartzCore/QuartzCore.h>

#define kMinimumArrowLength 40

@interface BSKAnnotationArrowView () {
    CGSize sizeAtPinchStart;
    CGFloat arrowLength;
    BOOL initialScaleDone;
    BOOL initialArrowSet;
    
    CGPoint localStartPoint, localEndPoint;
}
@property (nonatomic, retain) UIBezierPath *arrowPath;
@end

@implementation BSKAnnotationArrowView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.opaque = NO;
        initialScaleDone = NO;
        initialArrowSet = NO;

        self.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
        self.layer.shadowColor = [UIColor blackColor].CGColor;
        self.layer.shadowOpacity = 1.0f;
        self.layer.shadowRadius = 4.0f;
    }
    return self;
}

- (BOOL)canScale { return NO; }

- (void)initialScaleDone
{
    [super initialScaleDone];
    initialScaleDone = YES;
    
    if (arrowLength < kMinimumArrowLength) [self removeFromSuperview];
}

- (void)setStartedDrawingAtPoint:(CGPoint)startedDrawingAtPoint
{
    [super setStartedDrawingAtPoint:startedDrawingAtPoint];
}

- (void)setArrowEnd:(CGPoint)arrowEnd
{
    initialArrowSet = YES;
    _arrowEnd = arrowEnd;
    localStartPoint = [self convertPoint:self.startedDrawingAtPoint fromView:self.superview];
    localEndPoint = [self convertPoint:arrowEnd fromView:self.superview];

    CGPoint p1 = self.startedDrawingAtPoint, p2 = self.arrowEnd;
    CGFloat xDist = (p2.x - p1.x);
    CGFloat yDist = (p2.y - p1.y);
    arrowLength = sqrtf((float)(xDist * xDist) + (float)(yDist * yDist));
}

- (void)setFrame:(CGRect)frame
{
    if (! initialScaleDone) {
        if (frame.size.height < 10.0f) frame.size.height = 10.0f;
        if (frame.size.width < 10.0f)  frame.size.width = 10.0f;
        
        CGFloat extraFramePadding = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? -170.0f : -120.0f;
        frame = CGRectInset(frame, extraFramePadding, extraFramePadding);
    }
    
    [super setFrame:frame];
}


- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextClearRect(context, rect);
    
    if (! initialArrowSet) {
        self.layer.shadowOpacity = 0.0f;
        return;
    } else {
        self.layer.shadowOpacity = 1.0f;
    }
    
    [self.annotationFillColor setFill];
    
    CGFloat tailWidth = MAX(4.0f, arrowLength * 0.07f);
    CGFloat headLength = MAX(arrowLength / 3.0f, 10.0f);
    CGFloat headWidth = headLength * 0.9f;
    CGFloat strokeWidth = MAX(1.0f, tailWidth * 0.25f);
    
    self.layer.shadowRadius = MAX(4.0f, tailWidth * 0.25f);

    [self.annotationStrokeColor setStroke];
    
    self.arrowPath = [self.class
        bezierPathWithArrowFromPoint:localStartPoint
        toPoint:localEndPoint
        tailWidth:tailWidth
        headWidth:headWidth
        headLength:headLength
    ];
    self.arrowPath.lineWidth = strokeWidth;    
    [self.arrowPath fill];
    [self.arrowPath stroke];
    self.layer.shadowPath = self.arrowPath.CGPath;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    if ([self.arrowPath containsPoint:point]) return self;
    CGRect boundingBox = self.arrowPath.bounds;
    if ( (boundingBox.size.width < 80 || boundingBox.size.height < 80) &&
        CGRectContainsPoint(boundingBox, point)
    ) return self;

    return nil;
}

// Compacted version of Rob Mayoff's original code from https://gist.github.com/mayoff/4146780
+ (UIBezierPath *)bezierPathWithArrowFromPoint:(CGPoint)startPoint toPoint:(CGPoint)endPoint tailWidth:(CGFloat)tailWidth headWidth:(CGFloat)headWidth headLength:(CGFloat)headLength
{
    CGFloat length = hypotf((float)endPoint.x - (float)startPoint.x, (float)endPoint.y - (float)startPoint.y);
    CGFloat tailLength = length - headLength;
    
    CGPoint points[7] = {
        CGPointMake(0, tailWidth / 2),
        CGPointMake(tailLength, tailWidth / 2),
        CGPointMake(tailLength, headWidth / 2),
        CGPointMake(length, 0),
        CGPointMake(tailLength, -headWidth / 2),
        CGPointMake(tailLength, -tailWidth / 2),
        CGPointMake(0, -tailWidth / 2)
    };

    CGFloat cosine = (endPoint.x - startPoint.x) / length;
    CGFloat sine = (endPoint.y - startPoint.y) / length;
    CGAffineTransform transform = (CGAffineTransform){ cosine, sine, -sine, cosine, startPoint.x, startPoint.y };
    CGMutablePathRef cgPath = CGPathCreateMutable();
    CGPathAddLines(cgPath, &transform, points, sizeof points / sizeof *points);
    CGPathCloseSubpath(cgPath);
 
    UIBezierPath *uiPath = [UIBezierPath bezierPathWithCGPath:cgPath];
    uiPath.lineCapStyle = kCGLineCapRound;
    uiPath.lineJoinStyle = kCGLineJoinRound;
    CGPathRelease(cgPath);

    return uiPath;
}

@end

