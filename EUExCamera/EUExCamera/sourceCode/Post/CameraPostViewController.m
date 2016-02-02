//
//  CameraPostViewController.m
//  CameraCaptureCameraDemo
//
//  Created by zywx on 15/11/26.
//  Copyright (c) 2015年 zywx. All rights reserved.
//

#import "CameraPostViewController.h"
#import "JSON.h"
#import "EUExBaseDefine.h"
#import "CameraDefines.h"
#import "CameraUtility.h"

@interface CameraPostViewController ()

@end

@implementation CameraPostViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    [self setUpUI];
    [self addAddressViewWithText:_address];
    
    if (!self.isByOpenInternal) {
       self.closeCameraDelegate = _uexObj;
    }
}

//地理位置
- (void)addAddressViewWithText:(NSString*)text {
    if (!_middleContainerView) {
        
        CGRect middleFrame = CGRectMake(0, self.view.frame.size.height - kSpacing * 2 - 80, self.view.frame.size.width, 44);
        UIView *mView = [[UIView alloc] initWithFrame:middleFrame];
        mView.backgroundColor = [UIColor clearColor];
        [self.view addSubview:mView];
        self.middleContainerView = mView;
        
        
        _middleLbl = [[UILabel alloc] init];
        _middleLbl.font = [UIFont systemFontOfSize:20.f];
        CGSize lblSize = [text sizeWithFont:_middleLbl.font];
        _middleLbl.frame = CGRectMake((self.view.frame.size.width - lblSize.width) / 2, 0, lblSize.width, middleFrame.size.height);
        NSLog(@"x=%f,y=%f",_middleLbl.frame.origin.x,_middleLbl.frame.origin.y);
        _middleLbl.backgroundColor = [UIColor clearColor];
        _middleLbl.textColor = [UIColor blackColor];
        _middleLbl.text = text;
        [_middleContainerView addSubview:_middleLbl];
        
    }
    
}

- (void) setUpUI{
    
    self.view.backgroundColor = [UIColor lightGrayColor];
    CGFloat imgViewWidth = self.view.frame.size.width - 50;
    CGFloat imgViewX = 25;
    if (self.isByOpenInternal) {
        self.view.backgroundColor = [UIColor blackColor];
        imgViewWidth = self.view.frame.size.width;
        imgViewX = 0;
    }
    
    if (_postImage) {
        UIImageView *imgView = [[UIImageView alloc] initWithImage:_postImage];
        imgView.clipsToBounds = YES;
        imgView.contentMode = UIViewContentModeScaleAspectFill;
        imgView.frame = CGRectMake(imgViewX, 50, imgViewWidth, self.view.frame.size.height - 150);
        //        imgView.center = self.view.center;
        [self.view addSubview:imgView];
    }
    
    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    backBtn.frame = CGRectMake(10, self.view.frame.size.height - 50, 80, 30);
    [backBtn setTitle:@"重拍" forState:UIControlStateNormal];
    backBtn.backgroundColor = [UIColor whiteColor];
    [backBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [backBtn addTarget:self action:@selector(backBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:backBtn];
    
    
    UIButton *submitBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    submitBtn.frame = CGRectMake(self.view.frame.size.width - 90, self.view.frame.size.height - 50, 80, 30);
    NSLog(@"frame=%f",submitBtn.frame.origin.x);
    [submitBtn setTitle:@"提交" forState:UIControlStateNormal];
    submitBtn.backgroundColor = [UIColor whiteColor];
    [submitBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [submitBtn addTarget:self action:@selector(submitBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:submitBtn];

    if (self.isByOpenInternal) {
        backBtn.backgroundColor = [UIColor blackColor];
        [backBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [submitBtn setTitle:@"使用照片" forState:UIControlStateNormal];
        submitBtn.backgroundColor = [UIColor blackColor];
        [submitBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)backBtnPressed:(id)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)submitBtnPressed:(id)sender {

    if (self.isByOpenInternal) {
        [self savaImg:_postImage];
        [self dismissViewControllerAnimated:NO completion:^{
            if (_closeCameraDelegate) {
                [_closeCameraDelegate CloseCameraPicker];
            }
        }];

        return;
    }
    [self dismissViewControllerAnimated:NO completion:nil];
    NSString *filePath = [self saveImageWith:_postImage];
    NSLog(@"EUExCamera==>>submitBtnPressed==>>照片保存成功");

    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setValue:filePath forKey:@"photoPath"];
    [dict setValue:_address forKey:@"location"];
    SBJSON *jsonParser = [[SBJSON alloc]init];
    NSString *jsonString = [jsonParser stringWithObject:dict];
    NSLog(@"回调json串------》》》》%@",jsonString);
    [_closeCameraDelegate CloseCamera];
    if (_uexObj) {
        [_uexObj jsSuccessWithName:@"uexCamera.cbOpenViewCamera" opId:0 dataType:UEX_CALLBACK_DATATYPE_JSON strData:jsonString];
        NSLog(@"EUExCamera==>>submitBtnPressed==>>回调完成");
    }
}

-(NSString *)saveImageWith:(UIImage *)image{
    NSDateFormatter *formatter =[[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyyMMddHHmmss"];
    NSString *timeString = [formatter stringFromDate:[NSDate date]];
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSString *pathDocuments = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *createPath = [NSString stringWithFormat:@"%@/EUExCamera", pathDocuments];
    NSLog(@"EUExCamera==>>saveImageWith==>>保存路径createPath=%@",createPath);
    // 判断文件夹是否存在，如果不存在，则创建
    if (![[NSFileManager defaultManager] fileExistsAtPath:createPath]) {
        [fileManager createDirectoryAtPath:createPath withIntermediateDirectories:YES attributes:nil error:nil];
    } else {
        NSLog(@"FileDir is exists.");
    }
    
    NSString *filePath = [createPath stringByAppendingPathComponent:[NSString stringWithFormat:@"EUExCamera_%@.png", timeString]];
    NSLog(@"EUExCamera==>>saveImageWith==>>照片_postImage=%@,filePath=%@",_postImage,filePath);
    [UIImagePNGRepresentation(_postImage) writeToFile: filePath atomically:YES];
    [UIImageJPEGRepresentation(_postImage, self.quality) writeToFile:filePath atomically:YES];
    return filePath;
    
}

-(UIImage *)getImageWith:(NSString *)filePath{
    UIImage *img = [UIImage imageWithContentsOfFile:filePath];
    return img;
}

-(void)savaImg:(UIImage *)image {
    NSLog(@"savaImg==>>开始保存图片");
    //保存到一个指定目录
    NSError * error;
    NSFileManager * fmanager = [NSFileManager defaultManager];
    NSString * wgtPath = [self.uexObj absPath:@"wgt://"];
    NSString * imagePath = [CameraUtility getSavename:@"image" wgtPath:wgtPath];
    if([fmanager fileExistsAtPath:imagePath]) {
        [fmanager removeItemAtPath:imagePath error:&error];
    }
    UIImage * newImage = [EUtility rotateImage:image];
    //压缩
    UIImage * needSaveImg = [CameraUtility imageByScalingAndCroppingForSize:newImage width:640];
    //压缩比率，0：压缩后的图片最小，1：压缩后的图片最大
    NSData * imageData = nil;
    if (self.isCompress) {
        imageData = UIImageJPEGRepresentation(needSaveImg, self.quality);
    } else {
        imageData = UIImageJPEGRepresentation(needSaveImg, 1);
    }
    BOOL success = [imageData writeToFile:imagePath atomically:YES];
    if (success) {
        NSLog(@"savaImg==>>保存路径==>>imagePath=%@",imagePath);
        [self.uexObj jsSuccessWithName:@"uexCamera.cbOpenInternal" opId:0 dataType:UEX_CALLBACK_DATATYPE_TEXT strData:imagePath];
//        [self.uexObj uexSuccessWithOpId:0 dataType:UEX_CALLBACK_DATATYPE_TEXT data:imagePath];
    } else {
        [self.uexObj jsFailedWithOpId:0 errorCode:1030105 errorDes:UEX_ERROR_DESCRIBE_FILE_SAVE];
    }
}

@end
