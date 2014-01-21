//  BSKCheckerboardView.h
//  See included LICENSE file for the (MIT) license.
//  Created by Marco Arment on 6/30/13.

#import <UIKit/UIKit.h>

@interface BSKCheckerboardView : UIView

- (id)initWithFrame:(CGRect)frame checkerSquareWidth:(CGFloat)squareWidth;

@property (strong, nonatomic) UIColor *evenColor;
@property (strong, nonatomic) UIColor *oddColor;

@end
