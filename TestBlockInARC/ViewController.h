//
//  ViewController.h
//  TestBlockInARC
//
//  Created by xujunwen on 14-5-30.
//  Copyright (c) 2014年 福建星网视易信息系统有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^EVBlock)(void);            // 声明一个返回类型为void，不包含参数
typedef void (^EVObjectBlock)(id obj);    // 声明一个返回类型为void，参数为一个对象
typedef int  (^EVSumBlock)(int a, int b); // ···你懂的

@interface ViewController : UIViewController

@end
