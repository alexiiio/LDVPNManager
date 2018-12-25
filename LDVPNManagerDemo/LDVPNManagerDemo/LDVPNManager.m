//
//  LDVPNManager.m
//  VPNDemo
//
//  Created by lidi on 2018/8/1.
//  Copyright © 2018年 Li. All rights reserved.
//

#import "LDVPNManager.h"
// VPN配置信息
static NSString *VPNServerAddress = @"xx.xxx.xxx.xxx";  // VPN服务器地址
static NSString *VPNUserName = @"vpnuser"; // 用户名
static NSString *VPNPassWord = @"vpnpassword"; // 密码
static NSString *VPNSharedSecret = @"vpnsharesecret"; // 共享秘钥
static NSString *VPNLocalizedDescription = @"🎄❄️圣诞快乐🎅🍬"; // VPN的名称，会显示在设置里
//#define VPNLocalizedDescription [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"]
@implementation LDVPNManager

static LDVPNManager *instance;

+(instancetype)shareManager{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[LDVPNManager alloc]init];
        instance.manager = [NEVPNManager sharedManager];
        [[NSNotificationCenter defaultCenter] addObserver:instance selector:@selector(onVpnStateChange:) name:NEVPNStatusDidChangeNotification object:nil];
    });
    return instance;
}
-(void)setUpIPSec{
    [self.manager loadFromPreferencesWithCompletionHandler:^(NSError * _Nullable error) {
        NSError *errors = error;
        if (errors) {
            NSLog(@"%@",errors);
        }else{
            NEVPNProtocolIPSec *p = [[NEVPNProtocolIPSec alloc] init];
            p.username = VPNUserName;
            p.serverAddress = VPNServerAddress;
            [self createKeychainValue:VPNPassWord forIdentifier:@"VPN_PASSWORD"];
            p.passwordReference =  [self searchKeychainCopyMatching:@"VPN_PASSWORD"];
            [self createKeychainValue:VPNSharedSecret forIdentifier:@"PSK"];
            p.sharedSecretReference = [self searchKeychainCopyMatching:@"PSK"];
            //            p.localIdentifier = [UIDevice currentDevice].name;
            //            p.remoteIdentifier = @"139.196.217.80";
 
            p.authenticationMethod = NEVPNIKEAuthenticationMethodSharedSecret;
            p.useExtendedAuthentication = YES;
            p.disconnectOnSleep = NO;
            if (@available(iOS 9.0, *)) {
                [self.manager setProtocolConfiguration:p];
            } else {
                self.manager.protocol = p;
            }
            self.manager.localizedDescription = VPNLocalizedDescription;
            // 配置按需连接的规则
            NSMutableArray *rules = [NSMutableArray arrayWithCapacity:10];
            if (self.disconnectedSSIDMatch) {
                NEOnDemandRuleDisconnect *ruleDisconnect = [[NEOnDemandRuleDisconnect alloc]init];
                ruleDisconnect.SSIDMatch = self.disconnectedSSIDMatch;
                [rules addObject:ruleDisconnect];
            }
            if (self.connectUrls) {
                for (NSString *url in self.connectUrls) {
                    NEOnDemandRuleConnect *rule = [[NEOnDemandRuleConnect alloc]init];
                    rule.probeURL = [NSURL URLWithString:url];
                    [rules addObject:rule];
                }
            }
            if (self.disConnectUrls) {
                for (NSString *url in self.connectUrls) {
                    NEOnDemandRuleDisconnect *rule = [[NEOnDemandRuleDisconnect alloc]init];
                    rule.probeURL = [NSURL URLWithString:url];
                    [rules addObject:rule];
                }
            }
            if (rules.count>0) {
                self.manager.onDemandRules = rules;
                [self.manager setOnDemandEnabled:YES];
            }
            self.manager.enabled = YES;
            [self.manager saveToPreferencesWithCompletionHandler:^(NSError *error) {
                if(error) {
                    NSLog(@"Save error: %@", error);
                    if ([self.delegate respondsToSelector:@selector(vpnSavedFail)]) {
                        [self.delegate vpnSavedFail];
                    }
                }else {
                    NSLog(@"Saved!");
                    if ([[NSUserDefaults standardUserDefaults]boolForKey:@"alreadySavedOnce"]) {
                        if ([self.delegate respondsToSelector:@selector(vpnSavedSuccess)]) {
                            [self.delegate vpnSavedSuccess];
                        }
                    }else{
                        NSLog(@"第一次配置VPN成功");
                        [[NSUserDefaults standardUserDefaults]setBool:YES forKey:@"alreadySavedOnce"];
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            if ([self.delegate respondsToSelector:@selector(vpnSavedSuccess)]) {
                                [self.delegate vpnSavedSuccess];
                            }
                        });
                    }
                }
            }];
        }
    }];
}

-(void)onVpnStateChange:(NSNotification *)Notification {
    
    NEVPNStatus state = self.manager.connection.status;
    if ([self.delegate respondsToSelector:@selector(LDVPNManager:onVPNStatusChanged:)]) {
        [self.delegate LDVPNManager:self onVPNStatusChanged:state];
    }
    static BOOL isFirstLoad = YES;
    switch (state) {
        case NEVPNStatusInvalid:
            NSLog(@"无效vpn连接");
            break;
        case NEVPNStatusDisconnected:
            NSLog(@"vpn未连接");
            // 刚启动的时候会走vpn未连接
            if (isFirstLoad) {
                isFirstLoad = NO;
                return ;
            }
            if ([self.delegate respondsToSelector:@selector(vpnDidDisconnected)]) {
                [self.delegate vpnDidDisconnected];
            }
            break;
        case NEVPNStatusConnecting:
            NSLog(@"vpn正在连接");
            break;
        case NEVPNStatusConnected:
            NSLog(@"vpn已连接");
            if ([self.delegate respondsToSelector:@selector(vpnDidConnected)]) {
                [self.delegate vpnDidConnected];
            }
            break;
        case NEVPNStatusDisconnecting:
            NSLog(@"vpn断开连接");
            break;
        default:
            break;
    }
}

- (void)startVPNConnect{
    if (self.manager.connection.status!=NEVPNStatusConnecting && self.manager.connection.status!=NEVPNStatusConnected) {
        NSError *error = nil;
        [self.manager.connection startVPNTunnelAndReturnError:&error];
        if(error) {
            NSLog(@"Start error: %@", error.localizedDescription);
        }else{
            NSLog(@"Connection established!");
        }
    }else{
        if (self.manager.connection.status == NEVPNStatusConnected) {
            if ([self.delegate respondsToSelector:@selector(vpnDidConnected)]) {
                [self.delegate vpnDidConnected];
            }
        }
    }
}
-(void)stopVPNConnect{
    if (self.manager.connection.status>=NEVPNStatusConnecting) {
//        self.expectedVpnConnect = NO;
        [self.manager.connection stopVPNTunnel];
    }
}
- (NSData *)searchKeychainCopyMatching:(NSString *)identifier {
    NSMutableDictionary *searchDictionary = [self newSearchDictionary:identifier];
    [searchDictionary setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
    [searchDictionary setObject:@YES forKey:(__bridge id)kSecReturnPersistentRef];
    CFTypeRef result = NULL;
    SecItemCopyMatching((__bridge CFDictionaryRef)searchDictionary, &result);
    return (__bridge_transfer NSData *)result;
}

- (BOOL)createKeychainValue:(NSString *)password forIdentifier:(NSString *)identifier {
    // creat a new item
    NSMutableDictionary *dictionary = [self newSearchDictionary:identifier];
    //OSStatus 就是一个返回状态的code 不同的类返回的结果不同
    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)dictionary);
    NSData *passwordData = [password dataUsingEncoding:NSUTF8StringEncoding];
    [dictionary setObject:passwordData forKey:(__bridge id)kSecValueData];
    status = SecItemAdd((__bridge CFDictionaryRef)dictionary, NULL);
    if (status == errSecSuccess) {
        return YES;
    }
    return NO;
}

static NSString * const serviceName = @"AleX.VPNDemo";

- (NSMutableDictionary *)newSearchDictionary:(NSString *)identifier {
    //   keychain item creat
    NSMutableDictionary *searchDictionary = [[NSMutableDictionary alloc] init];
    //   extern CFTypeRef kSecClassGenericPassword  一般密码
    //   extern CFTypeRef kSecClassInternetPassword 网络密码
    //   extern CFTypeRef kSecClassCertificate 证书
    //   extern CFTypeRef kSecClassKey 秘钥
    //   extern CFTypeRef kSecClassIdentity 带秘钥的证书
    [searchDictionary setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
    NSData *encodedIdentifier = [identifier dataUsingEncoding:NSUTF8StringEncoding];
    [searchDictionary setObject:encodedIdentifier forKey:(__bridge id)kSecAttrGeneric];
    //ksecClass 主键
    [searchDictionary setObject:encodedIdentifier forKey:(__bridge id)kSecAttrAccount];
    [searchDictionary setObject:serviceName forKey:(__bridge id)kSecAttrService];
    return searchDictionary;
}


-(void)setUpIKEV2VPN{
    [self.manager loadFromPreferencesWithCompletionHandler:^(NSError * _Nullable error) {
        NSError *errors = error;
        if (errors) {
            NSLog(@"%@",errors);
        }else{
            NEVPNProtocolIKEv2 *p = [[NEVPNProtocolIKEv2 alloc] init];
            p.username = VPNUserName;
            p.serverAddress = VPNServerAddress;
            [self createKeychainValue:VPNPassWord forIdentifier:@"VPN_PASSWORD"];
            p.passwordReference =  [self searchKeychainCopyMatching:@"VPN_PASSWORD"];

//            p.authenticationMethod = NEVPNIKEAuthenticationMethodSharedSecret;
            p.authenticationMethod = NEVPNIKEAuthenticationMethodCertificate;
            p.identityData = [NSData dataWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"hctx" ofType:@"p12"]];
            p.identityDataPassword = @"com.hctx.vpn";  // p12证书的密码
//            p.identityDataPassword = xxx;
//            [self createKeychainValue:VPNSharedSecret forIdentifier:@"PSK"];
//            p.sharedSecretReference = [self searchKeychainCopyMatching:@"PSK"];
            
//            p.localIdentifier = @"[VPN local identifier]";
            p.remoteIdentifier = @"58.222.107.149";
            
            p.useExtendedAuthentication = YES;
            
            p.disconnectOnSleep = NO;
            if (@available(iOS 9.0, *)) {
                [self.manager setProtocolConfiguration:p];
            } else {
                self.manager.protocol = p;
            }
            self.manager.localizedDescription = VPNLocalizedDescription;
            // 配置按需连接的规则
            NSMutableArray *rules = [NSMutableArray arrayWithCapacity:10];
            if (self.disconnectedSSIDMatch) {
                NEOnDemandRuleDisconnect *ruleDisconnect = [[NEOnDemandRuleDisconnect alloc]init];
                ruleDisconnect.SSIDMatch = self.disconnectedSSIDMatch;
                [rules addObject:ruleDisconnect];
            }
            if (self.connectUrls) {
                for (NSString *url in self.connectUrls) {
                    NEOnDemandRuleConnect *rule = [[NEOnDemandRuleConnect alloc]init];
                    rule.probeURL = [NSURL URLWithString:url];
                    [rules addObject:rule];
                }
            }
            if (self.disConnectUrls) {
                for (NSString *url in self.connectUrls) {
                    NEOnDemandRuleDisconnect *rule = [[NEOnDemandRuleDisconnect alloc]init];
                    rule.probeURL = [NSURL URLWithString:url];
                    [rules addObject:rule];
                }
            }
            if (rules.count>0) {
                self.manager.onDemandRules = rules;
                [self.manager setOnDemandEnabled:YES];
            }
            self.manager.enabled = YES;
            
            [self.manager saveToPreferencesWithCompletionHandler:^(NSError *error) {
                if(error) {
                    NSLog(@"Save error: %@", error);
                    if ([self.delegate respondsToSelector:@selector(vpnSavedFail)]) {
                        [self.delegate vpnSavedFail];
                    }
                }else {
                    NSLog(@"Saved!");
                    if ([self.delegate respondsToSelector:@selector(vpnSavedSuccess)]) {
                        [self.delegate vpnSavedSuccess];
                    }
                }
            }];
        }
    }];
}
@end
