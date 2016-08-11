//
//  CameraToolBarView.h
//  TestForCamera
//
//  Created by dvt04 on 16/8/11.
//  Copyright © 2016年 suma. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CameraToolBarView : UIView

@property (nonatomic, strong) UIButton *btnSessionPreset;   // 设置AVCaptureSessionPreset，拍摄相片的质量
@property (nonatomic, strong) UIButton *btnImageCompress;   // 设置UIImageJPEGRepresentation，图片压缩比
@property (nonatomic, strong) UIButton *btnSwitchCamera;    // 旋转摄像头
@property (nonatomic, strong) UIButton *btnSnap;            // 拍照

@end
