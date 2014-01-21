//
//  BSKNavigationController.h
//  TestBugshotKit
//
//  Created by Marco Arment on 1/20/14.
//  Copyright (c) 2014 Marco Arment. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BSKNavigationController : UINavigationController

- (id)initWithRootViewController:(UIViewController *)rootViewController lockedToRotation:(UIInterfaceOrientation)lockedOrientation;

@property (nonatomic, readonly) UIInterfaceOrientation lockedOrientation;

@end
