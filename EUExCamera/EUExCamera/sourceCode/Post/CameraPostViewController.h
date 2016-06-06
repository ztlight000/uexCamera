//
//  CameraPostViewController.h
//  CameraCaptureCameraDemo
//
//  Created by zywx on 15/11/26.
//  Copyright (c) 2015年 zywx. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EUtility.h"
#import "CameraDefines.h"
#import "CameraCommon.h"
#import "EUExCamera.h"
//#import "CameraPickerController.h"

@interface CameraPostViewController : UIViewController

@property (nonatomic, strong) UIImage *postImage;
@property (nonatomic, assign) EBrowserView *meBrwView;
@property (nonatomic, copy) NSString *address;
@property (nonatomic, strong) UIView *middleContainerView;//中部view
@property (nonatomic, strong) UILabel *middleLbl;//中部的地址信息
@property (nonatomic, weak) EUExCamera *uexObj;
@property (nonatomic, assign) CGFloat quality;
@property (nonatomic, assign) id<CloseCaptureCameraDelegate> closeCameraDelegate;
@property (nonatomic, assign) BOOL isByOpenInternal;
@property (nonatomic, assign) BOOL isCompress;
@property (nonatomic, strong) ACJSFunctionRef *funcOpen;
@end
