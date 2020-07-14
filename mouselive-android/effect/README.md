# OrangeFilter SDK

OrangeFilter SDK, with content creation as the core, provides data-driven cross-platform video effects and AR interactive entertainment solutions, including various video beauty, dynamic filters, 2D/3D graphic effects, etc. The core code is based on C/C++ language and extends functions with Lua script.

* [1.User Authentication](#1.User Authentication)
* [2.Configure Project](#2.Configure Project)
* [3.Implementation](#3.Implementation)
* [4.Effect API](#4.Effect API)
* [5.OrangeFilter SDK API](#5.OrangeFilter SDK API)
* [6.Custom OrangeFilter Effect](#6.Custom OrangeFilter Effect)

-------------------------------------------------

## 1.User Authentication
Please contact the Jocloud technical support and offer the project AppID（android:applicationId/ios:bundle Id）for authentication. After approval, you will receive the serial No.

> **Notes** 
>
> - For authenticationdetails, see module [../mouselive-android/effect].
> -  Authentication type: face detection, background segmentation, and gesture detection. You can enable specified types or enable all.
> - Authentication includes SDK authentication (determines whether the SDK is available） and effect package authentication (determines whether the effect package can be loaded).
> -  For more effect packages, please contact the Jocloud technical support.

## 2.**Configure Project**

### 1).**Import OrangeFilter SDK**

 Add the following line in build.gradle file under the app module:

```java
dependencies {
    implementation fileTree(dir: 'libs', include: ['*.aar'])
}
```

**Notes:** SDK only support to depend by aar.


### 2).Declare OpenGL ES Feature & Permission

Add Declaration Code in AndroidManifest.xml file:

```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.INTERNET"/>

<uses-feature android:glEsVersion="0x00020000" android:required="true" />
```

### 3).**Initialization and Check Authorization**

Initialization when starts the application, sample codes are as below:

```java
// check license
 final String ofSerialNumber = getResources().getString(R.string.orangefilter_serial_number);
final String ofLicenseName = "of_offline_license.license";
String ofLicensePath = getFilesDir().getPath() + "/" + ofLicenseName;
int ret = OrangeFilter.checkSerialNumber(MainActivity.this, ofSerialNumber, ofLicensePath);
// Authentication Success when  OF_Result_Success return
if (ret != OrangeFilter.OF_Result_Success) {
    Log.e(TAG, "OrangeFilter license invalid. ret = [" + ret + "]");
}
```

### 4).**Initialize Face Model Data**
#### Copy the file in Demo :../src/main/assets/models/venus_models to the assets directory of the project.
> **Notes**
> <br> There are three directory in venus_models :Face Model(face),Gesture Data(gesture) and Segmentation Data(segment)

#### Initialize load face model data
> Copy the data form the assets dirctory to the current project file directory:
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

## 3.Implementation

OrangeFilter SDK is an independent SDK that you can use in any SDK and program that implements self-rendering and streaming. The current module is to integrate the beauty function of OrangeFilter on the basis of ThunderBoltSDK. ThunderBolt SDK, containing various client audio/video SDKs and flexible APIs, provides developers with stable and reliable real-time audio/video communication services through the global real-time communication network.



![../doc/pic/美颜.png](../doc/pic/美颜.png)

Picture above refers to the API calling sequence diagram of beauty function in this Demo. For using the OrangeFilter SDK in other scenarios, you can refer to the implementation of the EffectCaptureProcessor class.



> **Notes**
>
> The effect module provides some highly encapsulated interfaces to the OrangeFilter SDK api, but the effect module is not guaranteed to be compatible with all versions of the OrangeFilter SDK in the future. And take no responsibility for the effect module.



## 4.Effect API

Here are the APIs of the OrangeFilter SDK packaged in effect.

#### setDefaultBeautyEffect

Set the path to save the downloaded  beauty effect packages.

> - Note
> - After setting the saving path after calling this API, the downloaded beauty effect package will be saved in it.
> - Call this API before starting live streaming, otherwise the default effect cannot be enabled.

```java
    /**
    * Set the path of beauty effects package
    * @ defBeautyPath File saving path after downloading the beauty package
    */
   EffectManager.getIns().setDefaultBeautyEffect(String defBeautyPath);
```

| Parameter     | Type   | Description                                           |
| :------------ | :----- | :---------------------------------------------------- |
| defBeautyPath | String | File saving path after downloading the beauty package |

--------------------------

#### setBeautyEffectEnable

Turn on/off beauty

> **Note:**
>
> Call this API after setDefaultBeautyEffect, otherwise,there is no beauty effect package.

```java
    /**
    * Switch beauty
    * @param enable true Open beauty  false Close beauty
    */
   EffectManager.getIns().setBeautyEffectEnable(boolean enable);
```

| Parameter | Type    | Description                                               |
| :-------- | :------ | :-------------------------------------------------------- |
| enable    | boolean | Toggle beauty, true to open beauty, false to close beauty |

--------------------------

#### isBeautyReady

Whether to turn on beauty.

```java
    /**
    * Whether to turn on beauty
    * Before getting the beauty parameters, you should enable the beauty effect first.
    * @return “true”- enable, “false”-disable
    */
   EffectManager.getIns().isBeautyReady();
```

#### getBeautyOption

Get the beauty parameters of the current type, including maximum value, minimum value, current value, and percentage.

```java
    /**
    * Get the setting parameters of beauty under the current type
    * @param optionType Beauty plastic surgery type, see details in [BeautyHelper# (FILTER_INDEX_WHITE, FILTER_INDEX_BEAUTY, FILTER_INDEX_FACELIFTING)], issued in the background
    * @param optionName Beauty plastic type name, see details in [BeautyHelper#BEAUTY_OPTION_NAMES], issued in the background
    * @return beauty parameters
    */
   EffectManager.getIns().getBeautyOption(int optionType, String optionName);
```

| Parameter  | Type   | Description                                                  |
| :--------- | :----- | :----------------------------------------------------------- |
| optionType | int    | For details, see [BeautyHelper# (FILTER_INDEX_WHITE, FILTER_INDEX_BEAUTY, FILTER_INDEX_FACELIFTING)], issued in the background |
| optionName | String | See [BeautyHelper#BEAUTY_OPTION_NAMES] for details, issued in the background |

--------------------------

#### setBeautyOptionValue

Adjust the degree of beauty and plastic surgery


> - **Note:**
> - Make sure that after setDefaultBeautyEffect, otherwise there is no beauty effect package.

```java
    /**
    * @param optionType See [BeautyHelper#（FILTER_INDEX_WHITE，FILTER_INDEX_BEAUTY，FILTER_INDEX_FACELIFTING）]
    * @param optionName See [BeautyHelper#BEAUTY_OPTION_NAMES]
    * @param value The set value, this value must be within the corresponding range, the range of different beauty shaping is different, may be [0 ~ 100], [-50 ~ 50]. . . Can be obtained through getBeautyOption
    */
    EffectManager.getIns().setBeautyOptionValue(int optionType, String optionName, int value);
```

| Parameter  | Type   | Description                                                  |
| :--------- | :----- | :----------------------------------------------------------- |
| optionType | int    | See [BeautyHelper#（FILTER_INDEX_WHITE，FILTER_INDEX_BEAUTY，FILTER_INDEX_FACELIFTING）]，Issued in the background |
| optionName | String | See [BeautyHelper#BEAUTY_OPTION_NAMES]，Issued in the background |
| value      | int    | This value must be within the corresponding range, the range of different beauty shaping is different, may be [0 ~ 100], [-50 ~ 50]. . . Can be obtained through getBeautyOption |

--------------------------

#### setEffectWithType

Set filters, expressions, and gestures (such as like, OK). See more in EffectConst.Effect.

```java
    /**
    * @param type See EffectConst.Effect
    * @param effectPath The path of downloading and saving the special effect package, if path="", it is cleared.
    */
     EffectManager.getIns().setEffectWithType(String type, String effectPath);
```

| Parameter  | Type   | Description                                                  |
| :--------- | :----- | :----------------------------------------------------------- |
| type       | String | Special effect types, see [EffectConst.Effect](#11.EffectConst.Effect) |
| effectPath | String | The path of downloading and saving the special effect package, if path="", it is cleared. |

--------------------------

#### setFilterIntensity

Set the filter level.

```java
    /**
    * @param value Set the filter level.【0-100】
    */
     EffectManager.getIns().setFilterIntensity(int value);
```

| Parameter | Type | Description                               |
| :-------- | :--- | :---------------------------------------- |
| value     | int  | Filter degree value. Value range【0-100】 |

--------------------------

#### closeAllGestureEffect

Disable all gestures.

```java
    /**
    * Turn off all gestures
    */
     EffectManager.getIns().closeAllGestureEffect();  
```

#### EffectConst.Effect

```java
interface Effect {
        /**
         * Beauty
         */
        String EFFECT_BEAUTY = "beauty";
        /**
         * Filter
         */
        String EFFECT_FILTER = "filter";
        /**
         * Sticker
         */
        String EFFECT_STICKER = "sticker";
        /**
         * gesture
         */
        String EFFECT_GESTURE = "gesture";
        /**
         * gestures
         */
        String EFFECT_GESTURES = "gestures";
    }

    /**
     * Gesture effect subtypes: like, one-handed comparison, two-handed comparison, 666, palm, better than V, OK
     */
    interface GestureEffectType {
        /**
         * like
         */
        String GESTURE_GOOD = "gesture_thumbsup";
        /**
         * one-handed comparison
         */
        String GESTURE_SINGLE_LOVE = "gesture_onehandheart";
        /**
         * two-handed comparison
         */
        String GESTURE_DOUBLE_LOVE = "gesture_twohandheart";
        /**
         * 666
         */
        String GESTURE_SIX = "gesture_666";
        /**
         * palm
         */
        String GESTURE_HAND = "gesture_palm";
        /**
         * V
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

Create OrangeFilter Context.



| Parameter | Type | Desription |
| :--- | :--- | :--- |
| VenusModelPath | String | venus_models Path see [Initialize Face Model Data](#Initialize Face Model Data) |

--------------------------

#### OrangeFilter:prepareFrameData

```java
int prepareFrameData(int context, int witdh, int height, OrangeFilter.OF_FrameData frameData);
```

Pre-process frame data before rendering, including calculation of face pose (spatial position, orientation)
> **Note：**
>
> - Return value, return OF_Result_Success on success.

| Parameter | Type | Desription |
| :--- | :--- | :--- |
| context | String | Context ID |
| witdh | String | Frame Width |
| height | String | Frame Height |
| frameData | String | Context ID |
| context | String | Frame Data Object |

--------------------------

### OrangeFilter:applyFrame

```java
int applyFrame(int context, int effect, OrangeFilter.OF_Texture[] inputs, OrangeFilter.OF_Texture[] outputs);
```

Render Frame Effect

> **Note：**
>
> - Return value, return OF_Result_Success on success.

| Parameter | Type | Desription |
| :--- | :--- | :--- |
| context | int | Context ID |
| effect | int | Effect id |
| inputs | OrangeFilter.OF_Texture[] | Input image texture array,derived from the camera to collect video images or still pictures,usually 1 |
| outputs | OrangeFilter.OF_Texture[] | Output image texture array,used for rendering to screen or encoding to video stream,usually 1 |

--------------------------

#### OrangeFilter:setFilterParamData

```java
int setFilterParamData(int context, int filter, String paramName, OrangeFilter.OF_Param param);
```

Set Filter Parameter Data。

> **Note：**
>
> - Return value, return OF_Result_Success on success.


##### Parameter[]

| Parameter | Type | Description |
| :--- | :--- | :--- |
| context | int | Context id |
| filter | int | Filter id |
| paramName | String | Parameter Name |
| param | OrangeFilter.OF_Param | Through getFilterParamData, you can take out all the effects contained in the special effect package, and each effect will have a corresponding param |

--------------------------

#### OrangeFilter:destroyEffect

```java
int destroyEffect(int context, int effect);
```

Destroy Effect。

> **Note：**
>
> - Return value, return OF_Result_Success on success.

| Parameter | Type | Description |
| :--- | :--- | :--- |
| context | int | Context id |
| effect | int | Effect id |

--------------------------

#### OrangeFilter:destroyContext

```java
int destroyContext(int context);
```

Destroy OrangeFilter Context。

> **Note：**
>
> - Return value, return OF_Result_Success on success.

| Parameter | Type | Description |
| :--- | :--- | :--- |
| context | int | Context id to destroy |

## 6.Custom OrangeFilter Effect

Please contact the Jocloud technical support for customizing effects.

#### Apply Custom OrangeFilter Effects

Demo protocols, delivered in the background, contain beauty, filter, expression, and gesture protocol. You can use the default ones or customize, see details in [mouselive-android/effect/src/main/java/com/sclouds/effect/beauty_effect.json].





