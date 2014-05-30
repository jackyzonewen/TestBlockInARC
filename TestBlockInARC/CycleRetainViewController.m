//
//  CycleRetainViewController.m
//  TestBlockInARC
//
//  Created by xujunwen on 14-5-30.
//  Copyright (c) 2014年 福建星网视易信息系统有限公司. All rights reserved.
//

#import "CycleRetainViewController.h"
#import "ViewController.h"

@interface CycleRetainViewController ()

@property (nonatomic, copy) EVBlock testCycleBlock;

@end

@implementation CycleRetainViewController

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
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self testCycleRetain];
}

// 切换开关看效果
#define TEST_CYCLE_RETAIN_CASE1 1
//#define TEST_CYCLE_RETAIN_CASE2 1
//#define TEST_CYCLE_RETAIN_CASE3 1
//#define TEST_CYCLE_RETAIN_CASE4 1

/**
 *  测试是否会产生循环引用的问题，如果产生的循环引用，那么就不会被释放，dealloc就不会执行
 */
- (void)testCycleRetain
{
#if TEST_CYCLE_RETAIN_CASE1
    
    // 会循环引用
    self.testCycleBlock = ^{
        
        [self doSomeThing];
    };
    
#elif TEST_CYCLE_RETAIN_CASE2
    
    // 会循环引用
    __block CycleRetainViewController *blockSelf = self;
    self.testCycleBlock = ^{
        [blockSelf doSomeThing];
    };
    
#elif TEST_CYCLE_RETAIN_CASE3
    
    // 不会循环引用
    __weak CycleRetainViewController *weakSelf = self;
    self.testCycleBlock = ^{
        [weakSelf doSomeThing];
    };
    
#elif TEST_CYCLE_RETAIN_CASE4
    
    // 不会循环引用
    __unsafe_unretained CycleRetainViewController *weakSelf = self;
    self.testCycleBlock = ^{
        [weakSelf doSomeThing];
    };
    
#endif
    
    NSLog(@"testCycleBlock is %@", self.testCycleBlock);
    self.testCycleBlock();
}

- (void)doSomeThing
{
    NSLog(@"do something");
}


- (void)dealloc
{
    NSLog(@"CycleRetainViewController dealloc, no cycle retain");
}


@end
