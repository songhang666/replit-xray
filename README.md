# replit-vmess

## 鸣谢

- [Project X](https://github.com/XTLS/Xray-core)
- [wy580477](https://github.com/wy580477/replit-trojan)

## 概述

本项目用于在 Replit 免费服务上部署 Vmess + Vless + Trojan + Shadowsocks Websocket 协议，支持 WS-0RTT 降低延迟。

## 注意

 **请勿滥用，账号封禁风险自负。网络流量每月有100GB软上限。**
 
 **旧款安卓设备证书得不到更新，如无法连接，可尝试打开跳过证书验证**

## 部署

点击网页上方 Run，稍等片刻即部署完成，右侧console窗口会自动输出分享链接和二维码，可以使用v2rayn/v2rayng客户端扫码。

### 手动设置部署

点击左侧Secrets，在右侧选项卡设置 uuid（Vmess / Vless UUID、Trojan / Shadowsocks 密码）变量。

然后点击网页上方 Run，稍等片刻即部署完成。

手动客户端设置示例，右侧 Webview 预览选项卡地址栏内为服务器域名：

![image](https://user-images.githubusercontent.com/98247050/205805711-75a6ddcf-20c6-4e2c-a90a-05dc979ade45.png)

如需设置自定义域名，点击 Webview 预览选项卡的地址栏右侧铅笔图标，即可进入向导。
