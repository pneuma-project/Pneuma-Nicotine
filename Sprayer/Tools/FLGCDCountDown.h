//
//  FLGCDCountDown.h
//  Sprayer
//
//  Created by fanglin on 2019/7/2.
//  Copyright © 2019 FangLin. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum _ActionType {
    InquireHistory,  //查询历史
    StartTraining,   //开始训练
    EndTraining,     //结束训练
    RealSpray,      //实时喷雾
    RealConfirmCode,  //实时确认码
    HistoryConfirmCode  //历史确认码
}ActionType;

@interface FLGCDCountDown : NSObject

@property(nonatomic,assign)ActionType type;

@property(nonatomic,strong,nullable)dispatch_source_t timer;

+(instancetype)manager;

/*
 启动定时器
 */
-(void)resume;

/*
 暂停定时器
 */
-(void)pause;

/*
 重新加载计时器
 */
-(void)reset;

/*
 取消定时器
 */
-(void)cancel;

@end

NS_ASSUME_NONNULL_END
