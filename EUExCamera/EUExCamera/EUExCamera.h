//
//  EUExCamera.h
//  AppCan
//
//  Created by AppCan on 11-8-26.
//  Copyright 2011 AppCan. All rights reserved.

#import "EUExBase.h"


@class CameraCaptureCamera;
@class CameraPickerController;
@protocol CloseCaptureCameraDelegate <NSObject>
@optional
- (void)CloseCamera;
- (void)CloseCameraPicker;

@end
@interface EUExCamera : EUExBase  <CloseCaptureCameraDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate>{
    BOOL isCompress;//是否压缩
    float scale;//缩放比例
}
@property (nonatomic, strong) CameraCaptureCamera *captureCameraView;
@property (nonatomic, strong) UIImagePickerController * imagePickerController;
-(void)uexSuccessWithOpId:(int)inOpId dataType:(int)inDataType data:(NSString *)inData;
- (void)removeViewCameraFromWindow;
@end
