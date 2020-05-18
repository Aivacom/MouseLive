# MouseLive-iOS

鼠年，泛娱乐直播项目，iOS

# 产品概述
泛娱乐包含2大模块：直播模块和聊天室模块。
- 直播模块：可实现直播开播、魔法(美白+滤镜+手势+贴图)，多人在线观看、多人文字聊天、视频连麦、禁言等功能。
- 聊天室模块：可实现多人语音聊天、多人文字聊天、变声、抢麦、踢人等功能。

# 关键特性

# 工程介绍
此工程主要演示如何用Thunder和Hummer 2个SDK实现直播和聊天室功能。
- Thunder SDK：主要对音视频的控制。[在线文档](https://www.sunclouds.com/cloud/v2/developer/doc.htm?serviceId=102&typeCode=PRO_DES)
- Hummer SDK：主要是对房间类用户进出通知，以及房间类消息的传输。[在线文档](https://www.sunclouds.com/cloud/v2/developer/doc.htm?serviceId=105&typeCode=PRO_DES)
- 美颜 SDK：[接入文档](./Doc/beauty/readme.md)

# 申请

- 去[尚云平台](https://www.sunclouds.com/)注册账号，并创建自己的工程项目，获取到 AppID，并在 SYAppInfo.m 中替换申请的 AppID
- token 请在 SYToken.m 下修改
- 美颜根据工程 bundle id 申请 license + 鉴权字串，并在 SYAppInfo.m 中替换 kOFSDKSerialNumber
- 需求 CDN 推流，并在 SYAppInfo.m 中替换 kCDNRtmpPushUrl 和 kCDNRtmpPullUrl

# 集成
##### 1. 安装 CocoaPods。在 Terminal 里输入以下命令行：
```sh
brew install cocoapods
```
- 如果你已在系统中安装了 CocoaPods 和 Homebrew，可以跳过这一步。
- 如果 Terminal 显示 -bash: brew: command not found，则需要先安装 Homebrew，再输入该命令行。详见 [Homebrew 安装方法](https://brew.sh/index.html)。
##### 2.创建 Podfile 文件。
```sh
pod init
```
##### 3.添加ThunderBolt SDK 和Hummer SDK的引用
打开 Podfile 文本文件，修改文件为如下内容。注意 “YourApp” 是你的 Target 名称，需要添加source和sdk版本。

```python
# Uncomment the next line to define a global platform for your project
platform :ios, '9.0'

source 'https://github.com/CocoaPods/Specs.git'#添加项
source 'https://github.com/yyqapm/specs.git'#添加项
target 'YourApp' do
  # Uncomment the next line if you're using Swift or would like to use dynamic frameworks
  # use_frameworks!

  # Pods for YourApp
  pod 'Hummer/ChatRoom', '2.6.107'       #添加项，'2.6.107'是Hummer sdk版本号, 请根据具体导入的版本号进行修改
  pod 'thunder','2.7.0' #添加项，'2.7.0'是thunderbolt sdk版本号, 请根据具体导入的版本号进行修改

end
```

**4.相应SDK版本**

| SDK             | 版本    |
| :-------------- | :------ |
| thunder_version | 2.7.0   |
| hummer_version  | 2.6.107 |

# 开发
### 直播
- 视频功能-Thunder主要API

| API                                                          | 说明                                                         |
| :----------------------------------------------------------- | :----------------------------------------------------------- |
| [createEngine](https://www.sunclouds.com/cloud/v2/developer/doc.htm?serviceId=102&typeCode=API_DOC&title=iOS&version=2.7.0#createEngine) | 创建 ThunderEngine 实例并初始化 |
| [setArea](https://www.sunclouds.com/cloud/v2/developer/doc.htm?serviceId=102&typeCode=API_DOC&title=iOS&version=2.7.0#setArea) | 设置用户国家区域                                              |
| [setMediaMode](https://www.sunclouds.com/cloud/v2/developer/doc.htm?serviceId=102&typeCode=API_DOC&title=iOS&version=2.7.0#setMediaMode) | 配置-媒体模式                                                |
| [setRoomMode](https://www.sunclouds.com/cloud/v2/developer/doc.htm?serviceId=102&typeCode=API_DOC&title=iOS&version=2.7.0#setRoomMode) | 配置-房间模式                                                |
| [setAudioConfig](https://www.sunclouds.com/cloud/v2/developer/doc.htm?serviceId=102&typeCode=API_DOC&title=iOS&version=2.7.0#setAudioConfig) | 配置-音频模式                                                |
| [setAudioSourceType](https://www.sunclouds.com/cloud/v2/developer/doc.htm?serviceId=102&typeCode=API_DOC&title=iOS&version=2.7.0#setAudioSourceType) | 配置-音频开播模式                                            |
| [setVideoEncoderConfig](https://www.sunclouds.com/cloud/v2/developer/doc.htm?serviceId=102&typeCode=API_DOC&title=iOS&version=2.7.0#setVideoEncoderConfig) | 配置-视频开播参数                                            |
| [joinRoom](https://www.sunclouds.com/cloud/v2/developer/doc.htm?serviceId=102&typeCode=API_DOC&title=iOS&version=2.7.0#joinRoom) | 功能-加入房间，此接口是异步接口，需要监控ThunderEventHandler中[onJoinRoomSuccess](https://www.sunclouds.com/cloud/v2/developer/doc.htm?serviceId=102&typeCode=API_DOC&title=iOS&version=2.7.0#onJoinRoomSuccess)。 |
| [stopLocalAudioStream](https://www.sunclouds.com/cloud/v2/developer/doc.htm?serviceId=102&typeCode=API_DOC&title=iOS&version=2.7.0#stopLocalAudioStream) | 功能-音频推流开关（闭麦功能）                                |
| [startVideoPreview](https://www.sunclouds.com/cloud/v2/developer/doc.htm?serviceId=102&typeCode=API_DOC&title=iOS&version=2.7.0#startVideoPreview) | 功能-本地视频预览开关                                        |
| [stopLocalVideoStream](https://www.sunclouds.com/cloud/v2/developer/doc.htm?serviceId=102&typeCode=API_DOC&title=iOS&version=2.7.0#stopLocalVideoStream) | 功能-视频推流开关                                            |
| [setLocalVideoCanvas](https://www.sunclouds.com/cloud/v2/developer/doc.htm?serviceId=102&typeCode=API_DOC&title=iOS&version=2.7.0#setLocalVideoCanvas) | 功能-设置本地视图，设置此窗口，则可以看到我的视频画面        |
| [setRemoteVideoCanvas](https://www.sunclouds.com/cloud/v2/developer/doc.htm?serviceId=102&typeCode=API_DOC&title=iOS&version=2.7.0#setRemoteVideoCanvas) | 功能-设置远端视频的渲染视图，设置此窗口，则可以看到远端订阅的对应uid的流的画面 |
| [addSubscribe](https://www.sunclouds.com/cloud/v2/developer/doc.htm?serviceId=102&typeCode=API_DOC&title=iOS&version=2.7.0#addSubscribe) | 功能-跨房间订阅（2个主播PK功能）                             |
| [removeSubscribe](https://www.sunclouds.com/cloud/v2/developer/doc.htm?serviceId=102&typeCode=API_DOC&title=iOS&version=2.7.0#removeSubscribe) | 功能-取消跨房间订阅                                          |
| [switchFrontCamera](https://www.sunclouds.com/cloud/v2/developer/doc.htm?serviceId=102&typeCode=API_DOC&title=iOS&version=2.7.0#switchFrontCamera) | 功能-切到前/后置摄像头，需要在开启预览后[startVideoPreview](https://www.sunclouds.com/cloud/v2/developer/doc.htm?serviceId=102&typeCode=API_DOC&title=iOS&version=2.7.0#startVideoPreview)调用不调用该方法时引擎默认启动前置摄像头 |
| [setLocalVideoMirrorMode](https://www.sunclouds.com/cloud/v2/developer/doc.htm?serviceId=102&typeCode=API_DOC&title=iOS&version=2.7.0#setLocalVideoMirrorMode) | 功能-设置本地视频镜像模式，只对前置摄像头生效，后置摄像头不生效，后置摄像头固定预览推流都不镜像，前置摄像头默认预览镜像推流不镜像 |
| [setEnableInEarMonitor](https://www.sunclouds.com/cloud/v2/developer/doc.htm?serviceId=102&typeCode=API_DOC&title=iOS&version=2.7.0#setEnableInEarMonitor) | 功能-打开关闭耳返                                            |
| [setVoiceChanger](https://www.sunclouds.com/cloud/v2/developer/doc.htm?serviceId=102&typeCode=API_DOC&title=iOS&version=2.7.0#setVoiceChanger)| 功能-设置变声模式                                            |
| [leaveRoom](https://www.sunclouds.com/cloud/v2/developer/doc.htm?serviceId=102&typeCode=API_DOC&title=iOS&version=2.7.0#leaveRoom) | 功能-离开房间，此接口是异步接口，需要监控ThunderEventHandler中[onLeaveRoomWithStats](https://www.sunclouds.com/cloud/v2/developer/doc.htm?serviceId=102&typeCode=API_DOC&title=iOS&version=2.7.0#onLeaveRoomWithStats)。 |

### 聊天室
- 音频功能-Thunder主要API

| API                                                          | 说明                                                         |
| :----------------------------------------------------------- | :----------------------------------------------------------- |
| [createEngine](https://www.sunclouds.com/cloud/v2/developer/doc.htm?serviceId=102&typeCode=API_DOC&title=iOS&version=2.7.0#createEngine) | 初始化引擎 |
| [setArea](https://www.sunclouds.com/cloud/v2/developer/doc.htm?serviceId=102&typeCode=API_DOC&title=iOS&version=2.7.0#setArea) | 初始化-设置地区                                              |
| [setMediaMode](https://www.sunclouds.com/cloud/v2/developer/doc.htm?serviceId=102&typeCode=API_DOC&title=iOS&version=2.7.0#setMediaMode) | 配置-媒体模式                                                |
| [setRoomMode](https://www.sunclouds.com/cloud/v2/developer/doc.htm?serviceId=102&typeCode=API_DOC&title=iOS&version=2.7.0#setRoomMode) | 配置-房间模式                                                |
| [setAudioConfig](https://www.sunclouds.com/cloud/v2/developer/doc.htm?serviceId=102&typeCode=API_DOC&title=iOS&version=2.7.0#setAudioConfig) | 配置-音频模式                                                |
| [setAudioSourceType](https://www.sunclouds.com/cloud/v2/developer/doc.htm?serviceId=102&typeCode=API_DOC&title=iOS&version=2.7.0#setAudioSourceType) | 配置-音频开播模式                                            |
| [joinRoom](https://www.sunclouds.com/cloud/v2/developer/doc.htm?serviceId=102&typeCode=API_DOC&title=iOS&version=2.7.0#joinRoom) | 功能-加入房间，此接口是异步接口，需要监控ThunderEventHandler中[onJoinRoomSuccess](https://www.sunclouds.com/cloud/v2/developer/doc.htm?serviceId=102&typeCode=API_DOC&title=iOS&version=2.7.0#onJoinRoomSuccess)。 |
| [stopLocalAudioStream](https://www.sunclouds.com/cloud/v2/developer/doc.htm?serviceId=102&typeCode=API_DOC&title=iOS&version=2.7.0#stopLocalAudioStream) | 功能-音频推流开关（闭麦功能）                                |
| [setEnableInEarMonitor](https://www.sunclouds.com/cloud/v2/developer/doc.htm?serviceId=102&typeCode=API_DOC&title=iOS&version=2.7.0#setEnableInEarMonitor) | 功能-打开关闭耳返                                            |
| [setVoiceChanger](https://www.sunclouds.com/cloud/v2/developer/doc.htm?serviceId=102&typeCode=API_DOC&title=iOS&version=2.7.0#setVoiceChanger) | 功能-设置变声模式                                            |
| [leaveRoom](https://www.sunclouds.com/cloud/v2/developer/doc.htm?serviceId=102&typeCode=API_DOC&title=iOS&version=2.7.0#leaveRoom) | 功能-离开房间，此接口是异步接口，需要监控ThunderEventHandler中[onLeaveRoomWithStats](https://www.sunclouds.com/cloud/v2/developer/doc.htm?serviceId=102&typeCode=API_DOC&title=iOS&version=2.7.0#onLeaveRoomWithStats)。 |

- 音频功能-音乐文件播放API-ThunderAudioFilePlayer

| API                                                          | 说明                                                         |
| :----------------------------------------------------------- | :----------------------------------------------------------- |
| [createAudioFilePlayer](https://www.sunclouds.com/cloud/v2/developer/doc.htm?serviceId=102&typeCode=API_DOC&title=iOS&version=2.7.0#createAudioFilePlayer) | 创建文件播放 [ThunderAudioFilePlayer](https://www.sunclouds.com/cloud/v2/developer/doc.htm?serviceId=102&typeCode=API_DOC&title=iOS&version=2.7.0#ThunderAudioFilePlayer) 对象                                                       |
| [enablePublish](https://www.sunclouds.com/cloud/v2/developer/doc.htm?serviceId=102&typeCode=API_DOC&title=iOS&version=2.7.0#ThunderAudioFilePlayer)  | 配置-是否将当前播放的文件作为直播伴奏使用                    |
| [enableVolumeIndication](https://www.sunclouds.com/cloud/v2/developer/doc.htm?serviceId=102&typeCode=API_DOC&title=iOS&version=2.7.0#ThunderAudioFilePlayer) | 配置-打开文件播放音量回调                                    |
| [onAudioFilePlaying](https://www.sunclouds.com/cloud/v2/developer/doc.htm?serviceId=102&typeCode=API_DOC&title=iOS&version=2.7.0#ThunderAudioFilePlayer) | 配置-播放回调接口                                            |
| [open](https://www.sunclouds.com/cloud/v2/developer/doc.htm?serviceId=102&typeCode=API_DOC&title=iOS&version=2.7.0#ThunderAudioFilePlayer)  | 配置-打开需要播放的文件，支持文件格式：mp3、aac、wav。此接口是异步操作，onAudioFilePlaying，然后在ThunderAudioFilePlayer.IThunderAudioFilePlayerCallback中监控onAudioFilePlayError，当errorCode==0时，表示文件打开成功。 |
| [getTotalPlayTimeMS](https://www.sunclouds.com/cloud/v2/developer/doc.htm?serviceId=102&typeCode=API_DOC&title=iOS&version=2.7.0#ThunderAudioFilePlayer)  | 配置-获取文件的总播放时长，需要先open，并且onAudioFilePlayError回调成功打开之后才能获取到数据。 |
| [setLooping](https://www.sunclouds.com/cloud/v2/developer/doc.htm?serviceId=102&typeCode=API_DOC&title=iOS&version=2.7.0#ThunderAudioFilePlayer) | 配置-设置循环播放次数                                        |
| [play](https://www.sunclouds.com/cloud/v2/developer/doc.htm?serviceId=102&typeCode=API_DOC&title=iOS&version=2.7.0#ThunderAudioFilePlayer)  | 功能-开始播放                                                |
| [resume](https://www.sunclouds.com/cloud/v2/developer/doc.htm?serviceId=102&typeCode=API_DOC&title=iOS&version=2.7.0#ThunderAudioFilePlayer)| 功能-继续播放                                                |
| [pause](https://www.sunclouds.com/cloud/v2/developer/doc.htm?serviceId=102&typeCode=API_DOC&title=iOS&version=2.7.0#ThunderAudioFilePlayer) | 功能-暂停播放                                                |
| [stop](https://www.sunclouds.com/cloud/v2/developer/doc.htm?serviceId=102&typeCode=API_DOC&title=iOS&version=2.7.0#ThunderAudioFilePlayer) | 功能-停止播放                                                |
| [setPlayVolume](https://www.sunclouds.com/cloud/v2/developer/doc.htm?serviceId=102&typeCode=API_DOC&title=iOS&version=2.7.0#ThunderAudioFilePlayer)  | 功能-设置音量                                                |

# 常见问题
### Q：为什么看不到对方视频？
- 检查一下AppId是否正确。
- 检查一下对方startVideoPreview和stopLocalVideoStream是否设置，值是否正确。
- 检查一下自己setRemoteVideoCanvas是否设置，并且对方uid是否正确。
- 检查一下2边房间号，如果是跨房间订阅（不同房间号），需要设置addSubscribe，并且正确的设置对方uid。

### Q：为什么听不到对方声音？
- 检查一下AppId是否正确。
- 检查一下对方stopLocalAudioStream是否设置，参数是stop，值是否正确。
- 检查一下自己手机音量，是否是静音模式。
- 检查一下2边是否joinRoom成功，并且检查是否是同一个房间号。

### Q：为什么我这边播放音乐文件，对方听不到？
- 检查一下AppId是否正确。
- 检查一下自己stopLocalAudioStream是否设置，参数是stop，值是否正确。
- 检查一下对方手机音量，是否是静音模式。
- 检查一下2边是否joinRoom成功，并且检查是否是同一个房间号。
- 检查一下自己setAudioSourceType，是否设置成THUNDER_PUBLISH_MODE_MIX。
- 检查一下自己enablePublish，是否设置成true。

### Q：为什么我收不到ThunderAudioFilePlayer.IThunderAudioFilePlayerCallback回调
- 检查一下是否设置onAudioFilePlaying回掉。
- 检查一下是否设置enableVolumeIndication。

### Q：为什么joinRoom一直失败？
- 检查一下AppId是否正确。
- 检查一下joinRoom返回的错误码，然后对应代码中的ThunderRet，查看具体原因。

### Q：为什么播放音频文件循环播放？
- 检查一下在onAudioFilePlayError回调中设置setLooping:-1。

### Q：什么时候设置setMediaMode和setRoomMode？
- 要在joinRoom前设置。
