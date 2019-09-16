//
//  HistoryDetailViewController.m
//  Sprayer
//
//  Created by 黄上凌 on 2017/5/24.
//  Copyright © 2017年 FangLin. All rights reserved.
//

#import "HistoryDetailViewController.h"
#import "JHChartHeader.h"
#import "SqliteUtils.h"
#import "BlueToothDataModel.h"
#import "AddPatientInfoModel.h"
#import "DisplayUtils.h"
#import "UserDefaultsUtils.h"
#import "FLWrapJson.h"
#import "HistoryModel.h"
#define k_MainBoundsWidth [UIScreen mainScreen].bounds.size.width
#define k_MainBoundsHeight [UIScreen mainScreen].bounds.size.height

@interface HistoryDetailViewController ()<CustemBBI,UICollectionViewDelegate,UICollectionViewDataSource>
{
    NSString *medicineName; //药品名称
    UILabel * upTotalInfoLabel;
    
    UILabel * upYLineLabel;
    UILabel * upXLineLabel;
    UIView * upBgView;
    
    UILabel * yLineLabel;
    UILabel * xLineLabel;
    UIView * downBgView;
    
    NSInteger upSum;
    NSInteger sum;
    
    NSMutableArray * timeArr2;
    NSMutableArray * spraysArr;
}
@property(nonatomic,strong)JHLineChart *lineChart;
@property(nonatomic,strong)UILabel * slmLabel;

@property(nonatomic,strong)UILabel *medicineNameL;
@property(nonatomic,strong)UILabel *currentInfoLabel;

@property(nonatomic,strong)UICollectionView *upCollectionView;

@property(nonatomic,strong)UICollectionView *downCollectionView;

@property (nonatomic,strong)NSMutableArray *dataArr;

@property (nonatomic,strong)NSMutableArray *monthDataArr;
@end

@implementation HistoryDetailViewController

-(NSMutableArray *)dataArr
{
    if (!_dataArr) {
        _dataArr = [[NSMutableArray alloc] init];
    }
    return _dataArr;
}

-(NSMutableArray *)monthDataArr
{
    if (!_monthDataArr) {
        _monthDataArr = [[NSMutableArray alloc] init];
    }
    return _monthDataArr;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = RGBColor(240, 248, 252, 1.0);
    [self setNavTitle:@"History"];
    [self requestData];
    [self showFirstQuardrant];
    [self setUpCollect];
    [self setDownCollect];
}
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationItem.leftBarButtonItem = [CustemNavItem initWithImage:[UIImage imageNamed:@"icon-back"] andTarget:self andinfoStr:@"left"];
}

-(void)setNavTitle:(NSString *)title
{
    UILabel *label=[[UILabel alloc]initWithFrame:CGRectMake(0, 0, 60, 44)];
    label.text=title;
    label.textColor=[UIColor whiteColor];
    label.textAlignment=NSTextAlignmentCenter;
    label.font=[UIFont systemFontOfSize:19];
    self.navigationItem.titleView=label;
}
#pragma mark - CustemBBI代理方法
-(void)BBIdidClickWithName:(NSString *)infoStr
{
    if ([infoStr isEqualToString:@"left"]) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)showFirstQuardrant{
    for (UIView *subview in self.view.subviews) {
        [subview removeFromSuperview];
    }
    upBgView = [[UIView alloc]initWithFrame:CGRectMake(10, kSafeAreaTopHeight+10, screen_width-20, (screen_height-kSafeAreaTopHeight-kSafeAreaBottomHeight)/2-20)];
    upBgView.layer.cornerRadius = 3.0;
    upBgView.backgroundColor = [UIColor whiteColor];
    
    UIView * upPointView = [[UIView alloc]initWithFrame:CGRectMake(10, 10, 8, 8)];
//    upPointView.backgroundColor = RGBColor(0, 83, 181, 1.0);
    upPointView.layer.cornerRadius = 4.0;
    upPointView.layer.masksToBounds = 4.0;
    
    UILabel *upInspirationLabel = [[UILabel alloc]initWithFrame:CGRectMake(upPointView.current_x_w+5, 10, screen_width-upPointView.current_x_w, 15)];
//    upInspirationLabel.text = @"Inspiration Volume Distribution";
    upInspirationLabel.textColor = RGBColor(0, 83, 181, 1.0);
    
    CGPoint upInsPoint = upPointView.center;
    upInsPoint.y = upInspirationLabel.center.y;
    upPointView.center = upInsPoint;
    
    upTotalInfoLabel = [[UILabel alloc]initWithFrame:CGRectMake(upBgView.current_w-60, upInspirationLabel.current_y+15, 60, 30)];
    HistoryModel *model = self.dataArr[0];
    NSArray *totalMonthArr = [model.time componentsSeparatedByString:@"/"];
    upTotalInfoLabel.text = totalMonthArr[0];
    upTotalInfoLabel.textAlignment = NSTextAlignmentLeft;
    upTotalInfoLabel.textColor = RGBColor(0, 83, 181, 1.0);
    upTotalInfoLabel.font = [UIFont systemFontOfSize:16];
    UILabel * upTotalLabel = [[UILabel alloc]initWithFrame:CGRectMake(upTotalInfoLabel.current_x-40, upInspirationLabel.current_y_h+8,40,15)];
//    upTotalLabel.text = @"Total:";
    upTotalLabel.textAlignment = NSTextAlignmentRight;
    upTotalLabel.font = [UIFont systemFontOfSize:12];
    upTotalLabel.textColor = RGBColor(0, 83, 181, 1.0);
    UILabel * upUnitLabel = [[UILabel alloc]initWithFrame:CGRectMake(upPointView.current_x, upTotalLabel.current_y_h+5, 80, 15)];
    upUnitLabel.text = @"No. of puffs";
    upUnitLabel.font = [UIFont systemFontOfSize:12];
    upUnitLabel.textColor = RGBColor(203, 204, 205, 1.0);
    
    upYLineLabel = [[UILabel alloc]initWithFrame:CGRectMake(upUnitLabel.current_x_w-45, upUnitLabel.current_y_h+10, 1, upBgView.current_h-upUnitLabel.current_y_h-40)];
    upYLineLabel.backgroundColor = RGBColor(204, 205, 206, 1.0);
    
    //获取总和
    upSum = 10;
    NSMutableArray *numberArr = [[NSMutableArray alloc] init];
    for (HistoryModel *model in self.dataArr) {
        [numberArr addObject:[NSNumber numberWithInteger:model.number]];
    }
    if ([[numberArr valueForKeyPath:@"@max.integerValue"] integerValue] <= 4) {
        upSum = 6;
    }else {
        upSum = [[numberArr valueForKeyPath:@"@max.integerValue"] integerValue] + 2;
    }
    
    for (int i =0; i<6; i++) {
        UILabel * upYNumLabel = [[UILabel alloc]initWithFrame:CGRectMake(upYLineLabel.current_x-35,upYLineLabel.current_y+40+i*((upYLineLabel.current_h-40)/6), 30, 12)];
        upYNumLabel.tag = 60+i;
        upYNumLabel.textColor = RGBColor(204, 205, 206, 1.0);
        upYNumLabel.textAlignment = NSTextAlignmentRight;
        upYNumLabel.text = [NSString stringWithFormat:@"%ld",upSum-i*(upSum/5)];
        upYNumLabel.font = [UIFont systemFontOfSize:10];
        [upBgView addSubview:upYNumLabel];
    }
    
    upXLineLabel = [[UILabel alloc]initWithFrame:CGRectMake(upYLineLabel.current_x_w, upYLineLabel.current_y_h, upBgView.current_w-upYLineLabel.current_x_w-40, 1)];
    upXLineLabel.backgroundColor = RGBColor(204, 205, 206, 1.0);
    
    [self.upCollectionView reloadData];
    
    UILabel * upDateLabel = [[UILabel alloc]initWithFrame:CGRectMake(upXLineLabel.current_x_w, upXLineLabel.current_y_h-10, upBgView.current_w-upXLineLabel.current_x_w, 20)];
    upDateLabel.text = @"day";
    upDateLabel.textColor = RGBColor(204, 205, 206, 1.0);
    upDateLabel.font = [UIFont systemFontOfSize:10];
    
    [upBgView addSubview:upPointView];
    [upBgView addSubview:upInspirationLabel];
    [upBgView addSubview:upTotalInfoLabel];
    [upBgView addSubview:upTotalLabel];
    [upBgView addSubview:upDateLabel];
    [upBgView addSubview:upXLineLabel];
    [upBgView addSubview:upYLineLabel];
    [upBgView addSubview:upUnitLabel];
    [self.view addSubview:upBgView];
    
    /*创建第二个柱状图 */
    downBgView = [[UIView alloc]initWithFrame:CGRectMake(10, upBgView.current_y_h+10, screen_width-20,(screen_height-kSafeAreaTopHeight-kSafeAreaBottomHeight)/2-20)];
    downBgView.backgroundColor = [UIColor whiteColor];
    UIView * pointView = [[UIView alloc]initWithFrame:CGRectMake(10, 10, 8, 8)];
//    pointView.backgroundColor = RGBColor(0, 83, 181, 1.0);
    pointView.layer.cornerRadius = 4.0;
    pointView.layer.masksToBounds = 4.0;
    UILabel *inspirationLabel = [[UILabel alloc]initWithFrame:CGRectMake(pointView.current_x_w+5, 10, screen_width-pointView.current_x_w, 15)];
//    inspirationLabel.text = @"Inspiration Volume Distribution";
    inspirationLabel.textColor = RGBColor(0, 83, 181, 1.0);
    CGPoint insPoint = pointView.center;
    insPoint.y = inspirationLabel.center.y;
    pointView.center = insPoint;
    
    UILabel * totalInfoLabel = [[UILabel alloc]initWithFrame:CGRectMake(downBgView.current_w-60, inspirationLabel.current_y+15, 60, 30)];
    
    totalInfoLabel.text = @"Month";
    totalInfoLabel.textAlignment = NSTextAlignmentLeft;
    totalInfoLabel.textColor = RGBColor(0, 83, 181, 1.0);
    totalInfoLabel.font = [UIFont systemFontOfSize:16];
    UILabel * totalLabel = [[UILabel alloc]initWithFrame:CGRectMake(totalInfoLabel.current_x-40, inspirationLabel.current_y_h+8,40,15)];
//    totalLabel.text = @"Total:";
    totalLabel.textAlignment = NSTextAlignmentRight;
    totalLabel.font = [UIFont systemFontOfSize:12];
    totalLabel.textColor = RGBColor(0, 83, 181, 1.0);
    UILabel * unitLabel = [[UILabel alloc]initWithFrame:CGRectMake(pointView.current_x, totalLabel.current_y_h+5, 80, 15)];
    unitLabel.text = @"No. of puffs";
    unitLabel.font = [UIFont systemFontOfSize:12];
    unitLabel.textColor = RGBColor(203, 204, 205, 1.0);
    
    yLineLabel = [[UILabel alloc]initWithFrame:CGRectMake(unitLabel.current_x_w-45, unitLabel.current_y_h+10, 1, downBgView.current_h-unitLabel.current_y_h-40)];
    yLineLabel.backgroundColor = RGBColor(204, 205, 206, 1.0);
    
    //获取总和
    sum = 10;
    NSMutableArray *monthNumberArr = [[NSMutableArray alloc] init];
    for (HistoryModel *model in self.monthDataArr) {
        [monthNumberArr addObject:[NSNumber numberWithInteger:model.number]];
    }
    if ([[monthNumberArr valueForKeyPath:@"@max.integerValue"] integerValue] <= 4) {
        sum = 6;
    }else {
        sum = [[monthNumberArr valueForKeyPath:@"@max.integerValue"] integerValue] + 2;
    }
    for (int i =0; i<6; i++) {
        UILabel * yNumLabel = [[UILabel alloc]initWithFrame:CGRectMake(yLineLabel.current_x-35,yLineLabel.current_y+40+i*((yLineLabel.current_h-40)/6), 30, 12)];
        yNumLabel.textColor = RGBColor(204, 205, 206, 1.0);
        yNumLabel.textAlignment = NSTextAlignmentRight;
        yNumLabel.text = [NSString stringWithFormat:@"%ld",sum-i*(sum/5)];
        yNumLabel.font = [UIFont systemFontOfSize:10];
        [downBgView addSubview:yNumLabel];
        
    }
    xLineLabel = [[UILabel alloc]initWithFrame:CGRectMake(yLineLabel.current_x_w, yLineLabel.current_y_h, downBgView.current_w-yLineLabel.current_x_w-40, 1)];
    xLineLabel.backgroundColor = RGBColor(204, 205, 206, 1.0);
   
    [self.downCollectionView reloadData];
    
    UILabel * dateLabel = [[UILabel alloc]initWithFrame:CGRectMake(xLineLabel.current_x_w, xLineLabel.current_y_h-10, downBgView.current_w-xLineLabel.current_x_w, 20)];
    dateLabel.text = @"month";
    dateLabel.textColor = RGBColor(204, 205, 206, 1.0);
    dateLabel.font = [UIFont systemFontOfSize:10];
    
    [downBgView addSubview:dateLabel];
    [downBgView addSubview:xLineLabel];
    [downBgView addSubview:yLineLabel];
    [downBgView addSubview:unitLabel];
    [downBgView addSubview:totalLabel];
    [downBgView addSubview:totalInfoLabel];
    [downBgView addSubview:pointView];
    [downBgView addSubview:inspirationLabel];
    [self.view addSubview:downBgView];
    
}

-(void)setUpCollect {
    /**
     创建layout(布局)
     UICollectionViewFlowLayout 继承与UICollectionLayout
     对比其父类 好处是 可以设置每个item的边距 大小 头部和尾部的大小
     */
    UICollectionViewFlowLayout * layout = [[UICollectionViewFlowLayout alloc]init];
    CGFloat itemWidth = 40;
    // 设置每个item的大小
    layout.itemSize = CGSizeMake(itemWidth, upYLineLabel.current_h+20);
    // 设置列间距
    layout.minimumInteritemSpacing = 0;
    // 设置行间距
    layout.minimumLineSpacing = 20;
    //滚动方向
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    //每个分区的四边间距UIEdgeInsetsMake
    layout.sectionInset = UIEdgeInsetsMake(0, 20, 0, 20);
    _upCollectionView = [[UICollectionView alloc]initWithFrame:CGRectMake(upYLineLabel.current_x_w, upYLineLabel.current_y, upXLineLabel.current_w, upYLineLabel.current_h+20) collectionViewLayout:layout];
    /** mainCollectionView 的布局(必须实现的) */
    _upCollectionView.collectionViewLayout = layout;
    //mainCollectionView 的背景色
    _upCollectionView.backgroundColor = [UIColor clearColor];
    //设置代理协议
    _upCollectionView.delegate = self;
    //设置数据源协议
    _upCollectionView.dataSource = self;
    [_upCollectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"UICollectionViewCell"];
    [upBgView addSubview:self.upCollectionView];
}

-(void)setDownCollect {
    /**
     创建layout(布局)
     UICollectionViewFlowLayout 继承与UICollectionLayout
     对比其父类 好处是 可以设置每个item的边距 大小 头部和尾部的大小
     */
    UICollectionViewFlowLayout * layout = [[UICollectionViewFlowLayout alloc]init];
    CGFloat itemWidth = 40;
    // 设置每个item的大小
    layout.itemSize = CGSizeMake(itemWidth, yLineLabel.current_h+20);
    // 设置列间距
    layout.minimumInteritemSpacing = 0;
    // 设置行间距
    layout.minimumLineSpacing = 20;
    //滚动方向
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    //每个分区的四边间距UIEdgeInsetsMake
    layout.sectionInset = UIEdgeInsetsMake(0, 20, 0, 20);
    _downCollectionView = [[UICollectionView alloc]initWithFrame:CGRectMake(yLineLabel.current_x_w, yLineLabel.current_y, xLineLabel.current_w, yLineLabel.current_h+20) collectionViewLayout:layout];
    /** mainCollectionView 的布局(必须实现的) */
    _downCollectionView.collectionViewLayout = layout;
    //mainCollectionView 的背景色
    _downCollectionView.backgroundColor = [UIColor clearColor];
    //设置代理协议
    _downCollectionView.delegate = self;
    //设置数据源协议
    _downCollectionView.dataSource = self;
    [_downCollectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"UICollectionViewCell"];
    [downBgView addSubview:self.downCollectionView];
}

#pragma mark -- UICollectionViewDelegate
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (collectionView == self.upCollectionView) {
        return self.dataArr.count;
    }else {
        return self.monthDataArr.count;
    }
    
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionView == self.upCollectionView) {
        UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"UICollectionViewCell" forIndexPath:indexPath];
        for (UIView *view in cell.contentView.subviews) {
            [view removeFromSuperview];
        }
        UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
        view.backgroundColor = RGBColor(10, 77, 170, 1);
        UILabel *numL = [[UILabel alloc] initWithFrame:CGRectZero];
        numL.font = [UIFont systemFontOfSize:12];
        numL.textColor = [UIColor grayColor];
        numL.numberOfLines = 0;
        numL.textAlignment = NSTextAlignmentCenter;
        UILabel *dateL = [[UILabel alloc] initWithFrame:CGRectZero];
        dateL.font = [UIFont systemFontOfSize:12];
        dateL.textColor = [UIColor grayColor];
        dateL.numberOfLines = 0;
        dateL.textAlignment = NSTextAlignmentCenter;
        [cell.contentView addSubview:view];
        [cell.contentView addSubview:numL];
        [cell.contentView addSubview:dateL];
        HistoryModel * model = self.dataArr[indexPath.item];
        int viewH = model.number * ((upYLineLabel.current_h-40)/upSum);
        view.frame = CGRectMake(0, upYLineLabel.current_h-viewH, 40, viewH);
        numL.frame = CGRectMake(-5, view.current_y-40, 50, 40);
        dateL.frame = CGRectMake(-5, upYLineLabel.current_h, 50, 13);
        numL.text = [NSString stringWithFormat:@"%ld\n(%.2f)",(long)model.number,model.sum];
        dateL.text = model.time;
        return cell;
    }else {
        UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"UICollectionViewCell" forIndexPath:indexPath];
        for (UIView *view in cell.contentView.subviews) {
            [view removeFromSuperview];
        }
        UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
        view.backgroundColor = RGBColor(10, 77, 170, 1);
        UILabel *numL = [[UILabel alloc] initWithFrame:CGRectZero];
        numL.font = [UIFont systemFontOfSize:12];
        numL.textColor = [UIColor grayColor];
        numL.numberOfLines = 0;
        numL.textAlignment = NSTextAlignmentCenter;
        UILabel *dateL = [[UILabel alloc] initWithFrame:CGRectZero];
        dateL.font = [UIFont systemFontOfSize:12];
        dateL.textColor = [UIColor grayColor];
        dateL.numberOfLines = 0;
        dateL.textAlignment = NSTextAlignmentCenter;
        [cell.contentView addSubview:view];
        [cell.contentView addSubview:numL];
        [cell.contentView addSubview:dateL];
        HistoryModel * model = self.monthDataArr[indexPath.item];
        int viewH = model.number * ((yLineLabel.current_h-40)/sum);
        view.frame = CGRectMake(0, yLineLabel.current_h-viewH, 40, viewH);
        numL.frame = CGRectMake(-5, view.current_y-40, 50, 40);
        dateL.frame = CGRectMake(-5, yLineLabel.current_h, 50, 13);
        numL.text = [NSString stringWithFormat:@"%ld\n(%.2f)",(long)model.number,model.sum];
        dateL.text = model.time;
        return cell;
    }
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionView == self.downCollectionView) {
        HistoryModel * model = self.monthDataArr[indexPath.item];
        [self selectDate:model.time];
    }
}

-(void)selectDate:(NSString *)monthStr{
    [self.dataArr removeAllObjects];
    for (NSInteger j = 0; j < timeArr2.count; j++) {
        NSArray *totalTimeStrArr = [timeArr2[j] componentsSeparatedByString:@"/"];
        if ([totalTimeStrArr[0] isEqualToString:monthStr]) {
            HistoryModel *model = [[HistoryModel alloc] init];
            model.time = timeArr2[j];
            model.number = [spraysArr[j] integerValue];
            model.sum = [spraysArr[j] integerValue] * AMOUNT;
            [self.dataArr addObject:model];
        }
    }
    HistoryModel *model = self.dataArr[0];
    NSArray *totalMonthArr = [model.time componentsSeparatedByString:@"/"];
    upTotalInfoLabel.text = totalMonthArr[0];
    [self.upCollectionView reloadData];
    
    NSMutableArray *numberArr = [[NSMutableArray alloc] init];
    for (HistoryModel *model in self.dataArr) {
        [numberArr addObject:[NSNumber numberWithInteger:model.number]];
    }
    upSum = [[numberArr valueForKeyPath:@"@max.integerValue"] integerValue] + 2;
    for (int i = 0; i<6; i++) {
        UILabel *upYNumberL = [upBgView viewWithTag:(60+i)];
        upYNumberL.text = [NSString stringWithFormat:@"%ld",upSum-i*(upSum/5)];
    }
}

#pragma mark ----导航栏点击事件
-(void)leftTap
{
    [self.navigationController popViewControllerAnimated:YES];
    NSLog(@"点击了左侧");
}

#pragma mark ---- 柱状图的点击事件
-(void)tap:(UITapGestureRecognizer *)tap
{
    NSLog(@"点击了第%ld个柱状图",tap.view.tag - 1000);
    
}

#pragma mark --- 拿到每一天的所有数据
-(NSArray *)selectFromData
{
    //查询数据库(获取所有用户数据)
    NSArray * arr = [[SqliteUtils sharedManager] selectHistoryBTInfo];
    NSMutableArray * userTimeArr = [NSMutableArray array];
    NSMutableArray * dataArr = [NSMutableArray array];
    //筛选出该用户的所有历史数据
    for (BlueToothDataModel * model in arr) {
        if (model.userId == _model.userId) {
            NSLog(@"<<< %@ >>>", model.timestamp);
            [dataArr addObject:model];
        }
    }
    //对用户数据按日期降序排列    请问自己写排序的是什么心态。。。。
    if (dataArr.count == 0) {
        return @[];
    }
    for (int  i =0; i<[dataArr count]-1; i++) {
        for (int j = i+1; j<[dataArr count]; j++) {
            BlueToothDataModel * model1 = dataArr[i];
            BlueToothDataModel * model2 = dataArr[j];
            if ([model1.timestamp intValue] > [model2.timestamp intValue]) {
                //交换
                [dataArr exchangeObjectAtIndex:i withObjectAtIndex:j];
            }
        }
    }
    //将排序好的日期分列添加入数组
    for (BlueToothDataModel * model in dataArr) {
        [userTimeArr addObject:model.timestamp];
    }
    return userTimeArr;
}

-(void)requestData
{
    NSArray * dataArr = [self selectFromData];
    NSLog(@"%@",dataArr);
    if (dataArr.count == 0) {
        return;
    }
    NSMutableArray *timeArr1 = [NSMutableArray array];
    //将时间戳转为应用缩写
    for (NSString * timeStr in dataArr) {
        NSTimeInterval time=[timeStr doubleValue];
        NSDate *detaildate=[NSDate dateWithTimeIntervalSince1970:time];
        //实例化一个NSDateFormatter对象
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        //设定时间格式,这里可以设置成自己需要的格式
        [dateFormatter setDateFormat:@"MMM/dd"];
        
        NSString *currentDateStr = [dateFormatter stringFromDate: detaildate];
        [timeArr1 addObject:currentDateStr];
    }
    if (timeArr1.count == 0) {
        return;
    }
    //原始时间
    NSMutableArray * timeArr3 = [NSMutableArray array];
    NSString * originalTimeStr = dataArr[0];
    [timeArr3 addObject:originalTimeStr];
    
    //将数据按天数分类
    timeArr2 = [NSMutableArray array];
    NSString * dateStr = timeArr1[0];
    [timeArr2 addObject:dateStr];
    
    spraysArr = [NSMutableArray array];
    int index = 0;
    for (int i = 0; i<timeArr1.count; i++) {
        if ([dateStr isEqualToString:timeArr1[i]] ) {
            index ++;
        }else{
            dateStr = timeArr1[i];
            [timeArr2 addObject:timeArr1[i]];
            [timeArr3 addObject:dataArr[i]];
            [spraysArr addObject:[NSString stringWithFormat:@"%d",index]];
            index  = 1;
        }
        if (i==timeArr1.count - 1) {
            [spraysArr addObject:[NSString stringWithFormat:@"%d",index]];
        }
    }
    
    NSArray *timeStrArr = [timeArr2.lastObject componentsSeparatedByString:@"/"];
    for (NSInteger j = 0; j < timeArr2.count; j++) {
        NSArray *totalTimeStrArr = [timeArr2[j] componentsSeparatedByString:@"/"];
        if ([totalTimeStrArr[0] isEqualToString:timeStrArr[0]]) {
            HistoryModel *model = [[HistoryModel alloc] init];
            model.time = timeArr2[j];
            model.number = [spraysArr[j] integerValue];
            model.sum = [spraysArr[j] integerValue] * AMOUNT;
            [self.dataArr addObject:model];
        }
    }
    
    NSMutableArray * monthTimeArr1 = [NSMutableArray array];
    NSMutableArray * monthTimeArr2 = [NSMutableArray array];
    NSMutableArray * monthSpraysArr = [NSMutableArray array];
    NSInteger index1 = 0;
    for (NSString * monthTimeStr in timeArr3) {
        NSTimeInterval time=[monthTimeStr doubleValue];
        NSDate *detaildate=[NSDate dateWithTimeIntervalSince1970:time];
        //实例化一个NSDateFormatter对象
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        //设定时间格式,这里可以设置成自己需要的格式
        [dateFormatter setDateFormat:@"MMM"];
        NSString *currentDateStr = [dateFormatter stringFromDate: detaildate];
        [monthTimeArr1 addObject:currentDateStr];
    }
    NSString * monthStr = monthTimeArr1[0];
    [monthTimeArr2 addObject:monthStr];
    for (int i = 0; i < monthTimeArr1.count; i++) {
        if ([monthStr isEqualToString:monthTimeArr1[i]]) {
            index1 += [spraysArr[i] integerValue];
        }else{
            monthStr = monthTimeArr1[i];
            [monthTimeArr2 addObject:monthTimeArr1[i]];
            [monthSpraysArr addObject:[NSString stringWithFormat:@"%ld",(long)index1]];
            index1 = [spraysArr[i] integerValue];
        }
        if (i==monthTimeArr1.count - 1) {
            [monthSpraysArr addObject:[NSString stringWithFormat:@"%ld",(long)index1]];
        }
    }
    for (NSInteger j = 0; j < monthTimeArr2.count; j++) {
        HistoryModel *model = [[HistoryModel alloc] init];
        model.time = monthTimeArr2[j];
        model.number = [monthSpraysArr[j] integerValue];
        model.sum = [monthSpraysArr[j] integerValue] * AMOUNT;
        [self.monthDataArr addObject:model];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
