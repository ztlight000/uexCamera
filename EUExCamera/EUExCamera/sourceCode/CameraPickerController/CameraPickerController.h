//
//  CameraPickerController.h
//  EUExCamera
//
//  Created by zywx on 16/1/25.
//  Copyright © 2016年 zywx. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CameraCaptureSessionManager.h" 
@class EUExCamera;
@class EBrowserView;

@interface CameraPickerController : UIViewController<CloseCaptureCameraDelegate>


@property (nonatomic, assign) CGRect previewRect;
@property (nonatomic, assign) BOOL isStatusBarHiddenBeforeShowCamera;
@property (nonatomic, assign) EBrowserView *meBrwView;
@property (nonatomic, weak) EUExCamera *uexObj;
@property (nonatomic, assign) CGFloat scale;
@property (nonatomic, assign) BOOL isCompress;
@property (nonatomic, assign) BOOL isAction;

//@property (nonatomic, assign) id<CloseCaptureCameraDelegate> closeCameraDelegate;

@end
