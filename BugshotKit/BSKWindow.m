//  BSKWindow.m
//  See included LICENSE file for the (MIT) license.
//  Created by Bryan Irace on 1/21/14.

#import "BSKWindow.h"
#import "BugshotKit.h"

@implementation BSKWindow

#pragma mark - UIResponder

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    [super motionEnded:motion withEvent:event];

    if (event.subtype == UIEventSubtypeMotionShake) {
        [BugshotKit show];
    }
}

@end
