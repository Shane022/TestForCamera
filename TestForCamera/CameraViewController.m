//
//  CameraViewController.m
//  TestForCamera
//
//  Created by dvt04 on 16/8/10.
//  Copyright © 2016年 suma. All rights reserved.
//

#import "CameraViewController.h"
#import "HollowOutView.h"

@interface CameraViewController ()

@property (nonatomic, strong) AVCaptureDevice *device;
@property (nonatomic, strong) AVCaptureDeviceInput *input;
@property (nonatomic, strong) AVCaptureStillImageOutput *stillImageOutput;
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, strong) HollowOutView *bgView;

@end

@implementation CameraViewController
{
    BOOL _isFrontCamera;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupLayoutAndInitData];
    [self checkCameraAuth];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (self.session) {
        [self.session stopRunning];
    }
}

#pragma mark - SetupLayoutAndInitData
- (void)setupLayoutAndInitData {
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"转换" style:UIBarButtonItemStyleDone target:self action:@selector(onHitBtnSwitchCamera:)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"拍照" style:UIBarButtonItemStyleDone target:self action:@selector(onHitBtnTakePhoto:)];

    _isFrontCamera = NO;
}

#pragma mark - CheckCameraAuth
- (void)checkCameraAuth {
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    NSLog(@"camera auth = %ld",(long)authStatus);
    switch (authStatus) {
        case AVAuthorizationStatusNotDetermined:
        {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if (granted) {
                    // 创建相机
                    [self setupCamera];
                } else {
                    // 退出页面
                }
            }];
        }
            break;
        case AVAuthorizationStatusRestricted:
        case AVAuthorizationStatusDenied:
        {
            // 未授权；提示
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"相机授权" message:@"没有权限访问您的相机，请在“设置-本应用-相机”中允许使用" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:nil];
            [alertView show];
        }
        default:
        {
            [self setupCamera];
        }
            break;
    }
}

#pragma mark - SetupCamera
- (void)setupCamera {
    // 设置相机
    self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    // 更改设备时先锁定设备，修改完之后再解锁
    [self.device lockForConfiguration:nil];
    // 设置闪光灯为自动
    [self.device setFlashMode:AVCaptureFlashModeAuto];
    [self.device unlockForConfiguration];
    
    NSError *error = nil;
    self.input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:&error];
    if (!self.input) {
        // Handle the error appropriately.
        NSLog(@"ERROR: trying to open camera: %@", error);
    }
    
    self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    //输出设置。AVVideoCodecJPEG   输出jpeg格式图片
    NSDictionary * outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG,AVVideoCodecKey, nil];
    [self.stillImageOutput setOutputSettings:outputSettings];
    
    self.session = [[AVCaptureSession alloc] init];
    self.session.sessionPreset = AVCaptureSessionPresetHigh;
    
    if ([self.session canAddInput:self.input]) {
        [self.session addInput:self.input];
    }
    if ([self.session canAddOutput:self.stillImageOutput]) {
        [self.session addOutput:self.stillImageOutput];
    }
    
//    CGSize size = self.view.bounds.size;
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
    self.previewLayer.frame = self.view.bounds;
    [self.view.layer addSublayer:self.previewLayer];
    
    self.previewLayer.frame = self.view.bounds;
    
    [self.view.layer addSublayer:self.previewLayer];
    
    self.bgView = [[HollowOutView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.bgView];
    
    // start
    [self.session startRunning];
}

- (AVCaptureVideoOrientation)videoOrientationFromCurrentDeviceOrientation {
    AVCaptureVideoOrientation orientation = AVCaptureVideoOrientationLandscapeRight;
    switch (self.interfaceOrientation) {
        case UIInterfaceOrientationPortrait: {
            orientation =  AVCaptureVideoOrientationPortrait;
        }
            break;
        case UIInterfaceOrientationLandscapeLeft: {
            orientation = AVCaptureVideoOrientationLandscapeLeft;
        }
            break;
        case UIInterfaceOrientationLandscapeRight: {
            orientation = AVCaptureVideoOrientationLandscapeRight;
        }
            break;
        case UIInterfaceOrientationPortraitUpsideDown: {
            orientation = AVCaptureVideoOrientationPortraitUpsideDown;
        }
            break;
        default:
            break;
    }
    return orientation;
}

#pragma mark - ModifyCameraSettings
- (void)onHitBtnSwitchCamera:(id)sender {
    AVCaptureDevicePosition cameraPosition;
    if (_isFrontCamera) {
        cameraPosition = AVCaptureDevicePositionFront;
    } else {
        cameraPosition = AVCaptureDevicePositionBack;
    }
    for (AVCaptureDevice *d in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
        if ([d position] == cameraPosition) {
            [self.previewLayer.session beginConfiguration];
            AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:d error:nil];
            for (AVCaptureInput *oldInput in self.previewLayer.session.inputs) {
                [[self.previewLayer session] removeInput:oldInput];
            }
            [self.previewLayer.session addInput:input];
            [self.previewLayer.session commitConfiguration];
            break;
        }
    }
    _isFrontCamera = !_isFrontCamera;
}

#pragma mark - TakePhoto
- (void)onHitBtnTakePhoto:(id)sender {
    AVCaptureConnection *stillImageConnection = [self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
    UIDeviceOrientation curDeviceOrientation = [[UIDevice currentDevice] orientation];
    AVCaptureVideoOrientation avcaptureOrientation = [self avOrientationForDeviceOrientation:curDeviceOrientation];
    [stillImageConnection setVideoOrientation:avcaptureOrientation];
    [stillImageConnection setVideoScaleAndCropFactor:1];
    
    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:stillImageConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        
        NSData *jpegData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
        CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault,
                                                                    imageDataSampleBuffer,
                                                                    kCMAttachmentMode_ShouldPropagate);
        
        ALAuthorizationStatus author = [ALAssetsLibrary authorizationStatus];
        if (author == ALAuthorizationStatusRestricted || author == ALAuthorizationStatusDenied){
            //无权限
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"相册授权" message:@"没有获得相册授权，无法保存照片到相册" delegate:self cancelButtonTitle:@"取消" otherButtonTitles: nil];
            [alertView show];
            return ;
        }
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
     
        // TODO:test，测试为看照片，加入提示框，展示照片
        NSString *space = @"\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n";
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"" message:space preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            // 将图片保存到相册
            [library writeImageDataToSavedPhotosAlbum:jpegData metadata:(__bridge id)attachments completionBlock:^(NSURL *assetURL, NSError *error) {
                
            }];
        }];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        }];
        [alertController addAction:confirmAction];
        [alertController addAction:cancelAction];
    
        // width = 270;
        CGFloat imgViewWidth = 270 - 2*15;
        UIImageView *alertImageView = [[UIImageView alloc] initWithFrame:CGRectMake(15, 15, imgViewWidth, imgViewWidth*4/3)];
        // 裁剪照片
        UIImage *imageTem = [UIImage imageWithData:jpegData];
        CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
        CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
        CGFloat margionLeft = 15;
        CGFloat holeWidth = screenWidth - 2*margionLeft;
        CGFloat holeHeight = holeWidth * 4/3;
        CGRect rect = CGRectMake(margionLeft, (screenHeight - holeWidth)/2, holeWidth, holeHeight);
//        alertImageView.image = [self clipImageWithOriginalImage:imageTem inRect:rect];
        alertImageView.image = [UIImage imageWithData:jpegData];
        [alertController.view addSubview:alertImageView];
        [self presentViewController:alertController animated:YES completion:nil];
    }];
}

-(AVCaptureVideoOrientation)avOrientationForDeviceOrientation:(UIDeviceOrientation)deviceOrientation
{
    AVCaptureVideoOrientation result = (AVCaptureVideoOrientation)deviceOrientation;
    if ( deviceOrientation == UIDeviceOrientationLandscapeLeft )
        result = AVCaptureVideoOrientationLandscapeRight;
    else if ( deviceOrientation == UIDeviceOrientationLandscapeRight )
        result = AVCaptureVideoOrientationLandscapeLeft;
    return result;
}

- (UIImage *)clipImageWithOriginalImage:(UIImage *)image inRect:(CGRect)rect {
    //将UIImage转换成CGImageRef
    CGImageRef sourceImageRef = [image CGImage];
    //按照给定的矩形区域进行剪裁
    CGImageRef newImageRef = CGImageCreateWithImageInRect(sourceImageRef, rect);
    //将CGImageRef转换成UIImage
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef];
    //返回剪裁后的图片
    return newImage;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
