//
//  LDVPNManager.h
//  VPNDemo
//
//  Created by lidi on 2018/8/1.
//  Copyright © 2018年 Li. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <NetworkExtension/NetworkExtension.h>
@class LDVPNManager;
@protocol LDVPNManagerDelegate<NSObject>
@optional
/**
 VPN 保存失败
 */
-(void)vpnSavedFail;
/**
 VPN 保存成功
 */
-(void)vpnSavedSuccess;
/**
 VPN 连接成功
 */
-(void)vpnDidConnected;
/**
 VPN 断开连接
 */
-(void)vpnDidDisconnected;

 /**
 监听vpn的状态变化
 @param vpnManager LDVPNManager单例对象
 @param status NEVPNStatus
 */
-(void)LDVPNManager:(LDVPNManager *)vpnManager onVPNStatusChanged:(NEVPNStatus)status;
@end

@interface LDVPNManager : NSObject
@property(nonatomic,strong)NEVPNManager *manager;
@property(nonatomic,weak)id<LDVPNManagerDelegate> delegate;
@property(nonatomic,assign)BOOL expectedVpnConnect;
/**
 连接到该数组中SSID的wifi时，自动断开VPN
 */
@property(nonatomic,strong)NSArray *disconnectedSSIDMatch;
/**
  URL数组  NSString类型
 */
@property(nonatomic,strong)NSArray<NSString *> *connectUrls;
/**
   URL数组  NSString类型
 */
@property(nonatomic,strong)NSArray<NSString *> *disConnectUrls;
+(instancetype)shareManager;
/**
 配置IPSec协议的VPN
 */
-(void)setUpIPSec;
/**
 配置IKEV2协议的VPN
 */
-(void)setUpIKEV2VPN;
/**
 开启VPN连接，需要先配置
 */
-(void)startVPNConnect;
/**
 断开VPN连接
 */
-(void)stopVPNConnect;
@end
