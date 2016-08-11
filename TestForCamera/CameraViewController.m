//
//  CameraViewController.m
//  TestForCamera
//
//  Created by dvt04 on 16/8/10.
//  Copyright © 2016年 suma. All rights reserved.
//

#import "CameraViewController.h"
#import "HollowOutView.h"
#import "UIImage+ClipImage.h"
#import "CameraToolBarView.h"
#import "UIActionSheet+Blocks.h"

@interface CameraViewController ()

@property (nonatomic, strong) AVCaptureDevice *device;
@property (nonatomic, strong) AVCaptureDeviceInput *input;
@property (nonatomic, strong) AVCaptureStillImageOutput *stillImageOutput;
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, strong) HollowOutView *bgView;
@property (nonatomic, strong) CameraToolBarView *toolBarView;

@end

@implementation CameraViewController
{
    BOOL _isFrontCamera;
    CGFloat _beginGestureScale;
    CGFloat _effectiveScale;
    CGFloat _compressionQuality;    // ImageCompressionQuality
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
    self.toolBarView = [[CameraToolBarView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    [self.navigationController.navigationBar addSubview:self.toolBarView];
    [self.toolBarView.btnSnap addTarget:self action:@selector(onHitBtnTakePhoto:) forControlEvents:UIControlEventTouchUpInside];
    [self.toolBarView.btnSwitchCamera addTarget:self action:@selector(onHitBtnSwitchCamera:) forControlEvents:UIControlEventTouchUpInside];
    [self.toolBarView.btnImageCompress addTarget:self action:@selector(onHitBtnChangeImageCompressQuality:) forControlEvents:UIControlEventTouchUpInside];
    [self.toolBarView.btnSessionPreset addTarget:self action:@selector(onHitBtnChangeAVCaptureSessionPreset:) forControlEvents:UIControlEventTouchUpInside];
    
    // 添加缩放手势调整焦距
    UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
    pinchGesture.delegate = self;
    [self.view addGestureRecognizer:pinchGesture];
    
    _beginGestureScale = 1.0;
    _effectiveScale = 1.0;
    _isFrontCamera = NO;
    _compressionQuality = 1;
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
    // 分辨率
//    self.session.sessionPreset = AVCaptureSessionPresetHigh;
    
    if ([self.session canAddInput:self.input]) {
        [self.session addInput:self.input];
    }
    if ([self.session canAddOutput:self.stillImageOutput]) {
        [self.session addOutput:self.stillImageOutput];
    }
    
//    CGSize size = self.view.bounds.size;
    AVCaptureConnection *output2VideoConnection = [self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
    output2VideoConnection.videoOrientation = [self videoOrientationFromCurrentDeviceOrientation];
    
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    self.previewLayer.connection.videoOrientation = [self videoOrientationFromCurrentDeviceOrientation];
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

#pragma mark - CameraSettings
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

- (void)onHitBtnChangeAVCaptureSessionPreset:(id)sender {
    /*
     AVCaptureSessionPreset共11种，仅列举Photo,high,medium,low,inputpriority
     NSString *const  AVCaptureSessionPresetPhoto;
     NSString *const  AVCaptureSessionPresetHigh;
     NSString *const  AVCaptureSessionPresetMedium;
     NSString *const  AVCaptureSessionPresetLow;
     NSString *const  AVCaptureSessionPreset352x288;
     NSString *const  AVCaptureSessionPreset640x480;
     NSString *const  AVCaptureSessionPreset1280x720;
     NSString *const  AVCaptureSessionPreset1920x1080;
     NSString *const  AVCaptureSessionPresetiFrame960x540;
     NSString *const  AVCaptureSessionPresetiFrame1280x720;
     NSString *const  AVCaptureSessionPresetInputPriority;
     */
    [UIActionSheet showInView:self.bgView withTitle:@"选择分辨率" cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@[@"AVCaptureSessionPresetPhoto",@"AVCaptureSessionPresetHigh",@"AVCaptureSessionPresetMedium",@"AVCaptureSessionPresetLow",@"AVCaptureSessionPresetInputPriority"] tapBlock:^(UIActionSheet * _Nonnull actionSheet, NSInteger buttonIndex) {
        if (buttonIndex == 0) {
            [self.session beginConfiguration];
            self.session.sessionPreset = AVCaptureSessionPresetPhoto;
            [self.session commitConfiguration];
        } else if (buttonIndex == 1) {
            [self.session beginConfiguration];
            self.session.sessionPreset = AVCaptureSessionPresetHigh;
            [self.session commitConfiguration];
        } else if (buttonIndex == 2) {
            [self.session beginConfiguration];
            self.session.sessionPreset = AVCaptureSessionPresetMedium;
            [self.session commitConfiguration];
        } else if (buttonIndex == 3) {
            [self.session beginConfiguration];
            self.session.sessionPreset = AVCaptureSessionPresetLow;
            [self.session commitConfiguration];
        } else if (buttonIndex == 4) {
            [self.session beginConfiguration];
            self.session.sessionPreset = AVCaptureSessionPresetInputPriority;
            [self.session commitConfiguration];
        }
    }];
}

- (void)onHitBtnChangeImageCompressQuality:(id)sender {
    [UIActionSheet showInView:self.bgView withTitle:@"选择图片压缩比" cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@[@"0",@"0.5",@"1"] tapBlock:^(UIActionSheet * _Nonnull actionSheet, NSInteger buttonIndex) {
        if (buttonIndex == 0) {
            _compressionQuality = 0;
        } else if (buttonIndex == 0.5) {
            _compressionQuality = 0.5;
        } else if (buttonIndex == 1) {
            _compressionQuality = 1;
        }
    }];
}

- (void)handlePinchGesture:(UIPinchGestureRecognizer *)recognizer {
    // 缩放手势，调整焦距
    BOOL allTouchesAreOnThePreviewLayer = YES;
    NSUInteger numTouches = [recognizer numberOfTouches], i;
    for ( i = 0; i < numTouches; ++i ) {
        CGPoint location = [recognizer locationOfTouch:i inView:self.bgView];
        CGPoint convertedLocation = [self.previewLayer convertPoint:location fromLayer:self.previewLayer.superlayer];
        if ( ! [self.previewLayer containsPoint:convertedLocation] ) {
            allTouchesAreOnThePreviewLayer = NO;
            break;
        }
    }
    
    if ( allTouchesAreOnThePreviewLayer ) {
        
        
        _effectiveScale = _beginGestureScale * recognizer.scale;
        if (_effectiveScale < 1.0){
            _effectiveScale = 1.0;
        }
        
        NSLog(@"%f-------------->%f------------recognizerScale%f",_effectiveScale,_beginGestureScale,recognizer.scale);
        
        CGFloat maxScaleAndCropFactor = [[self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo] videoMaxScaleAndCropFactor];
        
        NSLog(@"%f",maxScaleAndCropFactor);
        if (_effectiveScale > maxScaleAndCropFactor)
            _effectiveScale = maxScaleAndCropFactor;
        
        [CATransaction begin];
        [CATransaction setAnimationDuration:.025];
        [self.previewLayer setAffineTransform:CGAffineTransformMakeScale(_effectiveScale, _effectiveScale)];
        [CATransaction commit];
        
    }
}

#pragma mark - TakePhoto
- (void)onHitBtnTakePhoto:(id)sender {
    AVCaptureConnection *stillImageConnection = [self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
    UIDeviceOrientation curDeviceOrientation = [[UIDevice currentDevice] orientation];
    AVCaptureVideoOrientation avcaptureOrientation = [self avOrientationForDeviceOrientation:curDeviceOrientation];
    [stillImageConnection setVideoOrientation:avcaptureOrientation];
    // 控制焦距
    [stillImageConnection setVideoScaleAndCropFactor:_effectiveScale];
    
    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:stillImageConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        
        NSData *jpegData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
        CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault,
                                                                    imageDataSampleBuffer,
                                                                    kCMAttachmentMode_ShouldPropagate);
        // 判断相册权限
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
        // width = 270;
        CGFloat imgViewWidth = 270 - 2*15;
        UIImageView *alertImageView = [[UIImageView alloc] initWithFrame:CGRectMake(15, 15, imgViewWidth, imgViewWidth*4/3)];
        // 裁剪照片
        CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
        CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
        CGFloat margionLeft = 15;
        CGFloat holeWidth = screenWidth - 2*margionLeft;
        CGFloat holeHeight = holeWidth * 4/3;
        CGRect rect = CGRectMake(margionLeft, (screenHeight-holeHeight)/2, holeWidth, holeHeight);
        // TODO:  此时得到的image的scale为1，imageOrientation为right
        UIImage *imageTem = [UIImage imageWithData:jpegData scale:1];
        // 重绘image
        UIGraphicsBeginImageContext(CGSizeMake(self.view.frame.size.width, self.view.frame.size.height));
        [imageTem drawInRect:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
        imageTem = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        // 裁剪图片
        UIImage *clippedImage = [UIImage cropImageWithImage:imageTem inRect:rect];
        alertImageView.image = clippedImage;
        [alertController.view addSubview:alertImageView];

        // 保存裁剪后的图片到相册
        // TODO：照片保存到相册之前需要旋转
        jpegData = UIImageJPEGRepresentation(clippedImage, 1);
        
        // set UIAlertAction
        UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            // 将图片保存到相册
            [library writeImageDataToSavedPhotosAlbum:jpegData metadata:(__bridge id)attachments completionBlock:^(NSURL *assetURL, NSError *error) {
            
            }];
        }];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        }];
        [alertController addAction:confirmAction];
        [alertController addAction:cancelAction];
    
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

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if ( [gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]] ) {
        _beginGestureScale = _effectiveScale;
    }
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
