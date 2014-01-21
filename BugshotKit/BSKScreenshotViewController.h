//  BSKScreenshotViewController.h
//  See included LICENSE file for the (MIT) license.
//  Created by Marco Arment on 6/28/13.

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface BSKScreenshotViewController : UIViewController

- (id)initWithImage:(UIImage *)image annotations:(NSArray *)annotations;

@property (nonatomic, retain) IBOutlet UIImageView *screenshotImageView;

@end


