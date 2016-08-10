//
//  HollowOutView.m
//  TestForCamera
//
//  Created by dvt04 on 16/8/9.
//  Copyright © 2016年 suma. All rights reserved.
//

#import "HollowOutView.h"

@implementation HollowOutView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        //设置 背景为clear
        self.backgroundColor = [UIColor clearColor];
        self.opaque = NO;
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    
    [[UIColor colorWithWhite:0 alpha:0.5] setFill];
    //半透明区域
    UIRectFill(rect);
    
    //透明的区域
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    CGFloat margionLeft = 15;
    CGFloat holeWidth = screenWidth - 2*margionLeft;
    CGFloat holeHeight = holeWidth * 4/3;
    CGRect holeRection = CGRectMake(margionLeft, (screenHeight-holeHeight)/2, holeWidth, holeHeight);
    
    UIImageView *faceImageView = [[UIImageView alloc] initWithFrame:holeRection];
    faceImageView.image = [UIImage imageNamed:@"face.png"];
    [self addSubview:faceImageView];
    /** union: 并集
     CGRect CGRectUnion(CGRect r1, CGRect r2)
     返回并集部分rect
     */
    
    /** Intersection: 交集
     CGRect CGRectIntersection(CGRect r1, CGRect r2)
     返回交集部分rect
     */
    CGRect holeiInterSection = CGRectIntersection(holeRection, rect);
    [[UIColor clearColor] setFill];
    
    //CGContextClearRect(ctx, <#CGRect rect#>)
    //绘制
    //CGContextDrawPath(ctx, kCGPathFillStroke);
    UIRectFill(holeiInterSection);
    
}

@end
