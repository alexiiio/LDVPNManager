# LDVPNManager

效果如图：

![vpndemonstration](https://raw.githubusercontent.com/alexiiio/LD-Notes/master/pics/vpndemonstration.gif)


iOS系统原生支持的VPN协议：
- IKEv2
- IPSec
- L2TP
- ~~PPTP~~ （iOS10以后已经不再支持。）
以上均可以在手机 设置->VPN 里添加。

可以通过程序自动添加的只有IKEV2和IPSec协议，[L2TP不可以](https://forums.developer.apple.com/thread/29909)。

iOS VPN功能在`<NetworkExtension/NetworkExtension.h>`下，最低支持iOS8。使用前需要先在项目中打开Personal VPN开关：

![openPersonVPNSwitch](https://raw.githubusercontent.com/alexiiio/LD-Notes/master/pics/openPersonVPNSwitch.png)

VPN服务器需要自行搭建，把相关参数替换成自己的就可以使用了。VPN服务器端可以使用 `strongSwan`搭建。
```
// VPN配置信息
static NSString *VPNServerAddress = @"xx.xxx.xxx.xxx";  // VPN服务器地址
static NSString *VPNUserName = @"vpnuser"; // 用户名
static NSString *VPNPassWord = @"vpnpassword"; // 密码
static NSString *VPNSharedSecret = @"vpnsharesecret"; // 共享秘钥
static NSString *VPNLocalizedDescription = @"🎄❄️圣诞快乐🎅🍬"; // VPN的名称，会显示在设置里
```
需要先添加VPN配置，这时会申请用户授权，在配置完成时再开启VPN。
```
/**
配置IPSec协议的VPN
*/
-(void)setUpIPSec;
/**
开启VPN连接，需要先配置
*/
-(void)startVPNConnect;
```

具体请看demo。
