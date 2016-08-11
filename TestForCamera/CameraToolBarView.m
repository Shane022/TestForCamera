//
//  CameraToolBarView.m
//  TestForCamera
//
//  Created by dvt04 on 16/8/11.
//  Copyright © 2016年 suma. All rights reserved.
//

#import "CameraToolBarView.h"

@implementation CameraToolBarView

@synthesize btnSessionPreset, btnImageCompress, btnSwitchCamera, btnSnap;

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupToolBarView];
    }
    return self;
}

- (void)setupToolBarView {
    CGFloat margionRight = 10;
    CGFloat margionTop = 7;
    CGFloat btnGap = 5;
    CGFloat btnWidth = 50;
    CGFloat btnHeight = 30;
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    // 拍照
    btnSnap = [UIButton buttonWithType:UIButtonTypeCustom];
    btnSnap.frame = CGRectMake(screenWidth-margionRight-btnWidth, margionTop, btnWidth, btnHeight);
    [btnSnap setTitle:@"拍照" forState:UIControlStateNormal];
    [btnSnap.titleLabel setFont:[UIFont systemFontOfSize:14]];
    [self addSubview:btnSnap];
    // 旋转摄像头
    btnSwitchCamera = [UIButton buttonWithType:UIButtonTypeCustom];
    btnSwitchCamera.frame = CGRectMake(btnSnap.frame.origin.x-btnGap-btnWidth, margionTop, btnWidth, btnHeight);
    [btnSwitchCamera setTitle:@"旋转" forState:UIControlStateNormal];
    [btnSwitchCamera.titleLabel setFont:[UIFont systemFontOfSize:14]];
    [self addSubview:btnSwitchCamera];
    // 设置UIImageJPEGRepresentation，图片压缩比
    btnImageCompress = [UIButton buttonWithType:UIButtonTypeCustom];
    btnImageCompress.frame = CGRectMake(btnSwitchCamera.frame.origin.x-btnGap-btnWidth, margionTop, btnWidth, btnHeight);
    [btnImageCompress setTitle:@"压缩比" forState:UIControlStateNormal];
    [btnImageCompress.titleLabel setFont:[UIFont systemFontOfSize:14]];
//    [self addSubview:btnImageCompress];
    // 设置AVCaptureSessionPreset，拍摄相片的质量
    btnSessionPreset = [UIButton buttonWithType:UIButtonTypeCustom];
    btnSessionPreset.frame = CGRectMake(btnImageCompress.frame.origin.x-btnGap-btnWidth, margionTop, btnWidth, btnHeight);
    [btnSessionPreset setTitle:@"分辨率" forState:UIControlStateNormal];
    [btnSessionPreset.titleLabel setFont:[UIFont systemFontOfSize:14]];
//    [self addSubview:btnSessionPreset];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
