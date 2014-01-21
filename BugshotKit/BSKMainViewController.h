//  BSKMainViewController.h
//  See included LICENSE file for the (MIT) license.
//  Created by Marco Arment on 1/17/14.

#import <UIKit/UIKit.h>
@import MessageUI;

@class BSKMainViewController;

@protocol BSKMainViewControllerDelegate

- (void)mainViewControllerDidClose:(BSKMainViewController *)mainViewController;

@end


@interface BSKMainViewController : UITableViewController <MFMailComposeViewControllerDelegate>

@property (nonatomic, weak) id<BSKMainViewControllerDelegate> delegate;

@end
