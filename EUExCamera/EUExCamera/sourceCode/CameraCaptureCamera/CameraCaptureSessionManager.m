//
//  CameraCaptureSessionManager.m
//  EUExCamera
//
//  Created by zywx on 16/1/22.
//  Copyright © 2016年 zywx. All rights reserved.
//

#import "CameraCaptureSessionManager.h"
#import <ImageIO/ImageIO.h>
#import "UIImage+CameraResize.h"
#import "CameraCommon.h"
#import "CameraInternationalization.h"

@interface CameraCaptureSessionManager ()


@property (nonatomic, strong) UIView *preview;

@end


@implementation CameraCaptureSessionManager

#pragma mark -
#pragma mark configure

- (id)init {
    
    self = [super init];
    
    if (self != nil) {
        
        _scaleNum = 1.f;
        
        _preScaleNum = 1.f;
        
    }
    
    return self;
    
}

- (void)configureWithParentLayer:(UIView*)parent previewRect:(CGRect)preivewRect {
    
    self.preview = parent;
    
    //1、队列
    [self createQueue];
    
    //2、session
    [self addSession];
    
    //3、previewLayer
    [self addVideoPreviewLayerWithRect:preivewRect];
    
    [parent.layer addSublayer:_previewLayer];
    
    //4、input
    [self addVideoInputFrontCamera:NO];
    
    //5、output
    [self addStillImageOutput];
    
    //    //6、preview imageview
    //    [self addPreviewImageView];
    
    //    //6、default flash mode
    //    [self switchFlashMode:nil];
    
    //    //7、default focus mode
    //    [self setDefaultFocusMode];
}

/**
 *  创建一个队列，防止阻塞主线程
 */
- (void)createQueue {
    
    dispatch_queue_t sessionQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL);
    
    self.sessionQueue = sessionQueue;
    
}

/**
 *  session
 */
- (void)addSession {
    
    AVCaptureSession *tmpSession = [[AVCaptureSession alloc] init];
    
    self.session = tmpSession;
    
    //设置质量
    //  _session.sessionPreset = AVCaptureSessionPresetPhoto;
    
}

/**
 *  相机的实时预览页面
 *
 *  @param previewRect 预览页面的frame
 */
- (void)addVideoPreviewLayerWithRect:(CGRect)previewRect {
    
    AVCaptureVideoPreviewLayer *preview = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_session];
    
    preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    preview.frame = previewRect;
    
    self.previewLayer = preview;
    
}

/**
 *  添加输入设备
 *
 *  @param front 前或后摄像头
 */
- (void)addVideoInputFrontCamera:(BOOL)front {
    
    NSArray *devices = [AVCaptureDevice devices];
    
    AVCaptureDevice *frontCamera;
    
    AVCaptureDevice *backCamera;
    
    for (AVCaptureDevice *device in devices) {
        
        if ([device hasMediaType:AVMediaTypeVideo]) {
            
            if ([device position] == AVCaptureDevicePositionBack) {
                
                SCDLog(@"Device position : back");
                
                backCamera = device;
                
                
            }  else {
                
                SCDLog(@"Device position : front");
                
                frontCamera = device;
                
            }
            
        }
        
    }
    
    NSError *error = nil;
    
    if (front) {
        
        AVCaptureDeviceInput *frontFacingCameraDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:frontCamera error:&error];
        
        if (!error) {
            
            if ([_session canAddInput:frontFacingCameraDeviceInput]) {
                
                [_session addInput:frontFacingCameraDeviceInput];
                
                self.inputDevice = frontFacingCameraDeviceInput;
                
            } else {
                
                SCDLog(@"Couldn't add front facing video input");
                
            }
            
        }
        
    } else {
        
        AVCaptureDeviceInput *backFacingCameraDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:backCamera error:&error];
        
        if (!error) {
            
            if ([_session canAddInput:backFacingCameraDeviceInput]) {
                
                [_session addInput:backFacingCameraDeviceInput];
                
                self.inputDevice = backFacingCameraDeviceInput;
                
            } else {
                
                SCDLog(@"Couldn't add back facing video input");
                
            }
            
        }
        
    }
    
}

/**
 *  添加输出设备
 */
- (void)addStillImageOutput {
    
    AVCaptureStillImageOutput *tmpOutput = [[AVCaptureStillImageOutput alloc] init];
    
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG,AVVideoCodecKey,nil];//输出jpeg
    
    tmpOutput.outputSettings = outputSettings;
    
    //    AVCaptureConnection *videoConnection = [self findVideoConnection];
    
    [_session addOutput:tmpOutput];
    
    self.stillImageOutput = tmpOutput;
    
}

/**
 *  拍完照片后预览图片
 */
//- (void)addPreviewImageView {

//    CGFloat headHeight = _previewLayer.bounds.size.height - SC_APP_SIZE.width;

//    CGRect imageFrame = _previewLayer.bounds;

//    imageFrame.origin.y = headHeight;
//
//    UIImageView *imgView = [[UIImageView alloc] initWithFrame:imageFrame];

//    imgView.contentMode = UIViewContentModeScaleAspectFill;

//    [_preview addSubview:imgView];

//    self.imageView = imgView;

//}

#pragma mark - actions

/**
 *  拍照
 */
- (void)takePicture:(DidCapturePhotoBlock)block {
    
    AVCaptureConnection *videoConnection = [self findVideoConnection];
    
    //	UIDeviceOrientation curDeviceOrientation = [[UIDevice currentDevice] orientation];
    
    //	AVCaptureVideoOrientation avcaptureOrientation = [self avOrientationForDeviceOrientation:curDeviceOrientation];
    
    //    [videoConnection setVideoOrientation:avcaptureOrientation];
    
    [videoConnection setVideoScaleAndCropFactor:_scaleNum];
    
    SCDLog(@"about to request a capture from: %@", _stillImageOutput);
    
    [_stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        
         NSLog(@"takePicture==>>error1=%@",error);
        
        if (error || !imageDataSampleBuffer) {
            
            NSLog(@"takePicture==>>error2=%@",error);
            
            NSLog(@"takePicture==>>imageDataSampleBuffer=%@",imageDataSampleBuffer);
            
        }
        
        CFDictionaryRef exifAttachments = CMGetAttachment(imageDataSampleBuffer, kCGImagePropertyExifDictionary, NULL);
        
        if (exifAttachments) {
            
            SCDLog(@"attachements: %@", exifAttachments);
            
        } else {
            
            SCDLog(@"no attachments");
            
        }
        
        NSData *imageData = nil;
        
        if (!error) {
            
            imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
            
        }
        
        UIImage *image = [[UIImage alloc] initWithData:imageData];
        
        SCDLog(@"originImage:%@", [NSValue valueWithCGSize:image.size]);
        
        //        [SCCommon saveImageToPhotoAlbum:image];
        
        CGFloat squareLength = SC_APP_SIZE.width;
        
        CGFloat headHeight = _previewLayer.bounds.size.height - squareLength;//_previewLayer的frame是(0, 44, 320, 320 + 44)
        
        CGSize size = CGSizeMake(squareLength * 2, squareLength * 2);
        
        UIImage *scaledImage = [image resizedImageWithContentMode:UIViewContentModeScaleAspectFill bounds:size interpolationQuality:kCGInterpolationHigh];
        
        SCDLog(@"scaledImage:%@", [NSValue valueWithCGSize:scaledImage.size]);
        
        CGRect cropFrame = CGRectMake((scaledImage.size.width - size.width) / 2, (scaledImage.size.height - size.height) / 2 + headHeight, size.width, size.height);
        
        SCDLog(@"cropFrame:%@", [NSValue valueWithCGRect:cropFrame]);
        
        UIImage *croppedImage = [scaledImage croppedImage:cropFrame];
        
        SCDLog(@"croppedImage:%@", [NSValue valueWithCGSize:croppedImage.size]);
        
        UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
        
        if (orientation != UIDeviceOrientationPortrait) {
            
            CGFloat degree = 0;
            
            if (orientation == UIDeviceOrientationPortraitUpsideDown) {
                
                degree = 180;// M_PI;
                
            } else if (orientation == UIDeviceOrientationLandscapeLeft) {
                
                degree = -90;// -M_PI_2;
                
            } else if (orientation == UIDeviceOrientationLandscapeRight) {
                
                degree = 90;// M_PI_2;
            }
            
            croppedImage = [croppedImage rotatedByDegrees:degree];
            
        }
        
        if (block) {
            
            block(croppedImage);
            
        } else if ([_delegate respondsToSelector:@selector(didCapturePhoto:)]) {
            
            [_delegate didCapturePhoto:croppedImage];
            
        } else {
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kCapturedPhotoSuccessfully object:croppedImage];
            
        }
        
    }];
}

- (AVCaptureVideoOrientation)avOrientationForDeviceOrientation:(UIDeviceOrientation)deviceOrientation {
    
    AVCaptureVideoOrientation result = (AVCaptureVideoOrientation)deviceOrientation;
    
    if ( deviceOrientation == UIDeviceOrientationLandscapeLeft )
        
        result = AVCaptureVideoOrientationLandscapeRight;
    
    else if ( deviceOrientation == UIDeviceOrientationLandscapeRight )
        
        result = AVCaptureVideoOrientationLandscapeLeft;
    
    return result;
    
}

/**
 *  切换前后摄像头
 *
 *  @param isFrontCamera YES:前摄像头  NO:后摄像头
 */
- (NSString *)switchCamera:(NSString *)cameraPosition {
    
    if (!_inputDevice) {
        
        return @"-1";
        
    }
    
    [_session beginConfiguration];
    
    [_session removeInput:_inputDevice];
    
    BOOL isFrontCamera;
    
    if ([cameraPosition isEqualToString:@"1"]) {
        
        isFrontCamera = YES;
        
    }else {
        
        isFrontCamera = NO;
        
    }
    
    [self addVideoInputFrontCamera:isFrontCamera];
    
    [_session commitConfiguration];
    
    return cameraPosition;
    
}

/**
 *  拉近拉远镜头
 *
 *  @param scale 拉伸倍数
 */
- (void)pinchCameraViewWithScalNum:(CGFloat)scale {
    
    _scaleNum = scale;
    
    if (_scaleNum < MIN_PINCH_SCALE_NUM) {
        
        _scaleNum = MIN_PINCH_SCALE_NUM;
        
    } else if (_scaleNum > MAX_PINCH_SCALE_NUM) {
        
        _scaleNum = MAX_PINCH_SCALE_NUM;
        
    }
    
    [self doPinch];
    
    _preScaleNum = scale;
    
}

- (void)pinchCameraView:(UIPinchGestureRecognizer *)gesture {
    
    BOOL allTouchesAreOnThePreviewLayer = YES;
    
    NSUInteger numTouches = [gesture numberOfTouches], i;
    
    for ( i = 0; i < numTouches; ++i ) {
        
        CGPoint location = [gesture locationOfTouch:i inView:_preview];
        
        CGPoint convertedLocation = [_previewLayer convertPoint:location fromLayer:_previewLayer.superlayer];
        
        if ( ! [_previewLayer containsPoint:convertedLocation] ) {
            
            allTouchesAreOnThePreviewLayer = NO;
            
            break;
            
        }
        
    }
    
    if ( allTouchesAreOnThePreviewLayer ) {
        
        _scaleNum = _preScaleNum * gesture.scale;
        
        if (_scaleNum < MIN_PINCH_SCALE_NUM) {
            
            _scaleNum = MIN_PINCH_SCALE_NUM;
            
        } else if (_scaleNum > MAX_PINCH_SCALE_NUM) {
            
            _scaleNum = MAX_PINCH_SCALE_NUM;
            
        }
        
        [self doPinch];
        
    }
    
    if ([gesture state] == UIGestureRecognizerStateEnded ||
        [gesture state] == UIGestureRecognizerStateCancelled ||
        [gesture state] == UIGestureRecognizerStateFailed) {
        
        _preScaleNum = _scaleNum;
        
        SCDLog(@"final scale: %f", _scaleNum);
        
    }
    
}

- (void)doPinch {
    
    //    AVCaptureStillImageOutput* output = (AVCaptureStillImageOutput*)[_session.outputs objectAtIndex:0];
    //    AVCaptureConnection *videoConnection = [output connectionWithMediaType:AVMediaTypeVideo];
    
    AVCaptureConnection *videoConnection = [self findVideoConnection];
    
    CGFloat maxScale = videoConnection.videoMaxScaleAndCropFactor;//videoScaleAndCropFactor这个属性取值范围是1.0-videoMaxScaleAndCropFactor。iOS5+才可以用
    
    if (_scaleNum > maxScale) {
        
        _scaleNum = maxScale;
        
    }
    
    //    videoConnection.videoScaleAndCropFactor = _scaleNum;
    
    [CATransaction begin];
    
    [CATransaction setAnimationDuration:.025];
    
    [_previewLayer setAffineTransform:CGAffineTransformMakeScale(_scaleNum, _scaleNum)];
    
    [CATransaction commit];
    
}

/**
 *  切换闪光灯模式
 *  0代表自动，1代表打开闪光灯，2代表关闭闪光灯
 *  @param flashMode
 */
- (NSString *)switchFlashMode:(NSString *)flashMode {
    
    Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
    
    if (!captureDeviceClass) {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:kInternationalization(@"prompt") message:kInternationalization(@"noCamera") delegate:nil cancelButtonTitle:NSLocalizedString(@"Sure", nil) otherButtonTitles: nil];
        
        [alert show];
        
        return @"-1";
        
    }
    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    [device lockForConfiguration:nil];
    
    if ([device hasFlash]) {
        
        if ([flashMode isEqualToString:@"0"]) {
            
            device.flashMode = AVCaptureFlashModeAuto;
            
            
        } else if ([flashMode isEqualToString:@"1"]) {
            
            device.flashMode = AVCaptureFlashModeOn;
            
            
        } else if ([flashMode isEqualToString:@"2"]) {
            
            device.flashMode = AVCaptureFlashModeOff;
            
        }
        
    } else {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:kInternationalization(@"prompt") message:kInternationalization(@"noFlash") delegate:nil cancelButtonTitle:kInternationalization(@"cancel") otherButtonTitles: nil];
        
        [alert show];
        
        return @"-1";
        
    }
    
    [device unlockForConfiguration];
    
    return flashMode;
    
}

- (void)switchFlashButton:(UIButton*)sender {
    
    Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
    
    if (!captureDeviceClass) {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:kInternationalization(@"prompt") message:kInternationalization(@"noCamera") delegate:nil cancelButtonTitle:NSLocalizedString(@"Sure", nil) otherButtonTitles: nil];
        
        [alert show];
        
        return;
        
    }
    
    NSString *imgStr = @"";
    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    [device lockForConfiguration:nil];
    
    if ([device hasFlash]) {
        
        //        if (!sender) {//设置默认的闪光灯模式
        //            device.flashMode = AVCaptureFlashModeAuto;
        //        } else {
        if (device.flashMode == AVCaptureFlashModeOff) {
            
            device.flashMode = AVCaptureFlashModeOn;
            
            imgStr = @"flashing_on";
            
        } else if (device.flashMode == AVCaptureFlashModeOn) {
            
            device.flashMode = AVCaptureFlashModeAuto;
            
            imgStr = @"flashing_auto";
            
        } else if (device.flashMode == AVCaptureFlashModeAuto) {
            
            device.flashMode = AVCaptureFlashModeOff;
            
            imgStr = @"flashing_off";
            
        }
        //        }
        
        if (sender) {
            
            [sender setImage:[CameraInternationalization getImageFromLocalFile:imgStr type:@"png"] forState:UIControlStateNormal];
            
        }
        
    } else {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:kInternationalization(@"prompt") message:kInternationalization(@"noFlash") delegate:nil cancelButtonTitle:kInternationalization(@"cancel") otherButtonTitles: nil];
        
        [alert show];
        
    }
    
    [device unlockForConfiguration];
    
}


/**
 *  点击后对焦
 *
 *  @param devicePoint 点击的point
 */
- (void)focusInPoint:(CGPoint)devicePoint {
    
    //    if (CGRectContainsPoint(_previewLayer.bounds, devicePoint) == NO) {
    //        return;
    //    }
    
    devicePoint = [self convertToPointOfInterestFromViewCoordinates:devicePoint];
    
    [self focusWithMode:AVCaptureFocusModeAutoFocus exposeWithMode:AVCaptureExposureModeContinuousAutoExposure atDevicePoint:devicePoint monitorSubjectAreaChange:YES];
    
}

- (void)focusWithMode:(AVCaptureFocusMode)focusMode exposeWithMode:(AVCaptureExposureMode)exposureMode atDevicePoint:(CGPoint)point monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange {
    
    dispatch_async(_sessionQueue, ^{
        
        AVCaptureDevice *device = [_inputDevice device];
        
        NSError *error = nil;
        
        if ([device lockForConfiguration:&error]) {
            
            if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:focusMode]) {
                
                [device setFocusMode:focusMode];
                
                [device setFocusPointOfInterest:point];
                
            }
            if ([device isExposurePointOfInterestSupported] && [device isExposureModeSupported:exposureMode]) {
                
                [device setExposureMode:exposureMode];
                
                [device setExposurePointOfInterest:point];
                
            }
            
            [device setSubjectAreaChangeMonitoringEnabled:monitorSubjectAreaChange];
            
            [device unlockForConfiguration];
            
        }
        
        else {
            
            SCDLog(@"%@", error);
            
        }
        
    });
    
}

- (void)subjectAreaDidChange:(NSNotification *)notification {
    
    CGPoint devicePoint = CGPointMake(.5, .5);
    
    [self focusWithMode:AVCaptureFocusModeContinuousAutoFocus exposeWithMode:AVCaptureExposureModeContinuousAutoExposure atDevicePoint:devicePoint monitorSubjectAreaChange:NO];
    
}

/**
 *  外部的point转换为camera需要的point(外部point/相机页面的frame)
 *
 *  @param viewCoordinates 外部的point
 *
 *  @return 相对位置的point
 */
- (CGPoint)convertToPointOfInterestFromViewCoordinates:(CGPoint)viewCoordinates {
    
    CGPoint pointOfInterest = CGPointMake(.5f, .5f);
    
    CGSize frameSize = _previewLayer.bounds.size;
    
    AVCaptureVideoPreviewLayer *videoPreviewLayer = self.previewLayer;
    
    if([[videoPreviewLayer videoGravity]isEqualToString:AVLayerVideoGravityResize]) {
        
        pointOfInterest = CGPointMake(viewCoordinates.y / frameSize.height, 1.f - (viewCoordinates.x / frameSize.width));
        
    } else {
        
        CGRect cleanAperture;
        
        for(AVCaptureInputPort *port in [[self.session.inputs lastObject]ports]) {
            
            if([port mediaType] == AVMediaTypeVideo) {
                
                cleanAperture = CMVideoFormatDescriptionGetCleanAperture([port formatDescription], YES);
                
                CGSize apertureSize = cleanAperture.size;
                
                CGPoint point = viewCoordinates;
                
                CGFloat apertureRatio = apertureSize.height / apertureSize.width;
                
                CGFloat viewRatio = frameSize.width / frameSize.height;
                
                CGFloat xc = .5f;
                
                CGFloat yc = .5f;
                
                if([[videoPreviewLayer videoGravity]isEqualToString:AVLayerVideoGravityResizeAspect]) {
                    
                    if(viewRatio > apertureRatio) {
                        
                        CGFloat y2 = frameSize.height;
                        
                        CGFloat x2 = frameSize.height * apertureRatio;
                        
                        CGFloat x1 = frameSize.width;
                        
                        CGFloat blackBar = (x1 - x2) / 2;
                        
                        if(point.x >= blackBar && point.x <= blackBar + x2) {
                            
                            xc = point.y / y2;
                            
                            yc = 1.f - ((point.x - blackBar) / x2);
                            
                        }
                        
                    } else {
                        
                        CGFloat y2 = frameSize.width / apertureRatio;
                        
                        CGFloat y1 = frameSize.height;
                        
                        CGFloat x2 = frameSize.width;
                        
                        CGFloat blackBar = (y1 - y2) / 2;
                        
                        if(point.y >= blackBar && point.y <= blackBar + y2) {
                            
                            xc = ((point.y - blackBar) / y2);
                            
                            yc = 1.f - (point.x / x2);
                            
                        }
                        
                    }
                    
                } else if([[videoPreviewLayer videoGravity]isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
                    
                    if(viewRatio > apertureRatio) {
                        
                        CGFloat y2 = apertureSize.width * (frameSize.width / apertureSize.height);
                        
                        xc = (point.y + ((y2 - frameSize.height) / 2.f)) / y2;
                        
                        yc = (frameSize.width - point.x) / frameSize.width;
                        
                    } else {
                        
                        CGFloat x2 = apertureSize.height * (frameSize.height / apertureSize.width);
                        
                        yc = 1.f - ((point.x + ((x2 - frameSize.width) / 2)) / x2);
                        
                        xc = point.y / frameSize.height;
                        
                    }
                    
                }
                
                pointOfInterest = CGPointMake(xc, yc);
                
                break;
                
            }
            
        }
        
    }
    
    return pointOfInterest;
}

/**
 *  显示/隐藏网格
 *
 *  @param toShow 显示或隐藏
 */
- (void)switchGrid:(BOOL)toShow {
    
    if (!toShow) {
        
        NSArray *layersArr = [NSArray arrayWithArray:_preview.layer.sublayers];
        
        for (CALayer *layer in layersArr) {
            
            if (layer.frame.size.width == 1 || layer.frame.size.height == 1) {
                
                [layer removeFromSuperlayer];
                
            }
            
        }
        
        return;
        
    }
    
    CGFloat headHeight = _previewLayer.bounds.size.height - SC_APP_SIZE.width;
    
    CGFloat squareLength = SC_APP_SIZE.width;
    
    CGFloat eachAreaLength = squareLength / 3;
    
    for (int i = 0; i < 4; i++) {
        
        CGRect frame = CGRectZero;
        
        if (i == 0 || i == 1) {//画横线
            
            frame = CGRectMake(0, headHeight + (i + 1) * eachAreaLength, squareLength, 1);
            
        } else {
            
            frame = CGRectMake((i + 1 - 2) * eachAreaLength, headHeight, 1, squareLength);
            
        }
        
        [CameraCommon drawALineWithFrame:frame andColor:[UIColor whiteColor] inLayer:_preview.layer];
        
    }
    
}


#pragma mark ---------------private--------------

- (AVCaptureConnection*)findVideoConnection {
    
    AVCaptureConnection *videoConnection = nil;
    
    for (AVCaptureConnection *connection in _stillImageOutput.connections) {
        
        for (AVCaptureInputPort *port in connection.inputPorts) {
            
            if ([[port mediaType] isEqual:AVMediaTypeVideo]) {
                
                videoConnection = connection;
                
                break;
                
            }
            
        }
        
        if (videoConnection) {
            
            break;
            
        }
        
    }
    
    return videoConnection;
    
}


@end
