//
//  EUExCamera.m
//  AppCan
//
//  Created by AppCan on 11-8-26.
//  Copyright 2011 AppCan. All rights reserved.
//

#import "EUExCamera.h"
#import "EUtility.h"
#import "EUExBaseDefine.h"
#import "CameraUtility.h"
#import "CameraCaptureCamera.h"
#import "CameraPickerController.h"
#import "CameraInternationalization.h"

@interface EUExCamera(){

}
@property(nonatomic,strong)ACJSFunctionRef *funcOpen;
@end

@implementation EUExCamera

#define IsIOS6OrLower ([[[UIDevice currentDevice] systemVersion] floatValue]<7.0)

#pragma mark -
#pragma mark - Plugin Method
- (instancetype)initWithWebViewEngine:(id<AppCanWebViewEngineObject>)engine
{
    self = [super initWithWebViewEngine:engine];
    if (self) {
       self.imagePickerController = [[UIImagePickerController alloc] init];
    }
    return self;
}
-(void)open:(NSMutableArray *)inArguments {
    isCompress = NO;
    if ([inArguments isKindOfClass:[NSMutableArray class]] && [inArguments count] > 0) {
        ACJSFunctionRef *func = JSFunctionArg(inArguments.lastObject);
        self.funcOpen = func;
        NSString * compress = [inArguments objectAtIndex:0];
        if ([compress isKindOfClass:[NSString class]] && compress.length > 0) {
            if (0 == [compress intValue]) {
                isCompress = YES;
                scale = 0.5;
                if ([inArguments count] == 2) {
                    NSString * scaleStr = [inArguments objectAtIndex:1];
                    float scalefloat = [scaleStr floatValue]/100;
                    if (scalefloat <= 100 && scalefloat >= 0 ) {
                        scale = scalefloat;
                    }
                }
            }
        }
    }
    [self showCamera];

}

-(void)openInternal:(NSMutableArray *)inArguments {
    ACJSFunctionRef *func = nil;
    NSLog(@"uexCamera==>>openInternal");
    isCompress = NO;
    if ([inArguments isKindOfClass:[NSMutableArray class]] && [inArguments count] > 0) {
        func = JSFunctionArg(inArguments.lastObject);
        NSString * compress = [inArguments objectAtIndex:0];
        if ([compress isKindOfClass:[NSString class]] && compress.length > 0) {
            if (0 == [compress intValue]) {
                isCompress = YES;
                scale = 0.5;
                if ([inArguments count] == 2) {
                    NSString * scaleStr = [inArguments objectAtIndex:1];
                    float scalefloat = [scaleStr floatValue]/100;
                    if (scalefloat <= 100 && scalefloat >= 0 ) {
                        scale = scalefloat;
                    }
                }
            }
        }
    }
    if (!self.cameraPickerController) {
        
        self.cameraPickerController = [[CameraPickerController alloc] init];
        self.cameraPickerController.funcOpenInternal = func;
    }
    
    //self.cameraPickerController.meBrwView = meBrwView;
    self.cameraPickerController.uexObj = self;
    self.cameraPickerController.scale = scale;
    self.cameraPickerController.isCompress = isCompress;
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 6.0) {
        //[EUtility brwView:meBrwView presentModalViewController:self.cameraPickerController animated:YES];
        [[self.webViewEngine viewController] presentViewController:self.cameraPickerController animated:YES completion:nil];
    } else {
       // [EUtility brwView:meBrwView navigationPresentModalViewController:self.cameraPickerController animated:YES];
        [[self.webViewEngine viewController].navigationController presentViewController:self.cameraPickerController animated:YES completion:nil];
    }
    
}


-(void)showCamera {
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        //[super jsFailedWithOpId:0 errorCode:1030108 errorDes:UEX_ERROR_DESCRIBE_DEVICE_SUPPORT];
    } else {
      
        [self.imagePickerController setDelegate:self];
        //        [imagePickerController setAllowsEditing:YES];
        [self.imagePickerController setSourceType:UIImagePickerControllerSourceTypeCamera];
        [self.imagePickerController setVideoQuality:UIImagePickerControllerQualityTypeMedium];
        
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 6.0) {
            [[self.webViewEngine viewController] presentViewController:self.imagePickerController animated:YES completion:nil];
        } else {
            [[self.webViewEngine viewController].navigationController presentViewController:self.imagePickerController animated:YES completion:nil];
        }
        if (IsIOS6OrLower) {
            
        } else {
            UIViewController *controller = [self.webViewEngine viewController];//[EUtility brwCtrl:meBrwView];
            [controller setNeedsStatusBarAppearanceUpdate];
        }
    }
}

#pragma mark -
#pragma mark - CallBack

-(void)uexSuccessWithOpId:(int)inOpId dataType:(int)inDataType data:(NSString *)inData {
	if (inData) {
		//[self jsSuccessWithName:@"uexCamera.cbOpen" opId:inOpId dataType:inDataType strData:inData];
        [self.webViewEngine callbackWithFunctionKeyPath:@"uexCamera.cbOpen" arguments:ACArgsPack(@(inOpId),@(inDataType),inData)];
        [self.funcOpen executeWithArguments:ACArgsPack(@(inOpId),@(inDataType),inData)];
	}
}

#pragma mark -
#pragma mark - UIImagePickerControllerDelegate

-(void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error
  contextInfo:(void *)contextInfo {
	if (error != NULL) {
		//[super jsFailedWithOpId:0 errorCode:1030105 errorDes:UEX_ERROR_DESCRIBE_FILE_SAVE];
	}
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
	if (picker) {
		[picker dismissViewControllerAnimated:YES completion:nil];
	}
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
	NSString * mediaType = [info objectForKey:UIImagePickerControllerMediaType];
	if ([mediaType isEqualToString:@"public.image"]){
        UIImage * image = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
        //同时有模态视图的时候需要 模态视图关闭动画之后再保存图片
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 5.0) {
            [picker dismissViewControllerAnimated:YES completion:^{
                [self performSelector:@selector(savaImg:) withObject:image afterDelay:0];
            }];
        }else{
            [picker dismissViewControllerAnimated:NO completion:nil];
            [self performSelector:@selector(savaImg:) withObject:image afterDelay:0];
        }
	}
}

-(void)savaImg:(UIImage *)image {
	//保存到一个指定目录
	NSError * error;
    NSFileManager * fmanager = [NSFileManager defaultManager];
    NSString * wgtPath = [super absPath:@"wgt://"];
    NSString * imagePath = [CameraUtility getSavename:@"image" wgtPath:wgtPath];
 	if([fmanager fileExistsAtPath:imagePath]) {
        [fmanager removeItemAtPath:imagePath error:&error];
	}
	UIImage * newImage = [EUtility rotateImage:image];
    //压缩
    UIImage * needSaveImg = [CameraUtility imageByScalingAndCroppingForSize:newImage width:640];
    //压缩比率，0：压缩后的图片最小，1：压缩后的图片最大
    NSData * imageData = nil;
    if (isCompress) {
        imageData = UIImageJPEGRepresentation(needSaveImg, scale);
    } else {
        imageData = UIImageJPEGRepresentation(needSaveImg, 1);
    }
	BOOL success = [imageData writeToFile:imagePath atomically:YES];
	if (success) {
		[self uexSuccessWithOpId:0 dataType:UEX_CALLBACK_DATATYPE_TEXT data:imagePath];
	} else {
		//[super jsFailedWithOpId:0 errorCode:1030105 errorDes:UEX_ERROR_DESCRIBE_FILE_SAVE];
	}
}


#pragma mark -
#pragma mark - 自定义相机
- (void)openViewCamera:(NSMutableArray *)array {
    
    @try {
        
        float x = [array objectAtIndex:0]?[[array objectAtIndex:0] floatValue]:0.0;
        float y = [array objectAtIndex:1]?[[array objectAtIndex:1] floatValue]:0.0;
        float w = [array objectAtIndex:2]?[[array objectAtIndex:2] floatValue]:SC_DEVICE_SIZE.width;
        float h = [array objectAtIndex:3]?[[array objectAtIndex:3] floatValue]:SC_DEVICE_SIZE.height;
        NSString *address = [array objectAtIndex:4]?[array objectAtIndex:4]:kInternationalization(@"noAddress");
         ACJSFunctionRef *func = JSFunctionArg(array.lastObject);
        _captureCameraView = [[CameraCaptureCamera alloc] initWithFrame:CGRectMake(x, y, w, h)];
        _captureCameraView.funcOpen = func;
        _captureCameraView.address = address;
        //_captureCameraView.meBrwView = meBrwView;
        _captureCameraView.uexObj = self;
        if (array.count > 5) {
            _captureCameraView.quality = [[array objectAtIndex:5] floatValue] / 100.0;
        }
        [_captureCameraView setUpUI];
        [[self.webViewEngine webView] addSubview:_captureCameraView];
    }
    @catch (NSException *exception) {
        
        NSLog(@"EUExCamera==>>openViewCamera==>>catch==>>%@\n%@\n%@",exception.name,exception.reason,exception.userInfo);
        
    }
    @finally {
        //
    }
    
}

//0代表自动，1代表打开闪光灯，2代表关闭闪光灯
-(NSNumber*)changeFlashMode:(NSMutableArray *)array{
    //uexCamera.cbChangeFlashMode
    NSString *flashMode = [array objectAtIndex:0]?[array objectAtIndex:0]:@"0";
    if (_captureCameraView) {
        if (flashMode.integerValue == 0 || flashMode.integerValue == 1) {
            NSString*mode = [_captureCameraView switchFlashMode:flashMode];
            return @(mode.integerValue);
        } else {
            return @(-1);
        }
      
    }else{
        NSLog(@"EUExCamera==>>changeFlashMode==>>相机初始化失败");
        //[self jsSuccessWithName:@"uexCamera.cbChangeFlashMode" opId:0 dataType:UEX_CALLBACK_DATATYPE_JSON strData:@"-1"];
        [self.webViewEngine callbackWithFunctionKeyPath:@"uexCamera.cbChangeFlashMode" arguments:ACArgsPack(@0,@1,@"0")];
        NSLog(@"EUExCamera==>>changeFlashMode==>>回调完成");
        return @(0);
    }
    
}

//1代表前置，0代表后置
-(NSNumber*)changeCameraPosition:(NSMutableArray *)array{
    
    NSString *cameraPosition = @"0";
    
    if (array.count > 0) {
        cameraPosition = [array objectAtIndex:0];
    }
    
    if (_captureCameraView) {
        if (cameraPosition.integerValue == 0 || cameraPosition.integerValue ==1) {
            NSString *mode = [_captureCameraView switchCamera:cameraPosition];
            return @(mode.integerValue);
        }else{
            return @(-1);
        }
      
    }else{
        NSLog(@"EUExCamera==>>changeCameraPosition==>>相机初始化失败");
        //[self jsSuccessWithName:@"uexCamera.cbChangeCameraPosition" opId:0 dataType:UEX_CALLBACK_DATATYPE_JSON strData:@"-1"];
        [self.webViewEngine callbackWithFunctionKeyPath:@"uexCamera.cbChangeCameraPosition" arguments:ACArgsPack(@0,@1,@"0")];
        NSLog(@"EUExCamera==>>changeCameraPosition==>>回调完成");
        return @(0);
    }
    
}

- (void)removeViewCameraFromWindow:(NSMutableArray *)inArguments {
    
    if (_captureCameraView) {
        NSLog(@"EUExCamera==>>removeViewCameraFromWindow==>>delegate关闭openViewCamera相机");
        [_captureCameraView removeFromSuperview];
       
    }
    
}

- (void)CloseCamera{
    
    [self removeViewCameraFromWindow:nil];
}

@end
