//
//  AppDelegate.m
//  TestBugshotKit
//
//  Created by Marco Arment on 1/20/14.
//  Copyright (c) 2014 Marco Arment. All rights reserved.
//

#import "AppDelegate.h"
#import "BugshotKit.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Configure BugshotKit to send email
    [BugshotKit enableWithNumberOfTouches:2 performingGestures:(BSKInvocationGestureSwipeFromRightEdge | BSKInvocationGestureSwipeUp) feedbackEmailAddress:@"test@invalid.org"];
    
    
    // Alternatively, configure BugshotKit to post to a JSON API. Examples:
    /*
    [BugshotKit enableWithNumberOfTouches:2 performingGestures:(BSKInvocationGestureSwipeFromRightEdge | BSKInvocationGestureSwipeUp)
                              feedbackURL:[NSURL URLWithString:@"my-api-url"]
                             headerFields:@{@"myFirstHeaderKeyForExampleAPIKey": @"myAPIKey"}
                               parameters:nil];
    
     */
   
    /*
    [BugshotKit enableWithNumberOfTouches:2 performingGestures:(BSKInvocationGestureSwipeFromRightEdge | BSKInvocationGestureSwipeUp)
                              feedbackURL:[NSURL URLWithString:@"my-api-url"]
                             headerFields:@{@"username": @"myUsername", @"password": @"mypassword"}
                               parameters:@{@"param1": @"value1", @"param2": @"value2"}];
    
    */
    
    return YES;
}

@end
