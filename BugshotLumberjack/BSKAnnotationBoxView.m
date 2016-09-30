//  BSKAnnotationBoxView.m
//  See included LICENSE file for the (MIT) license.
//  Created by Marco Arment on 6/29/13.

#import "BSKAnnotationBoxView.h"

#define M_3PI_2 (M_PI_2 + M_PI)

@implementation BSKAnnotationBoxView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.opaque = NO;
        self.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
        self.layer.shadowColor = [UIColor blackColor].CGColor;
        self.layer.shadowOpacity = 1.0f;
        self.layer.shadowRadius = 4.0f;
    }
    return self;
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];

    _borderWidth = MAX(6.0f, MIN(16.0f, MIN(frame.size.width, frame.size.height) * 0.075f));
    _cornerRadius = _borderWidth * 2.0f;
    _strokeWidth = MAX(2.0f, _borderWidth * 0.25f);

    self.layer.shadowRadius = MAX(4.0f, _borderWidth * 0.33f);
}

- (void)drawRect:(CGRect)rect
{
    CGRect frame = self.bounds;
    frame.origin = CGPointZero;
    
    CGRect outerBox = CGRectInset(frame, _strokeWidth, _strokeWidth);
    CGRect innerBox = CGRectInset(outerBox, _borderWidth + _strokeWidth, _borderWidth + _strokeWidth);
    if (MIN(innerBox.size.height, innerBox.size.width) < (_borderWidth + _strokeWidth) * 2) return;
    if (MIN(innerBox.size.height, innerBox.size.width) < _cornerRadius * 2.5) return;

    CGPathRef roundRectPath = CGPathCreateWithRoundedRect(innerBox, _cornerRadius, _cornerRadius, NULL);
    CGPathRef thickStrokePath = CGPathCreateCopyByStrokingPath(roundRectPath, NULL, _borderWidth + _strokeWidth, kCGLineCapButt, kCGLineJoinBevel, 100.0f);
    self.layer.shadowPath = thickStrokePath;
    UIBezierPath *bezierPath = [UIBezierPath bezierPathWithCGPath:thickStrokePath];
    
    [self.annotationFillColor setFill];
    [bezierPath fill];

    [self.annotationStrokeColor setStroke];
    bezierPath.lineWidth = _strokeWidth;
    [bezierPath stroke];
    
    CGPathRelease(roundRectPath);
    CGPathRelease(thickStrokePath);
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    CGRect touchBoundsOuter = self.bounds;
    CGRect touchBoundsInner = CGRectInset(touchBoundsOuter, _borderWidth + _strokeWidth + 20.0f, _borderWidth + _strokeWidth + 20.0f);
    touchBoundsOuter = CGRectInset(touchBoundsOuter, -16.0f, -16.0f);

    if (touchBoundsOuter.size.width < 80 || touchBoundsOuter.size.height < 80) {
        if (CGRectContainsPoint(touchBoundsOuter, point)) return self;
        else return nil;
    } else {
        if (CGRectContainsPoint(touchBoundsOuter, point) && ! CGRectContainsPoint(touchBoundsInner, point)) return self;
        else return nil;
    }

    return nil;
}

@end
