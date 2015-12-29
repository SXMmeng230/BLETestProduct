//
//  ViewController.m
//  BLETestProduct
//
//  Created by mac on 15/12/29.
//  Copyright © 2015年 孙晓萌. All rights reserved.
//

#import "ViewController.h"
#import "BLECenterViewController.h"
#import "BLEPreipheralViewController.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"蓝牙测试";
    // Do any additional setup after loading the view, typically from a nib.
}
- (IBAction)clickBtn:(UIButton *)sender {
    BLECenterViewController *vc = [[BLECenterViewController alloc] init];
    [self.navigationController pushViewController:vc
                                         animated:YES];
}
- (IBAction)clickWeiBtn:(UIButton *)sender {
    BLEPreipheralViewController *vc = [[BLEPreipheralViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
