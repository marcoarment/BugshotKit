//  BSKAnnotationBlurView.m
//  See included LICENSE file for the (MIT) license.
//  Created by Marco Arment on 7/15/13.

#import "BSKAnnotationBlurView.h"
#import "BugshotKit.h"
#import "UIImage+ImageEffects.h"
#import "BSKCheckerboardView.h"

static inline UIImage *imageCroppedToRect(UIImage *image, CGRect rect)
{
    CGFloat scale = image.scale;
    if (scale > 1.0f) rect = CGRectMake(rect.origin.x * scale, rect.origin.y * scale, rect.size.width * scale, rect.size.height * scale);
    CGImageRef imageRef = CGImageCreateWithImageInRect(image.CGImage, rect);
    UIImage *result = [UIImage imageWithCGImage:imageRef scale:scale orientation:image.imageOrientation];
    CGImageRelease(imageRef);
    return result;
}

static inline UIColor *modifiedColorWithAlpha(UIColor *color, CGFloat newAlpha)
{
    CGFloat hue, saturation, brightness, alpha;
    if (! [color getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha]) {
        if ([color getWhite:&brightness alpha:&alpha]) {
            hue = 0;
            saturation = 0;
        } else {
            return color;
        }
    }
    
    alpha = MAX(0.0f, MIN(1.0f, newAlpha));
    return [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:alpha];
}


@interface BSKAnnotationBlurView ()
@property (strong, nonatomic) UIImage *baseImage;
@property (strong, nonatomic) UIColor *sizingBackgroundColor;
@end

@implementation BSKAnnotationBlurView

- (id)initWithFrame:(CGRect)frame baseImage:(UIImage *)baseImage
{
    if ( (self = [super initWithFrame:frame]) ) {
        self.baseImage = [UIImage imageWithCGImage:baseImage.CGImage scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];

        self.sizingBackgroundColor    = modifiedColorWithAlpha(BugshotKit.sharedManager.annotationFillColor, 0.25f);
        UIColor *slightlyLighterColor = modifiedColorWithAlpha(BugshotKit.sharedManager.annotationFillColor, 0.21f);

        
        CGRect checkerFrame = frame;
        checkerFrame.origin = CGPointZero;
        BSKCheckerboardView *gridOverlay = [[BSKCheckerboardView alloc] initWithFrame:checkerFrame checkerSquareWidth:7.0f];
        gridOverlay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        gridOverlay.opaque = NO;
        gridOverlay.evenColor = self.sizingBackgroundColor;
        gridOverlay.oddColor = slightlyLighterColor;
        [self addSubview:gridOverlay];
    }
    return self;
}

- (void)pinchEnded { [self setNeedsDisplay]; }
- (void)panEnded { [self setNeedsDisplay]; }


- (void)initialScaleDone
{
    [super initialScaleDone];
    [self setNeedsDisplay];
}

- (void)setFrame:(CGRect)frame
{
    // Prevent blurs from being dragged partially offscreen
    CGRect superBounds = self.superview.bounds;

    if (frame.origin.x < 0) frame.origin.x = 0;
    if (frame.origin.y < 0) frame.origin.y = 0;
    if (frame.origin.x + frame.size.width > superBounds.size.width) frame.origin.x = superBounds.size.width - frame.size.width;
    if (frame.origin.y + frame.size.height > superBounds.size.height) frame.origin.y = superBounds.size.height - frame.size.height;
    
    [super setFrame:frame];
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    CGRect cropRect = [self convertRect:self.bounds toView:self.superview];
    UIImage *blurImage = imageCroppedToRect(self.baseImage, cropRect);

    blurImage = [blurImage applyBlurWithRadius:15.0f tintColor:_sizingBackgroundColor saturationDeltaFactor:0.25 maskImage:nil];
    [blurImage drawInRect:rect];
}

@end
