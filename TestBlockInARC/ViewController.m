//
//  ViewController.m
//  TestBlockInARC
//
//  Created by xujunwen on 14-5-30.
//  Copyright (c) 2014年 福建星网视易信息系统有限公司. All rights reserved.
//

#import "ViewController.h"
#import "CycleRetainViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    [self testBlockType];
    NSLog(@"\n\n");
    
    [self testBlockLife];
    NSLog(@"\n\n");
    
    [self testBlockUseBasicVariable];
    NSLog(@"\n\n");
    
    [self testBlockUseObjectVariable];
    NSLog(@"\n\n");
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/**
 *  Block有多中类型，Global、Stack、Malloc、ConcreteWeak、ConcreteAuto、ConcreteFinalizing (后三种使用GC）
 */
- (void)testBlockType
{
    NSLog(@"========testBlockType begin========");
    
    // 1. __NSGlobalBlock__ 类型，没有访问外部变量，类似于函数
    EVSumBlock globalBlock = ^int(int a, int b){
        return a + b;
    };
    NSLog(@"block is %@", globalBlock);
    
    
    // 2.__NSMallocBlock__ 类型，保存在堆内存中，当引用计数为0时会被销毁。(如果在非ARC下，打印的是__NSStackBlock
    // __类型，当函数返回的时候block销毁；这里因为ARC下经过strong类型指针过了一趟手后，对NSStackBlock进行了Copy操
    // 作，所以block拷贝到堆中了)
    NSArray *arrTest = @[@1, @2];
    EVBlock stackBlock = ^{
        NSLog(@"Array : %@", arrTest);
    };
    NSLog(@"block is %@", stackBlock);
    
    NSLog(@"========testBlockType end========");
}

/**
 * ARC下的生命周期
 * 总结：1.只要经过stong指针过手，block都位于堆内存，NSMallocBlock类型。
        2.从1知道，当block作为函数返回时，block自动拷贝到堆上，无需非ARC下的类似这样的操作[[block copy] autorelease]
        3.匿名block和weak指针修饰的block位于栈上，函数结束后释放，这也就是在非ARC下主要注意的问题。
 */
- (void)testBlockLife
{
    NSLog(@"========testBlockLife begin========");
    
    __block int blockVariable = 0;
    
    // strong指针指向的block位于堆上，arc默认都是strong指针
    __strong EVBlock strongBlock = ^{
        NSLog(@"blockVariable = %d", ++blockVariable);
    };
    NSLog(@"strongBlock is %@", strongBlock);
    
    // weak指针指向的block在栈上
    __weak EVBlock weakBlock = ^{
        NSLog(@"blockVariable = %d", ++blockVariable);
    };
    NSLog(@"weakBlock is %@", weakBlock);
    
    // copy操作会将block从栈上移到堆上
    NSLog(@"weakBlock copy is %@", [weakBlock copy]);
    
    // 匿名的Block在栈上
    NSLog(@"noName block is %@", ^{NSLog(@"blockVariable = %d", ++blockVariable);});
    
    NSLog(@"========testBlockLife end========");
}

/**
 *  block访问基本类型变量，ARC和非ARC规则一样
 *  总结:1.对于局部自动变量，block【定义】的时候，将其拷贝一份保存到block内(结构体中的variables字段http://blog.devtang.com/blog/2013/07/28/a-look-inside-blocks/)，执行block的时候，当作常量使用
        2.全局变量或者静态变量在内存中的地址是固定的，block读取该值直接从内存中读取，而不是copy到block内。
        3.__block修饰的变量作用等效于全局变量或静态变量，但是他们不是一个"东西"
 */
- (void)testBlockUseBasicVariable
{
    NSLog(@"========testBlockUseBasicVariable begin========");
    
    // 1 自动变量
    int localVariable = 100;
    NSLog(@"localVariable addr :%p", &localVariable);
    
    EVSumBlock sumBlock = ^int(int a, int b){
        NSLog(@"localVariable addr in block :%p", &localVariable); // 看看地址就知道，此物非彼物，不是一个东西
        return a + b + localVariable;
    };
    
    localVariable = 0;
    NSLog(@"sum = %d", sumBlock(1, 2)); // 你猜是多少？103 why？总结1
    
    
    // 2.static修饰的全局变量
    static int staticVariable = 100;
    NSLog(@"staticVariable addr :%p", &staticVariable);
    
    EVSumBlock sumBlock1 = ^int(int a, int b){
        staticVariable++;
        NSLog(@"staticVariable addr in block :%p", &staticVariable); // 诶，不错哦，一个东西
        
        return a + b + staticVariable;
    };
    
    staticVariable = 0;
    NSLog(@"sum = %d", sumBlock1(1, 2)); // 结果为4
    NSLog(@"staticVariable = %d", staticVariable); // 结果为1，因为执行sumBlock1的时候加1了

    // 3.__block修饰的变量
    __block int blockVariable = 100;
    NSLog(@"blockVariable addr :%p", &blockVariable);
    
    EVSumBlock sumBlock2 = ^int(int a, int b){
        blockVariable++;
        NSLog(@"blockVariable addr in block :%p", &blockVariable); // 哎哟，不是一个东西
        
        return a + b + blockVariable;
    };
    
    blockVariable = 0;
    NSLog(@"sum = %d", sumBlock2(1, 2)); // 结果为4
    NSLog(@"blockVariable = %d", blockVariable); // 结果为1，因为执行sumBlock2的时候加1了
    
    NSLog(@"========testBlockUseBasicVariable end========");
}

/**
 *  ARC中block访问对象，arc下没有retain或者retainCount的概念
 *  总结：1.当block中引用全局变量、static变量或block变量，会强引用指向的对象一次。
         2.仅仅当block中访问local对象的时候，block会【复制指针】，且强引用指向的对象一次。
 */

UIView *globalView = nil;

- (void)testBlockUseObjectVariable
{
    NSLog(@"========testBlockUseObjectVariable begin========");
    
    // 1. 局部自动变量
    UIView *localView = [[UIView alloc] init];
    NSLog(@"localObject : %@", localView);
    EVBlock localBlock = ^{
        NSLog(@"localObject in block : %@", localView);
    };
    localView = nil;
    localBlock(); // localObject in block : <UIView: 0x8d7b6d0; frame = (0 0; 0 0); layer = <CALayer: 0x8d72e90>>
    
    // 2.全局变量
    globalView = [[UIView alloc] init];
    NSLog(@"globalObject : %@", globalView);
    EVBlock globalBlock = ^{
        NSLog(@"globalObject in block : %@", globalView);
    };
    globalView = nil;
    globalBlock(); // globalObject in block : (null)
    
    // 3.static变量
    static UIView *staticView = nil;
    staticView = [[UIView alloc] init];
    NSLog(@"staticObject : %@", staticView);
    EVBlock staticBlock = ^{
        NSLog(@"staticObject in block : %@", staticView);
    };
    staticView = nil;
    staticBlock(); // staticObject in block : (null)
    
    // 4.block变量
    __block UIView *blockView = nil;
    blockView = [[UIView alloc] init];
    NSLog(@"blockObject : %@", blockView);
    EVBlock blockBlock = ^{
        NSLog(@"blockObject in block : %@", blockView);
    };
    blockView = nil;
    blockBlock(); // blockObject in block : (null)
    
    // 5.weak变量
    localView = [[UIView alloc] init];
    __weak UIView *weakView = localView;
    NSLog(@"weakObject : %@", weakView);
    EVBlock weakBlock = ^{
        NSLog(@"weakObject in block : %@", weakView); // 避免循环引用的解决方案
    };
    localView = nil;
    weakBlock();
    
    NSLog(@"========testBlockUseObjectVariable end========");
}

- (IBAction)enterCycleRetain:(id)sender
{
    CycleRetainViewController *vc = [[CycleRetainViewController alloc] initWithNibName:nil bundle:nil];
    [self.navigationController pushViewController:vc animated:YES];
}

@end
