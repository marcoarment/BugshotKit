//  BSKToggleButton.m
//  See included LICENSE file for the (MIT) license.
//  Created by Marco Arment on 1/18/14.

#import "BSKToggleButton.h"
#import "BugshotKit.h"

@interface BSKToggleButton () {
    BOOL on;
}
@property (nonatomic) UIImage *onImage;
@property (nonatomic) UIImage *offImage;

@end

@implementation BSKToggleButton

- (instancetype)initWithFrame:(CGRect)frame
{
    if ( (self = [super initWithFrame:frame]) ) {
        self.adjustsImageWhenHighlighted = NO;
        [self addTarget:self action:@selector(tapped:) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];

    CGRect imageRect = frame;
    imageRect.origin = CGPointZero;

    __block UIColor *mainColor = BugshotKit.sharedManager.toggleOnColor;
    __block UIColor *borderColor = UIColor.whiteColor;
    
    void (^onImageGenerator)() = ^{
        [mainColor setFill];
        [mainColor setStroke];

        CGRect circleBorderRect = CGRectInset(imageRect, 0.5f, 0.5f);
        UIBezierPath* circleBorderPath = [UIBezierPath bezierPathWithOvalInRect:circleBorderRect];
        circleBorderPath.lineWidth = 1.0f;
        [circleBorderPath stroke];

        [borderColor setStroke];
        CGRect circleRect = CGRectInset(imageRect, 2.5f, 2.5f);
        UIBezierPath* circlePath = [UIBezierPath bezierPathWithOvalInRect:circleRect];
        circlePath.lineWidth = 3.0f;
        [circlePath fill];
        [circlePath stroke];

        CGRect checkmarkRect = CGRectIntegral(CGRectInset(circleRect, circleRect.size.width * 0.25f, circleRect.size.height * 0.25f));
        UIBezierPath* checkmarkPath = [UIBezierPath bezierPath];
        [checkmarkPath moveToPoint:CGPointMake(checkmarkRect.origin.x, checkmarkRect.origin.y + 0.5f * checkmarkRect.size.height)];
        [checkmarkPath addLineToPoint:CGPointMake(checkmarkRect.origin.x + 0.3333f * checkmarkRect.size.width, checkmarkRect.origin.y + 0.8333f * checkmarkRect.size.height)];
        [checkmarkPath addLineToPoint:CGPointMake(checkmarkRect.origin.x + checkmarkRect.size.width, checkmarkRect.origin.y + 0.1667f * checkmarkRect.size.height)];
        checkmarkPath.lineWidth = ceilf(circleRect.size.width * 0.075f);
        [checkmarkPath stroke];
    };
    
    self.onImage = BSKImageWithDrawing(imageRect.size, onImageGenerator);
    mainColor = BugshotKit.sharedManager.toggleOffColor;
    UIImage *highlightedImage = BSKImageWithDrawing(imageRect.size, onImageGenerator);
    
    self.offImage = BSKImageWithDrawing(imageRect.size, ^{
        [mainColor setFill];
        [mainColor setStroke];

        CGRect circleBorderRect = CGRectInset(imageRect, 0.5f, 0.5f);
        UIBezierPath* circleBorderPath = [UIBezierPath bezierPathWithOvalInRect:circleBorderRect];
        circleBorderPath.lineWidth = 1.0f;
        [circleBorderPath stroke];

        [borderColor setStroke];
        [borderColor setFill];
        CGRect circleRect = CGRectInset(imageRect, 2.5f, 2.5f);
        UIBezierPath* circlePath = [UIBezierPath bezierPathWithOvalInRect:circleRect];
        circlePath.lineWidth = 3.0f;
        [circlePath stroke];
        [circlePath fill];

        [mainColor setStroke];
        CGRect circleInnerRect = CGRectInset(imageRect, 4.5f, 4.5f);
        UIBezierPath* circleInnerBorderPath = [UIBezierPath bezierPathWithOvalInRect:circleInnerRect];
        circleInnerBorderPath.lineWidth = 1.0f;
        [circleInnerBorderPath stroke];
    });

    [self setBackgroundImage:self.offImage forState:UIControlStateNormal];
    [self setBackgroundImage:highlightedImage forState:(UIControlStateHighlighted | UIControlStateSelected)];
}

- (BOOL)on { return on; }
- (void)setOn:(BOOL)o
{
    on = o;
    [self setBackgroundImage:(on ? self.onImage : self.offImage) forState:UIControlStateNormal];
//    [self setImage:(on ? self.onImage : self.offImage) forState:UIControlStateNormal];

    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

- (void)tapped:(BSKToggleButton *)btn
{
    self.on = ! on;
}


@end
