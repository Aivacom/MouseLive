# OrangeFilter SDK

OrangeFilter SDK是一套以内容创作为核心，设计数据驱动的跨平台视频特效及AR互动娱乐解决方案， 包含各种视频美颜、动态滤镜，2D/3D图形特效等功能，核心代码基于C/C++语言并采用 Lua 脚本来扩展功能。

* [1.获取用户鉴权及说明](#1.获取用户鉴权及说明)
* [2.配置项目](#2.配置项目)
* [3.OrangeFilter实现美颜效果](#3.OrangeFilter实现美颜效果)
* [4.Effect API](#4.Effect API)
* [5.OrangeFilter SDK API](#5.OrangeFilter SDK API)
* [6.自定义特效包资源](#6.自定义特效包资源)



## 1.获取用户鉴权及说明
联系聚联云技术支持，并提供项目AppID（android:applicationId/ios:bundle Id）以申请鉴权序列号，审核通过后将显示序列号。
> **注意** 
> - 用户鉴权详情请参考[../mouselive-android/effect]模块。
> - 授权类型包括人脸检测、背景分割、手势检测，可启用指定类型或全部启用。
> - 美颜、滤镜与人脸无关，贴纸、整形和人脸有关。
> - 鉴权分为SDK鉴权（决定OrangeFilter SDK是否可用）和特效包鉴权（决定特效能是否能被加载）。
> - 如需获取特效包，请联系聚联云技术支持。

## 2.配置项目

### 1).添加库依赖

在 app module 的 build.gradle 文件中加入库依赖：

```java
dependencies {
    implementation fileTree(dir: 'libs', include: ['*.aar'])
}
```

**注意：**目前美颜库已aar方式导入。


### 2).声明 OpenGL ES 功能需求

在 AndroidManifest.xml 中加入响应权限:

```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.INTERNET"/>

<uses-feature android:glEsVersion="0x00020000" android:required="true" />
```

### 3).初始化并检查授权

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

### 4).初始化人脸模型数据
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

## 3.OrangeFilter实现美颜效果

OrangeFilter SDK是一个独立的SDK，可以在实现了自渲染和推流的SDK和程序中使用。当前模块是在ThunderBoltSDK的基础上集成OrangeFilter的美颜功能。ThunderBolt SDK是提供各种客户端音视频SDK，具有可以灵活搭配的API组合，通过SDK连接全球部署的实时通信网络，为开发者提供质量稳定可靠的实时音视频通信服务。

![../doc/pic/美颜.png](../doc/pic/美颜.png)



上图是OrangeFilter SDK在Demo中实现美颜功能的API调用时序图。如果需要在其他场景下使用OrangeFilter SDK，可以参考EffectCaptureProcessor类的实现。

> **注意**
> <br>effect模块对OrangeFilter SDK的API提供了一些高度封装的接口，但是不保证effect模块以后对OrangeFilter SDK的各个版本兼容。且对effect模块不负任何责任

## 4.Effect API

此处列出effect封装的OrangeFilter SDK的API。



#### init

初始化SDK。

```java
    /**
    * 初始化
    * @param defBeautyPath 上下文
    * @param serialNumber 鉴权串
    */
    EffectManager.getIns().init(Context context, String serialNumber);
```

| 参数         | 类型    | 描述   |
| :----------- | :------ | :----- |
| context      | Context | 上下文 |
| serialNumber | String  | 鉴权串 |

--------------------------

#### setDefaultBeautyEffect

设置美颜特效包保存路径。

> - **注意:**
> - 调用该接口设置文件保存路径后，美颜特效包下载后将保存在该路径下。
> - 需要在直播之前调用，否则默认美颜开启不了

```java
    /**
    * 设置美颜特效包路径
    * @ defBeautyPath 美颜特效包下载后的文件保存路径
    */
   EffectManager.getIns().setDefaultBeautyEffect(String defBeautyPath);
```

| 参数          | 类型   | 描述                           |
| :------------ | :----- | :----------------------------- |
| defBeautyPath | String | 美颜特效包下载后的文件保存路径 |

--------------------------

#### setBeautyEffectEnable

打开/关闭美颜

> - **说明:**
> - 要确保setDefaultBeautyEffect之后，否则没有美颜特效包。

```java
    /**
    * 开关美颜
    * @param enable true打开美颜  false关闭美颜
    */
   EffectManager.getIns().setBeautyEffectEnable(boolean enable);
```

| 参数   | 类型    | 描述                                  |
| :----- | :------ | :------------------------------------ |
| enable | boolean | 开关美颜，true打开美颜  false关闭美颜 |

--------------------------

#### isBeautyReady

是否开启美颜。

```java
    /**
    * 是否开启美颜
    * 获取美颜参数前，需先开启美颜。
    * @return true美颜已经打开  false美颜已经关闭
    */
   EffectManager.getIns().isBeautyReady();
```

#### getBeautyOption

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

| 参数       | 类型   | 描述                                                         |
| :--------- | :----- | :----------------------------------------------------------- |
| optionType | int    | 详见[BeautyHelper#（FILTER_INDEX_WHITE，FILTER_INDEX_BEAUTY，FILTER_INDEX_FACELIFTING）]，后台下发 |
| optionName | String | 详见[BeautyHelper#BEAUTY_OPTION_NAMES]，后台下发             |

--------------------------

#### setBeautyOptionValue

调整美颜整形程度


> - **说明:**
> - 要确保setDefaultBeautyEffect之后，否则没有美颜特效包。

```java
    /**
    * @param optionType 详见[BeautyHelper#（FILTER_INDEX_WHITE，FILTER_INDEX_BEAUTY，FILTER_INDEX_FACELIFTING）]
    * @param optionName 详见[BeautyHelper#BEAUTY_OPTION_NAMES]
    * @param value 设置的值，这个值须在对应范围以内，不同的美颜整形的范围是不同的，可能是【0～100】、【-50～50】。。。可以通过getBeautyOption获取得到
    */
    EffectManager.getIns().setBeautyOptionValue(int optionType, String optionName, int value);
```

| 参数       | 类型   | 描述                                                         |
| :--------- | :----- | :----------------------------------------------------------- |
| optionType | int    | 详见[BeautyHelper#（FILTER_INDEX_WHITE，FILTER_INDEX_BEAUTY，FILTER_INDEX_FACELIFTING）]，后台下发 |
| optionName | String | 详见[BeautyHelper#BEAUTY_OPTION_NAMES]，后台下发             |
| value      | int    | 设置的值，这个值须在对应范围以内，不同的美颜整形的范围是不同的，可能是【0～100】、【-50～50】。。。可以通过getBeautyOption获取得到 |

--------------------------

#### setEffectWithType

设置滤镜、表情、手势(点赞、单手比芯、双手比芯、666、手掌、比V、OK)。详见[EffectConst.Effect](#11.EffectConst.Effect)

```java
    /**
    * @param type 传EffectConst.Effect
    * @param effectPath 特效包下载保存的路径，如果path=""，则是清空状态。
    */
     EffectManager.getIns().setEffectWithType(String type, String effectPath);
```

| 参数       | 类型   | 描述                                                       |
| :--------- | :----- | :--------------------------------------------------------- |
| type       | String | 特效类型，详见[EffectConst.Effect](#11.EffectConst.Effect) |
| effectPath | String | 特效包下载保存的路径，如果path=""，则是清空状态。          |

--------------------------

#### setFilterIntensity

设置滤镜程度。

```java
    /**
    * @param value 设置滤镜程度。【0-100】
    */
     EffectManager.getIns().setFilterIntensity(int value);
```

| 参数  | 类型 | 描述                          |
| :---- | :--- | :---------------------------- |
| value | int  | 滤镜程度值。取值范围【0-100】 |

--------------------------

#### closeAllGestureEffect

关闭所有手势。

```java
    /**
    * 关闭所有手势
    */
     EffectManager.getIns().closeAllGestureEffect();  
```

#### EffectConst.Effect

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





## 5.OrangeFilter SDK API

#### OrangeFilter:createContext

```java
int createContext(String VenusModelPath);
```

创建 OrangeFilter Context。

##### 参数[]

| 参数           | 类型   | 描述                                                         |
| :------------- | :----- | :----------------------------------------------------------- |
| VenusModelPath | String | venus_models数据模型路径 见[初始化加载人脸模型数据](#初始化加载人脸模型数据) |

--------------------------

#### OrangeFilter:prepareFrameData

```java
int prepareFrameData(int context, int witdh, int height, OrangeFilter.OF_FrameData frameData);
```

渲染前预处理帧数据，包含人脸姿态（空间位置、朝向）计算。

> **注意：**
>
> - 返回值，成功时返回 OF_Result_Success。

##### 参数[]

| 参数      | 类型                      | 描述       |
| :-------- | :------------------------ | :--------- |
| context   | String                    | Context ID |
| witdh     | int                       | 帧宽       |
| height    | int                       | 帧高       |
| frameData | OrangeFilter.OF_FrameData | 帧数据     |

--------------------------

#### OrangeFilter:applyFrame

```java
int applyFrame(int context, int effect, OrangeFilter.OF_Texture[] inputs, OrangeFilter.OF_Texture[] outputs);
```

渲染帧特效。

> **注意：**
>
> - 返回值，成功时返回 OF_Result_Success。


##### 参数[]

| 参数    | 类型                      | 描述                                                         |
| :------ | :------------------------ | :----------------------------------------------------------- |
| context | int                       | Context id                                                   |
| effect  | int                       | Effect id                                                    |
| inputs  | OrangeFilter.OF_Texture[] | 输入图像纹理数组，来源于摄像头采集视频图像或静态图片，通常为 1 个 |
| outputs | OrangeFilter.OF_Texture[] | 输出图像纹理数组，用于渲染到屏幕或编码到视频流，通常为 1 个  |

--------------------------

#### OrangeFilter:setFilterParamData

```java
int setFilterParamData(int context, int filter, String paramName, OrangeFilter.OF_Param param);
```

设置 Filter 参数数据。

> **注意：**
>
> - 返回值，成功时返回 OF_Result_Success。


##### 参数[]

| 参数      | 类型                  | 描述                                                         |
| :-------- | :-------------------- | :----------------------------------------------------------- |
| context   | int                   | Context id                                                   |
| filter    | int                   | Filter id                                                    |
| paramName | String                | 参数名称                                                     |
| param     | OrangeFilter.OF_Param | 通过getFilterParamData可以从特效包取出所包含的所有效果，每个效果都会有对应的param |

--------------------------

#### OrangeFilter:destroyEffect

```java
int destroyEffect(int context, int effect);
```

销毁 Effect。

> **注意：**
>
> - 返回值：成功时返回 OF_Result_Success。


##### 参数[]

| 参数    | 类型 | 描述       |
| :------ | :--- | :--------- |
| context | int  | Context id |
| effect  | int  | Effect id  |

--------------------------

#### OrangeFilter:destroyContext

```java
int destroyContext(int context);
```

销毁 OrangeFilter Context。

> **注意：**
>
> - 返回值：成功时返回 OF_Result_Success。


##### 参数[]

| 参数    | 类型 | 描述                |
| :------ | :--- | :------------------ |
| context | int  | 要销毁的 Context id |



## 6.自定义特效包资源

请联系聚联云技术支持获取定制特效包。

#### 下发OrangeFilter特效接口（业务自定义）
Demo协议为后台下发，分为美颜，滤镜，表情，手势相关协议。业务可以使用默认协议或定义，详见协议文件[mouselive-android/effect/src/main/java/com/sclouds/effect/beauty_effect.json]。

