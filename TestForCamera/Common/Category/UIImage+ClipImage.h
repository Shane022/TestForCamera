//
//  UIImage+ClipImage.h
//  TestForCamera
//
//  Created by dvt04 on 16/8/10.
//  Copyright © 2016年 suma. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (ClipImage)

+ (UIImage *)cropImageWithImage:(UIImage *)image inRect:(CGRect)cropRect;

@end
