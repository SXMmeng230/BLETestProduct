//
//  BLECenterViewController.m
//  BLETestProduct
//
//  Created by mac on 15/12/29.
//  Copyright © 2015年 孙晓萌. All rights reserved.
//

#import "BLECenterViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import <AVFoundation/AVFoundation.h>
@interface BLECenterViewController ()<CBCentralManagerDelegate,CBPeripheralDelegate,UITableViewDataSource,UITableViewDelegate,AVAudioPlayerDelegate>
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) CBCentralManager *manager;
@property (nonatomic, strong) CBPeripheral *peripheral;
@property (nonatomic, strong) CBCharacteristic *characteristic;
@property (nonatomic, strong) NSMutableArray *centralArray;
@property (nonatomic,strong) AVAudioPlayer *audioPlayer;//播放器
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityView;
@property (strong, nonatomic) IBOutlet UILabel *textLabel;
@property (strong, nonatomic) IBOutlet UIButton *startBtn;

@end

@implementation BLECenterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.centralArray = [NSMutableArray array];
    self.activityView.hidden = YES;
}
-(AVAudioPlayer *)audioPlayer{
    if (!_audioPlayer) {
        NSString *urlStr=[[NSBundle mainBundle]pathForResource:@"1" ofType:@"mp3"];
        NSURL *url=[NSURL fileURLWithPath:urlStr];
        NSError *error=nil;
        //初始化播放器，注意这里的Url参数只能时文件路径，不支持HTTP Url
        _audioPlayer=[[AVAudioPlayer alloc]initWithContentsOfURL:url error:&error];
        //设置播放器属性
        _audioPlayer.numberOfLoops=0;//设置为0不循环
        _audioPlayer.delegate=self;
        [_audioPlayer prepareToPlay];//加载音频文件到缓存
        if(error){
            NSLog(@"初始化播放器过程发生错误,错误信息:%@",error.localizedDescription);
            return nil;
        }
    }
    return _audioPlayer;
}
- (IBAction)writeBtn:(UIButton *)sender
{
    NSString *str = @"这个是中心设备发出来的信号";
    [self.peripheral writeValue:[str dataUsingEncoding:NSUTF8StringEncoding]
              forCharacteristic:self.characteristic type:CBCharacteristicWriteWithResponse];
}
- (IBAction)startCan:(UIButton *)sender
{
    if (!sender.selected) {
        self.activityView.hidden = NO;
        [self.centralArray removeAllObjects];
        self.manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        [self.activityView startAnimating];
    }else {
        self.activityView.hidden = YES;
        [self.manager stopScan];
        [self.activityView stopAnimating];
    }
    sender.selected = !sender.selected;
}
#pragma mark - CBCentralManagerDelegate
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    switch (central.state) {
        case CBCentralManagerStatePoweredOn:
            //开始扫描周围的外设
            /*
             第一个参数nil就是扫描周围所有的外设，扫描到外设后会进入
             */
            [self.manager scanForPeripheralsWithServices:nil options:nil];
            break;
        default:
            NSLog(@"该设备不支持此扫描功能");
            break;
    }
}
//扫描到外设备
 - (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSLog(@"扫描到 -- %@",peripheral.name);
    if (peripheral.name.length == 0) {
        return;
    }
    if ([self.centralArray containsObject:peripheral]) {
        return;
    }
    [self.centralArray addObject:peripheral];
    [self.tableView reloadData];

}
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"连接%@成功",peripheral.name);
    self.textLabel.text = [NSString stringWithFormat:@"已成功连接到--%@设备,请通过设备来操作!",peripheral.name];
    [self startCan:self.startBtn];
    self.peripheral = peripheral;
    [peripheral setDelegate:self];
    [peripheral discoverServices:nil];

}
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"断开连接%@",peripheral.name);
}
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"连接%@失败",peripheral.name);

}
#pragma mark - CBPeripheralDelegate
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    NSLog(@"外设服务: %@",peripheral.services);
    if (error) {
        NSLog(@"设备 %@ 出现服务错误 %@",peripheral.name,[error localizedDescription]);
    }
    for (CBService *service in peripheral.services) {
        [peripheral discoverCharacteristics:nil forService:service];
    }
}
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    NSLog(@"外设特征值: %@",service.UUID);
    if (error) {
        NSLog(@"特征值 %@ 出现服务错误 %@",service.UUID,[error localizedDescription]);
    }

    for (CBCharacteristic *characteristic in service.characteristics){
        {
//            [peripheral readValueForCharacteristic:characteristic];
            self.characteristic = characteristic;
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];

        }
    }
    //搜索Characteristic的Descriptors，
    for (CBCharacteristic *characteristic in service.characteristics){
        [peripheral discoverDescriptorsForCharacteristic:characteristic];
    }


}
//值改变时,触发代理
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSLog(@"UUID的值:%@ value:%@",characteristic.UUID,characteristic.value);
    NSString *value = [[NSString alloc]initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    NSLog(@"value:%@",value);
    CBUUID *UUID1 = [CBUUID UUIDWithString:@"FFF1"];
    if ([characteristic.UUID isEqual:UUID1]) {
        if ([value isEqualToString:@"start"]) {
            [self.audioPlayer play];
        }else if ([value isEqualToString:@"pause"]){
            [self.audioPlayer pause];
        }
    }
}
//搜索到Descriptors时,触发代理
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    for (CBDescriptor *d in characteristic.descriptors) {
        NSLog(@"Descriptor value:%@",d.value);
    }
    
}
//获取到Descriptors的值时,触发代理
-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error{
    //打印出DescriptorsUUID 和value
    NSLog(@"characteristic uuid:%@  value:%@",[NSString stringWithFormat:@"%@",descriptor.UUID],descriptor.value);
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return  self.centralArray.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *indentifier = @"indentifierCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:indentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:indentifier];
    }
    cell.textLabel.text = [self.centralArray[indexPath.row] name];
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    //连接
    [self.manager connectPeripheral:self.centralArray[indexPath.row] options:nil];
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
