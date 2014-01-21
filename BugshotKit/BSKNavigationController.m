//
//  BSKNavigationController.m
//  TestBugshotKit
//
//  Created by Marco Arment on 1/20/14.
//  Copyright (c) 2014 Marco Arment. All rights reserved.
//

#import "BSKNavigationController.h"

@interface BSKNavigationController ()
@property (nonatomic) UIInterfaceOrientation lockedOrientation;
@end

@implementation BSKNavigationController

- (id)initWithRootViewController:(UIViewController *)rootViewController lockedToRotation:(UIInterfaceOrientation)lockedOrientation
{
    if ( (self = [super initWithRootViewController:rootViewController]) ) {
        self.lockedOrientation = lockedOrientation;
    }
    return self;
}

- (UIStatusBarStyle)preferredStatusBarStyle { return UIStatusBarStyleDefault; }
- (BOOL)prefersStatusBarHidden { return NO; }

- (NSUInteger)supportedInterfaceOrientations
{
    return 1 << self.lockedOrientation;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return self.lockedOrientation;
}

- (BOOL)shouldAutorotate
{
    return NO;
}

@end
