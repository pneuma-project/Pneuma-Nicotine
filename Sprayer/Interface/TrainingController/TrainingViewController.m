//
//  TrainingViewController.m
//  Sprayer
//
//  Created by FangLin on 17/2/27.
//  Copyright © 2017年 FangLin. All rights reserved.
//

#import "TrainingViewController.h"
#import "FL_ScaleCircle.h"
#import "TrainingStartViewController.h"
#import "RetrainingViewController.h"
#import "SqliteUtils.h"
#import "AddPatientInfoModel.h"
#import "UserDefaultsUtils.h"
#import "BlueToothDataModel.h"
#import "FLDrawDataTool.h"

@interface TrainingViewController ()
{
    UIView *view;
    UIImageView *bgImageView;
    UIView *footView;
    
    int userId;//当前用户ID
    int pastNum;  //过去60min次数
    
    NSData *timeData;
}

@property (nonatomic,strong)FL_ScaleCircle *circleView;
@property(nonatomic,strong)NSMutableArray * AllNumberArr;

@property (nonatomic,strong)NSTimer *timer;

@end

@implementation TrainingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self setNavTitle:[DisplayUtils getTimestampData]];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:2.0f target:self selector:@selector(writeDataAction) userInfo:nil repeats:YES];
    [self.timer setFireDate:[NSDate distantFuture]];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    for (UIView *subview in self.view.subviews) {
        [subview removeFromSuperview];
    }
    [self.timer setFireDate:[NSDate distantPast]];
    [self selectDataFromDb];
    [self createHeadView];
    [self createFootView];
    self.tabBarController.tabBar.hidden = NO;
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"transparent"] forBarMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar setShadowImage:[UIImage imageNamed:@"transparent"]];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
    //接收到实时喷雾数据刷新界面通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshViewAction) name:@"refreshSprayView" object:nil];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"nav_bg"] forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.barTintColor = RGBColor(0, 83, 181, 1.0);
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
    self.navigationController.interactivePopGestureRecognizer.enabled=YES;
    [self.timer setFireDate:[NSDate distantFuture]];
}

-(void)selectDataFromDb
{
    pastNum = 0;
    //先查看是哪个用户登录并且调取他的最优数据
    userId = 0;
    NSArray * arr = [[SqliteUtils sharedManager]selectUserInfo];
    if (arr.count!=0) {
        for (AddPatientInfoModel * model in arr) {
            if (model.isSelect == 1) {
                userId = model.userId ;
            }
        }
    }
    
    self.AllNumberArr = [[NSMutableArray alloc] init];
    //获取该用户的实时喷雾数据(50个为一组)
    NSArray * arr2 = [[SqliteUtils sharedManager] selectHistoryBTInfo];
    if (arr2.count == 0) {
        [self.AllNumberArr removeAllObjects];
        return;
    }
    //判断是否为今天的数据
    UInt64 recordTime = [[NSDate date] timeIntervalSince1970];
    NSString *time = [NSString stringWithFormat:@"%.llu",recordTime];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"YYYYMMdd"];
    NSDate *confromTimesp1 = [NSDate dateWithTimeIntervalSince1970:[time doubleValue]];
    NSString * confromTimespStr1 = [formatter stringFromDate:confromTimesp1];
    //当前时间戳
    long long nowTimeStamp = [DisplayUtils getNowTimestamp];
    for (BlueToothDataModel * model  in arr2) {
        //当前读取数据的时间
        NSDate *confromTimesp2 = [NSDate dateWithTimeIntervalSince1970:[model.timestamp doubleValue]];
        NSString * confromTimespStr2 = [formatter stringFromDate:confromTimesp2];
        if (model.userId == userId&&(confromTimespStr1 == confromTimespStr2)) {
            [self.AllNumberArr addObject:model];
        }
        if ([model.timestamp longLongValue] >= (nowTimeStamp-3600)) {
            pastNum += 1;
        }
    }
}

-(void)createHeadView
{
    view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screen_width, screen_height/2)];
    [self.view addSubview:view];
    
    //背景图片
    bgImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, screen_width, screen_height/2)];
    bgImageView.image = [UIImage imageNamed:@"my-profile-bg"];
    [view addSubview:bgImageView];
    
    self.circleView = [[FL_ScaleCircle alloc] initWithFrame:CGRectMake(0, 0, screen_width/2-10, screen_width/2-10)];
    self.circleView.center = CGPointMake(screen_width/2, bgImageView.current_h/2);
    self.circleView.number = [NSString stringWithFormat:@"%.2fmg",self.AllNumberArr.count*AMOUNT];
    self.circleView.lineWith = 7.0;
    [bgImageView addSubview:self.circleView];
}

-(void)createFootView
{
    footView = [[UIView alloc] initWithFrame:CGRectMake(0, view.current_y_h, screen_width, screen_height/2)];
    footView.backgroundColor = RGBColor(242, 250, 254, 1.0);
    [self.view addSubview:footView];
    
    UILabel *allNumL = [[UILabel alloc] initWithFrame:CGRectMake(10, 70, screen_width-20,40)];
    allNumL.text = [NSString stringWithFormat:@"NO. of puffs today:   %lu",(unsigned long)self.AllNumberArr.count];
    allNumL.textColor = RGBColor(8, 86, 184, 1.0);
    allNumL.font = [UIFont systemFontOfSize:20];
    [footView addSubview:allNumL];
    
    UILabel *pastNumL = [[UILabel alloc] initWithFrame:CGRectMake(10, 130, screen_width-20,40)];
    pastNumL.text = [NSString stringWithFormat:@"NO. of puffs in the past 60 min:  %d",pastNum];
    pastNumL.textColor = RGBColor(8, 86, 184, 1.0);
    pastNumL.font = [UIFont systemFontOfSize:19];
    [footView addSubview:pastNumL];
}

-(void)refreshViewAction
{
    for (UIView *subview in self.view.subviews) {
        [subview removeFromSuperview];
    }
    [self selectDataFromDb];
    [self createHeadView];
    [self createFootView];
}

-(void)writeDataAction
{
    //    NSString *time = [DisplayUtils getTimeStampWeek];
    //    NSString *weakDate = [DisplayUtils getTimestampDataWeek];
    //    NSMutableString *allStr = [[NSMutableString alloc] initWithString:time];
    //    [allStr insertString:weakDate atIndex:10];
    //    timeData = [FLWrapJson bcdCodeString:allStr];
    long long time = [DisplayUtils getNowTimestamp];
    timeData = [FLDrawDataTool longToNSData:time];
    [BlueWriteData sparyData:timeData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
