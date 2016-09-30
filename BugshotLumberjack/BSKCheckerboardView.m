//  BSKCheckerboardView.m
//  See included LICENSE file for the (MIT) license.
//  Created by Marco Arment on 6/30/13.

#import "BSKCheckerboardView.h"

@interface BSKCheckerboardView () {
    CGFloat squareWidth;
}
@end

#define kSquaresPerSide 16

@implementation BSKCheckerboardView

- (id)initWithFrame:(CGRect)frame checkerSquareWidth:(CGFloat)sw
{
    if ( (self = [super initWithFrame:frame]) ) {
        squareWidth = ceilf((float)sw);
        self.evenColor = [UIColor colorWithWhite:0.96f alpha:1.0f];
        self.oddColor  = [UIColor colorWithWhite:0.88f alpha:1.0f];
    }
    return self;
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    CGSize viewSize = self.bounds.size;
    
    int rows = (int) ceilf((float)viewSize.height / (float)squareWidth);
    int columns = (int) ceilf((float)viewSize.width / (float)squareWidth);

    CGContextRef c = UIGraphicsGetCurrentContext();
    
    for (int row = 0; row < rows; row++) {
        for (int column = 0; column < columns; column++) {
            if ((row + column) % 2) {
                [_evenColor set];
            } else {
                [_oddColor set];
            }
            
            CGContextFillRect(c, CGRectMake(column * squareWidth, row * squareWidth, squareWidth, squareWidth));
        }
    }
}

@end
