//
//  UIImage+ClipImage.m
//  TestForCamera
//
//  Created by dvt04 on 16/8/10.
//  Copyright © 2016年 suma. All rights reserved.
//

#import "UIImage+ClipImage.h"

@implementation UIImage (ClipImage)

+ (UIImage *)cropImageWithImage:(UIImage *)image inRect:(CGRect)cropRect {
    CGRect drawRect = CGRectMake(-cropRect.origin.x , -cropRect.origin.y, image.size.width * image.scale, image.size.height * image.scale);
    UIGraphicsBeginImageContext(cropRect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextClearRect(context, CGRectMake(0, 0, cropRect.size.width, cropRect.size.height));
    
    [image drawInRect:drawRect];
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

@end
