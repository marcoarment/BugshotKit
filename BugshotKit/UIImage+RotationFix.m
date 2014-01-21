//
//  UIImage+RotationFix.m
//  Pods
//
//  Created by Matteo Gavagnin on 21/01/14.
//
//

#import "UIImage+RotationFix.h"

@implementation UIImage (RotationFix)

static inline double radians (double degrees) {return degrees * M_PI/180;}

UIImage* rotateIfNeeded(UIImage* src, UIImageOrientation orientation)
{
    if (src.imageOrientation == UIImageOrientationDown && src.size.width < src.size.height) {
        UIGraphicsBeginImageContext(src.size);
        [src drawAtPoint:CGPointMake(0, 0)];
        return UIGraphicsGetImageFromCurrentImageContext();
    } else if ((src.imageOrientation == UIImageOrientationLeft || src.imageOrientation == UIImageOrientationRight) && src.size.width > src.size.height) {
        UIGraphicsBeginImageContext(src.size);
        
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        if (orientation == UIImageOrientationRight) {
            CGContextRotateCTM (context, radians(90));
        } else if (orientation == UIImageOrientationLeft) {
            CGContextRotateCTM (context, radians(-90));
        } else if (orientation == UIImageOrientationDown) {
            // CGContextRotateCTM (context, radians(-90));
        } else if (orientation == UIImageOrientationUp) {
            CGContextRotateCTM (context, radians(90));
        }
        
        [src drawAtPoint:CGPointMake(0, 0)];
        
        return UIGraphicsGetImageFromCurrentImageContext();
        
    } else {
        return src;
    }
}

@end
