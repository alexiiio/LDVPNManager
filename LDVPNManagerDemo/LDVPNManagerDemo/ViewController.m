//
//  ViewController.m
//  LDVPNManagerDemo
//
//  Created by lidi on 2018/12/25.
//  Copyright © 2018 Li. All rights reserved.
//

#import "ViewController.h"
#import "LDVPNManager.h"
@interface ViewController ()<LDVPNManagerDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [LDVPNManager shareManager].delegate = self;
    
}
- (IBAction)startVPNConnect:(id)sender {
    [[LDVPNManager shareManager]setUpIPSec];
    
}

- (IBAction)stopVPNConnect:(id)sender {
    [[LDVPNManager shareManager]stopVPNConnect];
}
- (void)vpnSavedSuccess {
    [[LDVPNManager shareManager]startVPNConnect];
}
- (void)vpnDidConnected {
    NSLog(@"VPN 连接成功");
    self.view.backgroundColor = [UIColor orangeColor];
}
- (void)vpnDidDisconnected {
    self.view.backgroundColor = [UIColor whiteColor];
}
@end
