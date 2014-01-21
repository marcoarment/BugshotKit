//
//  UIImage+RotationFix.h
//  Pods
//
//  Created by Matteo Gavagnin on 21/01/14.
//
//

#import <UIKit/UIKit.h>

@interface UIImage (RotationFix)

UIImage* rotateIfNeeded(UIImage* src, UIImageOrientation orientation);

@end
