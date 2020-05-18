# OrangeFilter SDK接入ThunderBolt SDK

## 概览
### ThunderBolt_SDK&OrangeFilter_SDK简介
> ThunderBolt SDK:提供各种客户端音视频SDK，具有可以灵活搭配的API组合，通过SDK连接全球部署的实时通信网络，为开发者提供质量稳定可靠的实时音视频通信服务。<br>
OrangeFilter SDK:是一套以内容创作为核心，设计数据驱动的跨平台视频特效及 AR 互动娱乐解决方案， 包含各种视频美颜，动态滤镜，2D，3D 图形特效等功能，核心代码采用 C/C++ 编写的, 采用 Lua 脚本来扩展功能。

* [一.OrangeFilter接入ThunderBolt步骤](#一orangefilter接入thunderbolt步骤)
* [二.OrangeFilter_Android_API](#二orangefilter_android_api)
* [三.OF_SDK融合ThunderBolt_SDK数据处理](#三of_sdk融合thunderbolt_sdk数据处理)
* [四.OrangeFilter特效资源自定义](#四orangefilter特效资源自定义)
* [五.业务接入美颜特效流程](#五业务接入美颜特效流程)

-------------------------------------------------

## 一.OrangeFilter接入ThunderBolt步骤
## 获取用户鉴权及说明
OF SDK暂时无官网申请，申请需要提供项目App Id（android:applicationId/ios:bundle Id）通过技术支持同学申请响应的of sdk鉴权序列号（后期of sdk特效包也会提供鉴权，无鉴权特效包可能无法加载），审核通过后会有一串sn号。
> **注意** 
> - 详细参照[../mouselive-android/effect]模块。
> - 授权类型，现在分这几个类型，可以授权人脸检测、背景分割、手势检测，可以指定开通指定几个，也可以全开通。
> - 美颜，滤镜和人脸没有关系，贴纸、整形和人脸有关。
> - 鉴权分为：sdk鉴权和特效包鉴权（sdk鉴权决定of是否可用，特效包鉴权决定是否特效能加载）。
> - 针对特效包，对外客户暂时需要通过技术支持同学向内部提需求跟进，会以zip包的形式提供给客户。

## 鉴权逻辑
> **注意**
应用启动时初始化，示例实现代码：
```java
// check license
 final String ofSerialNumber = getResources().getString(R.string.orangefilter_serial_number);
final String ofLicenseName = "of_offline_license.license";
String ofLicensePath = getFilesDir().getPath() + "/" + ofLicenseName;
int ret = OrangeFilter.checkSerialNumber(MainActivity.this, ofSerialNumber, ofLicensePath);
// 检查通过后返回 OF_Result_Success 说明授权成功
if (ret != OrangeFilter.OF_Result_Success) {
    Log.e(TAG, "OrangeFilter license invalid. ret = [" + ret + "]");
}
```

## 引入 OrangeFilter 库
### 1).添加库依赖

在 app module 的 build.gradle 文件中加入库依赖：
```java
dependencies {
    implementation fileTree(dir: 'libs', include: ['*.aar'])
}
```

> **注意：**
>
> - 目前美颜库已aar方式导入。


### 2).声明 OpenGL ES 功能需求
在 AndroidManifest.xml 中加入响应权限:
```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.INTERNET"/>

<uses-feature android:glEsVersion="0x00020000" android:required="true" />
```
### 3).初始化人脸模型数据
#### 将示例代码中../src/main/assets/models/venus_models拷贝到项目工程的assets目录下
> **注意**
> <br> 拷贝后assets的venus_models目录分为人脸模型数据（face）、手势数据（gesture）和分割数据（segment）

#### 初始化加载人脸模型数据
> 初始化，将数据从assets目录拷贝到当前项目文件目录下
```java
        // extract assets
final String venusModelPath = getFilesDir().getPath() + "/orangefilter/models/venus_models";
File modelDir = new File(venusModelPath);
if (!(modelDir.isDirectory() && modelDir.exists())) {
            new File(venusModelPath + "/face").mkdirs();
    OrangeFilter.extractAssetsDir(getAssets(),"models/venus_models/face",
                getFilesDir().getPath() + "/orangefilter/models/venus_models/face"
            );

    new File(venusModelPath + "/segment").mkdirs();
    OrangeFilter.extractAssetsDir(getAssets(), "models/venus_models/segment",
                getFilesDir().getPath() + "/orangefilter/models/venus_models/segment"
            );
}
```

## 二.OrangeFilter_Android_API

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

## 三.OF_SDK融合ThunderBolt_SDK数据处理

> IGPUProcess是交由业务可自行实现业务如美颜等纹理操作的对外回调接口,sdk就会在视频生命周期中调用对应3个接口,具体实现详见泛娱乐Demo中effect module[mouselive-android/effect/com.sclouds.effect.EffectOrangeFilterProcess]类，接口意义详见下面:
### 1. 实现IGPUProcess接口

```java
public interface IGPUProcess {

    /**
     * GL线程启动，初始化
     * @param textureTarget 纹理类型, (GL_TEXTURE_EXTERNAL_OES/GL_TEXTURE_2D）
     * @param outputWidth 纹理宽
     * @param outputHeight 纹理高
     */
    void onInit(int textureTarget, int outputWidth, int outputHeight);

    /**
     * 每一帧渲染处理
     * @param textureId 纹理ID
     * @param textureBuffer 纹理坐标
     */
    void onDraw(final int textureId, final FloatBuffer textureBuffer);

    /**
     * GL线程结束，销毁特效资源
     */
    void onDestroy();

    /**
     * 通知纹理大小更新
     * @param width
     * @param height
     */
    void onOutputSizeChanged(final int width, final int height);
}


```
### 2. 注册美颜实例到sdk(registerVideoCaptureTextureObserver)
> 在startPreviewVideo之后调用registerVideoCaptureTextureObserver注册第一步实现IGPUProcess接口类的实例。IGPUProcess实现实例设置到sdk，sdk就会在视频生命周期中调用对应3个接口。

```java
/**
 * 注册监听采集纹理数据，用于美颜等处理等
 * {@link IGPUProcess} 接口对象实例；如果传入 null，则取消注册
 *
 * @param observer 用于设置获取处理每一帧video渲染纹理的实例
 * @return 0:成功, 其它错误参见{@link ThunderRtcConstant.ThunderRet}
 */
public int registerVideoCaptureTextureObserver(IGPUProcess observer);
```

> **注意：**
>
> - 由于对外的of sdk需要传入YUV原始数据，因此在IGPUProcess#onDraw方法里返回的是纹理数据不支持直接传入of里，需要实现IVideoCaptureObserver接口。
> - 建议在startPreviewVideo之后调用registerVideoCaptureTextureObserver注册。
> - 该接口在正在推流情况下，开关预览情况下，建议无须重复调用registerVideoCaptureTextureObserver。
> - OrangeFilter(简称OF)的实例需要在视频openGL渲染线程中创建和销毁；即IGPUProcess#onInit和IGPUProcess#onDestroy中创建销毁。
> - 对OF的操作也需要抛到openGl线程中，不能在业务的线程直接调用(参照x接口用法)。

### 3. 实现IVideoCaptureObserver接口

监听采集后视频YUV(NV21)数据 (registerVideoCaptureFrameObserver)。<br>
IVideoCaptureObserver是交由业务可自行获取camera采集图像进行操作的对外回调接口。

#### IVideoCaptureObserver是交由业务可自行获取camera采集图像进行操作的对外回调接口，接口详见如下：

```java
public interface IVideoCaptureObserver {

    /*
     * 负责回调camera采集的原始YUV(NV21)给客户
     * @param w 视频数据宽
     * @param h 视频数据高
     * @param data  视频NV21数据
     * @param dateLen 视频数据长度
     * */
    void onCaptureVideoFrame(int width, int height, byte[] data, int length);

}
```

#### 注册摄像头采集数据观测器对象

```java
/**
 * 注册摄像头采集数据观测器对象
 *
 * @param observer 对象实例, 如果observer等于NULL, 则取消注册，用于设置分别获取video camera yuv采集和video渲染数据的实例
 * @return 0:成功, 其它错误参见{@link ThunderRtcConstant.ThunderRet}
 */

public int registerVideoCaptureFrameObserver(IVideoCaptureObserver observer)
```
- 说明：
注册摄像头采集数据观测器对象到sdk，sdk会通过该接口返回camera图像数据；

## 四.OrangeFilter特效资源自定义

> - **注意**
> 目前需要提需求到技术支持同学这边，然后会根据特效需求安排设计同学跟进。最终会给出导出的特效zip包。

### OrangeFilter特效接口下发（业务自定义）
> - **注意**
 目前demo协议为后台下发，分为美颜，滤镜，表情，手势相关协议。
 业务可以参照也可以自定义，详见[mouselive-android/effect/src/main/java/com/sclouds/effect/beauty_effect.json]协议文件。

----------------------------------------------------------------------

## 五.业务接入美颜特效流程

### 1.module引入
> - 1、在build.gradle文件引入：implementation project(':effect')
> - 2、在 AndroidManifest.xml 中加入权限：<uses-feature android:glEsVersion="0x00020000" android:required="true" />

### 2.init

初始化SDK。

```java
    /**
    * 设置美颜特效包路径
    * @param defBeautyPath 上下文
    * @param serialNumber 鉴权串
    */
    EffectManager.getIns().init(Context context, String serialNumber);
```

#### 参数[]

| 参数 | 类型 | 描述 |
| :--- | :--- | :--- |
| context | Context | 上下文 |
| serialNumber | String | 鉴权串 |

--------------------------

### 3.setDefaultBeautyEffect
在进入直播间之前将特效数据请求下来，可以考虑先把一些特效包下载下来（当前是先把美颜和滤镜的优先下载了），在请求到特效数据后，预先将下载好美颜特效包路径初始化到effect SDK，调用方法：
> - **注意:**
> - 传递的参数path是特效包下载后的文件保存路径，of SDK会通过这个路径去设置
> - 要直播之前调用，否则默认美颜开启不了

```java
    /**
    * 设置美颜特效包路径
    * @ defBeautyPath 美颜特效包下载后的文件保存路径
    */
   EffectManager.getIns().setDefaultBeautyEffect(String defBeautyPath);
```

#### 参数[]

| 参数 | 类型 | 描述 |
| :--- | :--- | :--- |
| defBeautyPath | String | 美颜特效包下载后的文件保存路径 |

--------------------------

### 4.setBeautyEffectEnable

打开/关闭美颜

> - **注意:**
> - 要确保setDefaultBeautyEffect之后，否则没有美颜特效包。

```java
    /**
    * 开关美颜
    * @param enable true打开美颜  false关闭美颜
    */
   EffectManager.getIns().setBeautyEffectEnable(boolean enable);
```

#### 参数[]

| 参数 | 类型 | 描述 |
| :--- | :--- | :--- |
| enable | boolean | 开关美颜，true打开美颜  false关闭美颜 |

--------------------------

### 5.isBeautyReady

是否开启美颜。

```java
    /**
    * 是否开启美颜
    * 如果美颜没有开启，是无法取到最大值、最小值和当前值的，一定要确保开启了，再调用获取的方法。
    * @return true美颜已经打开  false美颜已经关闭
    */
   EffectManager.getIns().isBeautyReady();
```

### 6.getBeautyOption

获取当前类型下美颜的设置参数。包括最大值，最小值，设置值，百分比。

```java
    /**
    * 获取当前类型下美颜的设置参数
    * @param optionType 美颜整形类型下标
    * @param optionName 美颜整形类型下标
    * @return 美颜的设置参数 BeautyOption
    */
   EffectManager.getIns().getBeautyOption(int optionType, String optionName);
```

#### 参数[]

| 参数 | 类型 | 描述 |
| :--- | :--- | :--- |
| optionType | int | 详见[BeautyHelper#（FILTER_INDEX_WHITE，FILTER_INDEX_BEAUTY，FILTER_INDEX_FACELIFTING）]，后台下发 |
| optionName | String | 详见[BeautyHelper#BEAUTY_OPTION_NAMES]，后台下发 |

--------------------------

### 7.setBeautyOptionValue
调整美颜整形程度


> - **注意:**
> - 要确保setDefaultBeautyEffect之后，否则没有美颜特效包。

```java
    /**
    * @param optionType 详见[BeautyHelper#（FILTER_INDEX_WHITE，FILTER_INDEX_BEAUTY，FILTER_INDEX_FACELIFTING）]
    * @param optionName 详见[BeautyHelper#BEAUTY_OPTION_NAMES]
    * @param value 设置的值，这个值须在对应范围以内，不同的美颜整形的范围是不同的，可能是【0～100】、【-50～50】。。。可以通过getBeautyOption获取得到
    */
    EffectManager.getIns().setBeautyOptionValue(int optionType, String optionName, int value);
```

#### 参数[]

| 参数 | 类型 | 描述 |
| :--- | :--- | :--- |
| optionType | int | 详见[BeautyHelper#（FILTER_INDEX_WHITE，FILTER_INDEX_BEAUTY，FILTER_INDEX_FACELIFTING）]，后台下发 |
| optionName | String | 详见[BeautyHelper#BEAUTY_OPTION_NAMES]，后台下发 |
| value | int | 设置的值，这个值须在对应范围以内，不同的美颜整形的范围是不同的，可能是【0～100】、【-50～50】。。。可以通过getBeautyOption获取得到 |

--------------------------

### 8.setEffectWithType

设置滤镜、表情、手势(点赞、单手比芯、双手比芯、666、手掌、比V、OK)。详见[EffectConst.Effect](#11.EffectConst.Effect)

```java
    /**
    * @param type 传EffectConst.Effect
    * @param effectPath 特效包下载保存的路径，如果path=""，则是清空状态。
    */
     EffectManager.getIns().setEffectWithType(String type, String effectPath);
```

#### 参数[]

| 参数 | 类型 | 描述 |
| :--- | :--- | :--- |
| type | String | 特效类型，详见[EffectConst.Effect](#11.EffectConst.Effect) |
| effectPath | String | 特效包下载保存的路径，如果path=""，则是清空状态。 |

--------------------------

### 9.setFilterIntensity

设置滤镜程度。

```java
    /**
    * @param value 设置滤镜程度。【0-100】
    */
     EffectManager.getIns().setFilterIntensity(int value);
```

#### 参数[]

| 参数 | 类型 | 描述 |
| :--- | :--- | :--- |
| value | int | 滤镜程度值。取值范围【0-100】 |

--------------------------

### 10.closeAllGestureEffect

关闭所有设置生效的手势。

```java
    /**
    * 关闭所有手势
    */
     EffectManager.getIns().closeAllGestureEffect();  
```

### 11.EffectConst.Effect

```java
interface Effect {
        /**
         * 美颜
         */
        String EFFECT_BEAUTY = "beauty";
        /**
         * 滤镜
         */
        String EFFECT_FILTER = "filter";
        /**
         * 贴纸
         */
        String EFFECT_STICKER = "sticker";
        /**
         * 一个手势
         */
        String EFFECT_GESTURE = "gesture";
        /**
         * 一组手势
         */
        String EFFECT_GESTURES = "gestures";
    }

    /**
     * 手势特效子类型：点赞，单手比心，双手比心，666，手掌，比V，OK
     */
    interface GestureEffectType {
        /**
         * 点赞
         */
        String GESTURE_GOOD = "gesture_thumbsup";
        /**
         * 单手比心
         */
        String GESTURE_SINGLE_LOVE = "gesture_onehandheart";
        /**
         * 双手比心
         */
        String GESTURE_DOUBLE_LOVE = "gesture_twohandheart";
        /**
         * 666
         */
        String GESTURE_SIX = "gesture_666";
        /**
         * 手掌
         */
        String GESTURE_HAND = "gesture_palm";
        /**
         * 比V
         */
        String GESTURE_V = "gesture_yeah";
        /**
         * OK
         */
        String GESTURE_OK = "gesture_ok";
    }
```