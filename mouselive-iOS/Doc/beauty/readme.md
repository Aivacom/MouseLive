# OrangeFilter SDK接入ThunderBolt SDK

## 概览
### [一.ThunderBolt_SDK&OrangeFilter_SDK简介](#一thunderbolt_sdk&orangefilter_sdk简介)
### [二.OrangeFilter接入ThunderBolt步骤](#二orangefilter接入thunderbolt步骤)
### [三.OrangeFilter_iOS_API](#三orangefilter_ios_api)
### [四.OF_SDK融合ThunderBolt_SDK数据处理](#四of_sdk融合thunderbolt_sdk数据处理)
### [五.OrangeFilter特效资源自定义](#五orangefilter特效资源自定义)
### [六.业务接入美颜特效流程](#六业务接入美颜特效流程)

-------------------------------------------------

## 一.ThunderBolt_SDK&OrangeFilter_SDK简介
ThunderBolt SDK:尚云音视频SDK<br>
OrangeFilter SDK:是一套以内容创作为核心，设计数据驱动的跨平台视频特效及 AR 互动娱乐解决方案， 包含各种视频美颜，动态滤镜，2D，3D 图形特效等功能，核心代码采用 C/C++ 编写的, 采用 Lua 脚本来扩展功能。

## 二.OrangeFilter接入ThunderBolt步骤
## 获取用户鉴权及说明
OF SDK暂时无官网申请，申请需要提供项目App Id（ios:bundle Id）通过技术支持同学申请响应的of sdk鉴权序列号（后期of sdk特效包也会提供鉴权，无鉴权特效包可能无法加载），审核通过后会有一串sn号。
> **注意**
>
> - 授权类型，现在分这几个类型，可以授权人脸检测、背景分割、手势检测，可以指定开通指定几个，也可以全开通。
> - 美颜，滤镜和人脸没有关系，贴纸、整形和人脸有关。
> - 鉴权分为：sdk鉴权和特效包鉴权（sdk鉴权决定of是否可用，特效包鉴权决定是否特效能加载）。
> - 针对特效包，对外客户暂时需要通过技术支持同学向内部提需求跟进，会以zip包的形式提供给客户。

## 鉴权逻辑
> **注意**
应用启动时初始化，示例实现代码：
```Objective-C
// check license
NSString *ofSerialNumber = @"";
NSString *ofLicenseName = @"of_offline_license.license";
NSArray *documentsPathArr = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
NSString *documentPath = [documentsPathArr lastObject];
NSString *ofLicensePath = [NSString stringWithFormat:@"%@/%@", documentPath, ofLicenseName];
OF_Result checkResult = OF_CheckSerialNumber([ofSerialNumber UTF8String], [ofLicensePath UTF8String]);
if (OF_Result_Success != checkResult) {
    NSLog(@"check sn failed");
}
```

## 引入 OrangeFilter 库
### 1）将示例代码中 ../MouseLive/Classes/Effects/of_effect.framework 库直接拖入到工程目录下
> **注意：**
>
> - Added folders : Create groups
### 2）初始化人脸模型数据
#### 将示例代码中 ../MouseLive/Classes/Effects/venus_models 库直接拖入到工程目录下
> **注意**
>
> - Added folders : Create folder references

#### 初始化加载人脸模型数据
```Objective-C
NSString *modelPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"venus_models"];
OF_Result result = OF_CreateContext(&_ofContext, [modelPath UTF8String]);  
```

## 三.OrangeFilter_iOS_API

> 目前对外用到的API接口如下：

### OrangeFilter:createContext

```java
int createContext(String VenusModelPath);
```

创建 OrangeFilter Context。

#### 参数[]

| 参数 | 类型 | 描述 |
| :--- | :--- | :--- |
| VenusModelPath | String | venus_models数据模型路径 见[初始化加载人脸模型数据](#初始化加载人脸模型数据) |

--------------------------

### OrangeFilter:prepareFrameData

```java
int prepareFrameData(int context, int witdh, int height, OrangeFilter.OF_FrameData frameData);
```

渲染前预处理帧数据，包含人脸姿态（空间位置、朝向）计算。
> **注意：**
>
> - 返回值，成功时返回 OF_Result_Success。

#### 参数[]

| 参数 | 类型 | 描述 |
| :--- | :--- | :--- |
| context | String | Context id |
| witdh | String | 帧宽 |
| height | String | 帧高 |
| frameData | String | Context id |
| context | String | 帧数据对象 |

--------------------------

### OrangeFilter:applyFrame

```java
int applyFrame(int context, int effect, OrangeFilter.OF_Texture[] inputs, OrangeFilter.OF_Texture[] outputs);
```

渲染帧特效。

> **注意：**
>
> - 返回值，成功时返回 OF_Result_Success。


#### 参数[]

| 参数 | 类型 | 描述 |
| :--- | :--- | :--- |
| context | int | Context id |
| effect | int | Effect id |
| inputs | OrangeFilter.OF_Texture[] | 输入图像纹理数组，来源于摄像头采集视频图像或静态图片，通常为 1 个 |
| outputs | OrangeFilter.OF_Texture[] | 输出图像纹理数组，用于渲染到屏幕或编码到视频流，通常为 1 个 |

--------------------------

### OrangeFilter:setFilterParamData

```java
int setFilterParamData(int context, int filter, String paramName, OrangeFilter.OF_Param param);
```

设置 Filter 参数数据。

> **注意：**
>
> - 返回值，成功时返回 OF_Result_Success。


#### 参数[]

| 参数 | 类型 | 描述 |
| :--- | :--- | :--- |
| context | int | Context id |
| filter | int | Filter id |
| paramName | String | 参数名称 |
| param | OrangeFilter.OF_Param | 输出图像纹理数组，用于渲染到屏幕或编码到视频流，通常为 1 个 |

--------------------------

### OrangeFilter:destroyEffect

```java
int destroyEffect(int context, int effect);
```

销毁 Effect。

> **注意：**
>
> - 返回值：成功时返回 OF_Result_Success。


#### 参数[]

| 参数 | 类型 | 描述 |
| :--- | :--- | :--- |
| context | int | Context id |
| effect | int | Effect id |

--------------------------

### OrangeFilter:destroyContext

```java
int destroyContext(int context);
```

销毁 OrangeFilter Context。

> **注意：**
>
> - 返回值：成功时返回 OF_Result_Success。


#### 参数[]

| 参数 | 类型 | 描述 |
| :--- | :--- | :--- |
| context | int | 要销毁的 Context id |

--------------------------

## 四.OF_SDK融合ThunderBolt_SDK数据处理

> ThunderVideoCaptureFrameObserver是交由业务可自行实现业务如美颜等纹理操作的对外回调接口,sdk就会在视频生命周期中调用对应3个接口,具体实现详见泛娱乐Demo中MouseLive/Classes/Live/Controller/BaseLiveViewController类，接口意义详见下面:
### 1. 实现ThunderVideoCaptureFrameObserver接口

```Objective-C
/**
 @protocol
 @brief 视频帧预处理代理接口
 */
@protocol ThunderVideoCaptureFrameObserver <NSObject>

@required
/**
 @brief 向SDK申明使用哪种格式的数据，将会根据设置的格式调用下述的两个方法
 @return 使用哪种格式的数据进行回调
 */
- (ThunderVideoCaptureFrameDataType)needThunderVideoCaptureFrameDataType;

/**
 @brief 从采集接受一帧数据处理并返回处理后数据
 @param [OUT] pixelBuf  当前帧buf指针
 @return 返回经过处理之后的pixelbuff，如不处理数据，可将参数中的pixelbuffer直接返回
 */
- (CVPixelBufferRef _Nullable)onVideoCaptureFrame:(EAGLContext *_Nonnull)glContext
                                      PixelBuffer:(CVPixelBufferRef _Nonnull)pixelBuf;

/**
 @brief 返回src texture 和 dst texture
 @param [OUT] context EAGLContext
 @param [OUT] pixelBuffer 原始图像pixelBuffer
 @param [OUT] srcTextureID 原始纹理id
 @param [OUT] dstTextureID 目标纹理id
 @param [OUT] textureFormat texture 的格式
 @param [OUT] textureTarget texture target
 @param [OUT] width 纹理宽度
 @param [OUT] height 纹理高度
 @return bool
 */
- (BOOL)onVideoCaptureFrame:(EAGLContext *_Nonnull)context
                PixelBuffer:(CVPixelBufferRef _Nonnull)pixelBuffer
            SourceTextureID:(unsigned int)srcTextureID
       DestinationTextureID:(unsigned int)dstTextureID
              TextureFormat:(int)textureFormat
              TextureTarget:(int)textureTarget
               TextureWidth:(int)width
              TextureHeight:(int)height;

@end
```

### 2. 注册美颜实例到sdk(registerVideoCaptureFrameObserver)
> 在startPreviewVideo之后调用registerVideoCaptureFrameObserver注册第一步实现ThunderVideoCaptureFrameObserver接口类的实例。ThunderVideoCaptureFrameObserver实现实例设置到sdk，sdk就会在视频生命周期中调用对应3个接口。

```Objective-C
/**
 @brief 设置本地视频预处理回调接口
 @param [IN] delegate 本地视频帧预处理接口，可用于自定义的美颜等处理。
 */
-(int)registerVideoCaptureFrameObserver:(nullable id<ThunderVideoCaptureFrameObserver>)delegate;
```

## 五.OrangeFilter特效资源自定义

> - **注意**
> 目前需要提需求到技术支持同学这边，然后会根据特效需求安排设计同学跟进。最终会给出导出的特效zip包。

### OrangeFilter特效接口下发（业务自定义）
> - **注意**
 目前demo协议为后台下发，分为美颜，滤镜，表情，手势相关协议。
 业务可以参照也可以自定义，详见MouseLive/Classes/Effects/SYEffectProtocol协议文件。

----------------------------------------------------------------------

## 六.业务接入美颜特效流程

### 1.module引入
> - 1、将库和模型数据引入到工程
> - 2、将 MouseLive/Classes/Effects/Utils和协议SYEffectProtocol引入到工程

### 2.checkSDKSerailNumber

校验并初始化SDK。

```Objective-C
/// 应用启动时请校验 SDK 序列号，否则不生效
/// @param serialNumber 序列号 SN
- (void)checkSDKSerailNumber:(NSString *)serialNumber;
```

### 3.renderPixelBufferRef
开始渲染
```Objective-C
/// 渲染方法
/// @param pixelBufferRef 源CVPixelBufferRef
/// @param context 上下文EAGLContext
- (CVPixelBufferRef)renderPixelBufferRef:(CVPixelBufferRef)pixelBufferRef
                                 context:(EAGLContext *)context;

/// 渲染方法
/// @param pixelBuffer 源pixelBuffer
/// @param context 上下文EAGLContext
/// @param srcTextureID 源纹理
/// @param dstTextureID 目标纹理
/// @param textureFormat 纹理格式
/// @param textureTarget 纹理target
/// @param width width description
/// @param height height description
- (void)renderPixelBufferRef:(CVPixelBufferRef)pixelBuffer
                     context:(EAGLContext *)context
             sourceTextureID:(unsigned int)srcTextureID
        destinationTextureID:(unsigned int)dstTextureID
               textureFormat:(int)textureFormat
               textureTarget:(int)textureTarget
                textureWidth:(int)width
               textureHeight:(int)height;
```

### 4.setDefaultBeautyEffectPath
在进入直播间之前将特效数据请求下来，可以考虑先把一些特效包下载下来（当前是先把美颜和滤镜的优先下载了）
> - **注意:**
> - 如果不需要开启默认美颜，可以不调用
> - 传递的参数path是特效包下载后的文件保存路径，of SDK会通过这个路径去设置
> - 要保证路径下有特效包，否则默认美颜开启不了

```Objective-C
/// 设置默认美颜路径
/// @param effectPath effectPath description
- (void)setDefaultBeautyEffectPath:(NSString *)effectPath;
```

### 5.loadBeautyEffectWithEffectPath

加载美颜

> - **注意:**
> - 要确保美颜特效包存在，否则美颜不生效。

```Objective-C
/// 加载美颜特效
/// @param effectPath 特效地址
- (void)loadBeautyEffectWithEffectPath:(NSString *)effectPath;
```

### 6.cancelBeautyEffect
取消美颜

```Objective-C
/// 取消美颜特效
- (void)cancelBeautyEffect;
```

### 7.getBeautyOptionMinValue
获取当前类型下美颜的设置参数的最小值

```Objective-C
/// 获取特效最小值
/// @param filterIndex 特效在特效包中的 index
/// @param filterName 特效在特效包中的 name
- (int)getBeautyOptionMinValue:(int)filterIndex filterName:(NSString *)filterName;
```

### 8.getBeautyOptionMaxValue
获取当前类型下美颜的设置参数的最大值

```Objective-C
/// 获取特效最大值
/// @param filterIndex 特效在特效包中的 index
/// @param filterName 特效在特效包中的 name
- (int)getBeautyOptionMaxValue:(int)filterIndex filterName:(NSString *)filterName;
```

### 9.getBeautyOptionValue
获取当前类型下美颜的设置参数的默认值

```Objective-C
/// 获取特效当前值
/// @param filterIndex 特效在特效包中的 index
/// @param filterName 特效在特效包中的 name
- (int)getBeautyOptionValue:(int)filterIndex filterName:(NSString *)filterName;
```

### 10.setBeautyOptionValue
调整美颜整形程度

> - **注意:**
> - 要确保已经加载美颜特效包，否则不生效。

```Objective-C
/// 设置特效强度值
/// @param filterIndex 特效在特效包中的 index
/// @param filterName 特效在特效包中的 name
/// @param value value description
- (void)setBeautyOptionValue:(int)filterIndex filterName:(NSString *)filterName value:(int)value;
```

### 11.loadFilterEffectWithEffectPath
加载滤镜

> - **注意:**
> - 要确保滤镜特效包存在，否则美颜不生效。

```Objective-C
/// 加载滤镜特效
/// @param effectPath 特效地址
- (void)loadFilterEffectWithEffectPath:(NSString *)effectPath;
```

### 12.cancelFilterEffect
取消滤镜

```Objective-C
/// 取消滤镜特效
- (void)cancelFilterEffect;
```

### 13.getFilterIntensity
获取当前类型下滤镜的设置参数的默认值

```Objective-C
/// 获取当前滤镜强度
- (int)getFilterIntensity;
```

### 14.setFilterIntensity
设置当前类型下滤镜的参数值

```Objective-C
/// 设置滤镜强度
/// @param value value description
- (void)setFilterIntensity:(int)value;
```

### 15.loadStickerEffectWithEffectPath
加载贴纸

> - **注意:**
> - 要确保贴纸特效包存在，否则美颜不生效。

```Objective-C
/// 加载贴纸特效
/// @param effectPath 特效地址
- (void)loadStickerEffectWithEffectPath:(NSString *)effectPath;
```

### 16.cancelStickerEffect
取消贴纸

```Objective-C
/// 取消贴纸特效
- (void)cancelStickerEffect;
```

### 17.loadGestureEffectWithEffectPath
加载手势

> - **注意:**
> - 要确保手势特效包存在，否则美颜不生效。

```Objective-C
/// 加载手势特效
/// @param effectPath 特效地址
- (void)loadGestureEffectWithEffectPath:(NSString *)effectPath;
```

### 18.cancelGestureEffect
取消手势

```Objective-C
/// 取消手势特效
- (void)cancelGestureEffect;
```

### 19.destroyAllEffects

销毁所有设置生效的手势。

```Objective-C
/// 销毁所有特效（离开房间的时候调用，会释放所有资源）
- (void)destroyAllEffects;
```
