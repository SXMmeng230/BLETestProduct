//
//  BLEPreipheralViewController.m
//  BLETestProduct
//
//  Created by mac on 15/12/29.
//  Copyright © 2015年 孙晓萌. All rights reserved.
//

#import "BLEPreipheralViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>
static NSString *const ServiceUUID1 =  @"FFF0";
static NSString *const notiyCharacteristicUUID =  @"FFF1";
static NSString *const readwriteCharacteristicUUID =  @"FFF2";
static NSString *const ServiceUUID2 =  @"FFE0";
static NSString *const readCharacteristicUUID =  @"FFE1";
static NSString * const LocalNameKey =  @"myPeripheral";

@interface BLEPreipheralViewController ()<CBPeripheralManagerDelegate>
@property (nonatomic, strong) CBPeripheralManager *manager;
@property (nonatomic, strong) NSArray *arr;
@property (strong, nonatomic) IBOutlet UILabel *textLabel;
@property (nonatomic, strong) CBCharacteristic *preCharacteistic;
@property (nonatomic, strong) CBCharacteristic *nextCharacteistic;
@end

@implementation BLEPreipheralViewController
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.manager stopAdvertising];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.manager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)preBtn:(UIButton *)sender {
    NSString *str = @"start";
    [self.manager updateValue:[str dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:(CBMutableCharacteristic *)self.preCharacteistic onSubscribedCentrals:nil];
}
- (IBAction)nextBtn:(UIButton *)sender {
    NSString *str = @"pause";
    [self.manager updateValue:[str dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:(CBMutableCharacteristic *)self.preCharacteistic onSubscribedCentrals:nil];

}
#pragma mark - CBPeripheralManagerDelegate
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    switch (peripheral.state) {
        case CBPeripheralManagerStatePoweredOn:
            [self setUp];
            break;
            
        default:
            break;
    }
}
-(void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic{
    NSLog(@"订阅了 %@的数据",characteristic.UUID);
}

//perihpheral添加了service
- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error{

    [self.manager startAdvertising:@{CBAdvertisementDataServiceUUIDsKey : @[[CBUUID UUIDWithString:ServiceUUID1]],  CBAdvertisementDataLocalNameKey : LocalNameKey}];
    
    
}
- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error
{
}
//写characteristics请求
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray *)requests{
    NSLog(@"didReceiveWriteRequests");
    CBATTRequest *request = requests[0];
    
    //判断是否有写数据的权限
    if (request.characteristic.properties & CBCharacteristicPropertyWrite) {
        //需要转换成CBMutableCharacteristic对象才能进行写值
        CBMutableCharacteristic *c =(CBMutableCharacteristic *)request.characteristic;
        c.value = request.value;
        NSString *value = [[NSString alloc]initWithData:c.value encoding:NSUTF8StringEncoding];
        self.textLabel.text = value;
        NSLog(@"%@",value);
        [self.manager respondToRequest:request withResult:CBATTErrorSuccess];
    }else{
        [self.manager respondToRequest:request withResult:CBATTErrorWriteNotPermitted];
    }
    
    
}
//配置bluetooch的
-(void)setUp{
    //characteristics字段描述
    CBUUID *CBUUIDCharacteristicUserDescriptionStringUUID = [CBUUID UUIDWithString:CBUUIDCharacteristicUserDescriptionString];
    
    /*
     可以通知的
     */
    CBMutableCharacteristic *notiyCharacteristic = [[CBMutableCharacteristic alloc]initWithType:[CBUUID UUIDWithString:notiyCharacteristicUUID] properties:CBCharacteristicPropertyNotify value:nil permissions:CBAttributePermissionsReadable];
    
    /*
     可读写的
     */
    CBMutableCharacteristic *readwriteCharacteristic = [[CBMutableCharacteristic alloc]initWithType:[CBUUID UUIDWithString:readwriteCharacteristicUUID] properties:CBCharacteristicPropertyWrite | CBCharacteristicPropertyRead value:nil permissions:CBAttributePermissionsReadable | CBAttributePermissionsWriteable];
    //设置description
    CBMutableDescriptor *readwriteCharacteristicDescription1 = [[CBMutableDescriptor alloc]initWithType: CBUUIDCharacteristicUserDescriptionStringUUID value:@"name"];
    [readwriteCharacteristic setDescriptors:@[readwriteCharacteristicDescription1]];
    
    /*
     只读的Characteristic
     */
    CBMutableCharacteristic *readCharacteristic = [[CBMutableCharacteristic alloc]initWithType:[CBUUID UUIDWithString:readCharacteristicUUID] properties:CBCharacteristicPropertyRead value:nil permissions:CBAttributePermissionsReadable];
    self.preCharacteistic = notiyCharacteristic;
    
    //service1初始化并加入两个characteristics
    CBMutableService *service1 = [[CBMutableService alloc]initWithType:[CBUUID UUIDWithString:ServiceUUID1] primary:YES];
    NSLog(@"%@",service1.UUID);
    
    [service1 setCharacteristics:@[notiyCharacteristic,readwriteCharacteristic]];
    
    //service2初始化并加入一个characteristics
    CBMutableService *service2 = [[CBMutableService alloc]initWithType:[CBUUID UUIDWithString:ServiceUUID2] primary:YES];
    NSLog(@"%@",service2.UUID);
    [service2 setCharacteristics:@[readCharacteristic]];
    
    [self.manager addService:service1];
//    [self.manager addService:service2];
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
