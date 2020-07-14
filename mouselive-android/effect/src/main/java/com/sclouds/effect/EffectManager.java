package com.sclouds.effect;

import android.content.Context;
import android.text.TextUtils;

import com.orangefilter.OrangeFilter;
import com.sclouds.effect.consts.EffectConst;
import com.sclouds.effect.utils.BeautyHelper;
import com.sclouds.effect.utils.FilterHelper;
import com.thunder.livesdk.ThunderEngine;

import java.io.File;
import java.util.logging.Logger;

/**
 * Created by zhouwen on 2020/4/8.
 * 特效接口类--美颜,滤镜,贴纸,手势功能接口管理类
 */
public class EffectManager {

    private static final Logger sLogger = Logger.getLogger("FaceEffectManager");
    private static EffectManager sEffectManager;

    private String mVenusModelPath;
    private String mDefaultBeautyPath;
    // 是否已经注册过registerVideoCaptureTextureObserver等相关
    private boolean mHasRegister = false;

    private EffectCaptureProcessor mEffectProcessor = null;
    private EffectCaptureProcessor.VideoCaptureWrapper mVideoCaptureWrapper;

    private BeautyHelper mBeautyHelper = new BeautyHelper();
    private FilterHelper mFilterHelper = new FilterHelper();
    private BeautyOption mOption = new BeautyOption();

    private ThunderEngine mThunderEngine = null;

    public static EffectManager getIns() {
        if (sEffectManager == null) {
            synchronized (EffectManager.class) {
                if (sEffectManager == null) {
                    sEffectManager = new EffectManager();
                }
            }
        }

        return sEffectManager;
    }

    /**
     * 初始化
     *
     * @param context      上下文
     * @param serialNumber 鉴权串（需要业务方通过技术支持内部申请）
     */
    public void init(Context context, ThunderEngine mThunderEngine, String serialNumber) {
        sLogger.info("chowen#init>>>>>>>");
        this.mThunderEngine = mThunderEngine;

        OrangeFilter.setLogLevel(OrangeFilter.OF_LogLevel_Debug);
        // extract assets 加载美颜，滤镜相关数据模型
        mVenusModelPath = context.getFilesDir().getPath() + "/orangefilter/models/venus_models";
        File modelDir = new File(mVenusModelPath);

        if (!(modelDir.isDirectory() && modelDir.exists())) {
            boolean isSuc = new File(mVenusModelPath + "/face").mkdirs();
            sLogger.info("initOfSdk#isSuc=" + isSuc);
            OrangeFilter.extractAssetsDir(
                    context.getAssets(),
                    "models/venus_models/face",
                    mVenusModelPath + "/face"
            );

            new File(mVenusModelPath + "/segment").mkdirs();
            OrangeFilter.extractAssetsDir(
                    context.getAssets(),
                    "models/venus_models/segment",
                    mVenusModelPath + "/segment"
            );

            new File(mVenusModelPath + "/gesture").mkdirs();
            OrangeFilter.extractAssetsDir(
                    context.getAssets(),
                    "models/venus_models/gesture",
                    mVenusModelPath + "/gesture"
            );
        }

        final String effectPath = context.getFilesDir().getPath() + "/orangefilter/effects";
        File effectDir = new File(effectPath);
        if (!(effectDir.isDirectory() && effectDir.exists())) {
            effectDir.mkdirs();
            OrangeFilter.extractAssetsDir(context.getAssets(), "effects", effectPath);
        }

        // check license 鉴权
        final String ofLicenseName = "of_offline_license.license";
        String ofLicensePath = context.getFilesDir().getPath() + "/" + ofLicenseName;
        int ret = OrangeFilter.checkSerialNumber(context, serialNumber, ofLicensePath);
        if (ret != OrangeFilter.OF_Result_Success) {
            sLogger.severe("OrangeFilter license invalid. ret = [" + ret + "]");
        } else {
            sLogger.info("OrangeFilter license valid. ret = [" + ret + "]");
        }
    }

    /**
     * 注意，register函数需要在startVideoPreview紧挨着下面调用
     */
    public void register() {
        if (mThunderEngine == null) {
            throw new NullPointerException("your must call init first");
        }

        sLogger.severe("GPUImageBeautyOrangeFilter register");
        mEffectProcessor = new EffectCaptureProcessor(mVenusModelPath);
        mEffectProcessor.setEffectHelper(mBeautyHelper, mFilterHelper);
        mThunderEngine.registerVideoCaptureTextureObserver(mEffectProcessor);

        mVideoCaptureWrapper = mEffectProcessor.new VideoCaptureWrapper();
        mThunderEngine.registerVideoCaptureFrameObserver(mVideoCaptureWrapper);

        if (!TextUtils.isEmpty(mDefaultBeautyPath)) {
            setBeautyEffectPath(mDefaultBeautyPath);
        }
        mHasRegister = true;
    }

    /**
     * 注意，unRegister函数需要在stopVideoPreview后调用
     */
    public void unRegister() {
        if (mThunderEngine == null) {
            return;
        }

        sLogger.severe("GPUImageBeautyOrangeFilter unRegister");
        mThunderEngine.registerVideoCaptureTextureObserver(null);
        mThunderEngine.registerVideoCaptureFrameObserver(null);
        mEffectProcessor = null;
        mVideoCaptureWrapper = null;
        mHasRegister = false;
    }

    /**
     * 进入房间--设置美颜默认特效包路径：可默认显示美颜特效
     *
     * @param defBeautyPath 特效包路径
     */
    public void setDefaultBeautyEffect(String defBeautyPath) {
        mDefaultBeautyPath = defBeautyPath;
        if (mHasRegister) {
            setBeautyEffectPath(defBeautyPath);
        }
    }

    /**
     * 获取美颜整形 Filter 参数数据
     *
     * @param optionType 详见{@link BeautyHelper#（FILTER_INDEX_WHITE，FILTER_INDEX_BEAUTY，FILTER_INDEX_FACELIFTING）}
     * @param optionName 详见{@link BeautyHelper# BEAUTY_OPTION_NAMES}
     * @return BeautyOption
     */
    public BeautyOption getBeautyOption(int optionType, String optionName) {
        mOption.min = mBeautyHelper.getBeautyOptionMinValue(optionType, optionName);
        mOption.max = mBeautyHelper.getBeautyOptionMaxValue(optionType, optionName);
        mOption.value = mBeautyHelper.getBeautyOptionValue(optionType, optionName);
        if ((mOption.max - mOption.min) != 0) {
            mOption.percent = (mOption.value - mOption.min) * 100 / (mOption.max - mOption.min);
        } else {
            mOption.percent = 0;
        }

        return mOption;
    }

    /**
     * 美颜整形
     *
     * @param optionType 详见{@link BeautyHelper#（FILTER_INDEX_WHITE，FILTER_INDEX_BEAUTY，FILTER_INDEX_FACELIFTING）}
     *                   FILTER_INDEX_WHITE:美白
     *                   FILTER_INDEX_BEAUTY:美肤
     *                   FILTER_INDEX_FACELIFTING:整形一类
     * @param optionName 详见{@link BeautyHelper# BEAUTY_OPTION_NAMES}
     * @param value      修改特效value
     */
    public void setBeautyOptionValue(int optionType, String optionName, int value) {
        mBeautyHelper.setBeautyOptionValue(optionType, optionName, value);
    }

    /**
     * 设置美颜，滤镜，表情，手势(点赞，单手比心，双手比心，666，手掌，比V，OK)
     *
     * @param type:       类型  详见{@link com.sclouds.effect.consts.EffectConst.Effect}
     * @param effectPath: 特效资源path:后台下发(业务可选)
     */
    public void setEffectWithType(String type, String effectPath) {
        sLogger.info("setEffectWithType#type=" + type + ">>effectPath=" + effectPath);
        if (TextUtils.equals(type, EffectConst.Effect.EFFECT_BEAUTY)) {
            setBeautyEffectPath(effectPath);
        } else if (TextUtils.equals(type, EffectConst.Effect.EFFECT_FILTER)) {
            setFilterEffectPath(effectPath);
        } else if (TextUtils.equals(type, EffectConst.Effect.EFFECT_STICKER)) {
            setStickerEffectPath(effectPath);
        } else if (TextUtils.equals(type, EffectConst.Effect.EFFECT_GESTURE)) {
            setGestureEffectPath(effectPath);
        } else if (TextUtils.equals(type, EffectConst.GestureEffectType.GESTURE_GOOD)) {
            setGestureGoodEffect(effectPath);
        } else if (TextUtils.equals(type, EffectConst.GestureEffectType.GESTURE_SINGLE_LOVE)) {
            setGestureSingleLoveEffect(effectPath);
        } else if (TextUtils.equals(type, EffectConst.GestureEffectType.GESTURE_DOUBLE_LOVE)) {
            setGestureDoubleLoveEffect(effectPath);
        } else if (TextUtils.equals(type, EffectConst.GestureEffectType.GESTURE_SIX)) {
            setGestureSixEffect(effectPath);
        } else if (TextUtils.equals(type, EffectConst.GestureEffectType.GESTURE_HAND)) {
            setGestureHandEffect(effectPath);
        } else if (TextUtils.equals(type, EffectConst.GestureEffectType.GESTURE_V)) {
            setGestureVEffect(effectPath);
        } else if (TextUtils.equals(type, EffectConst.GestureEffectType.GESTURE_OK)) {
            setGestureOkEffect(effectPath);
        }
    }

    /**
     * 关闭所有手势
     */
    public void closeAllGestureEffect() {
        if (mEffectProcessor != null) {
            mEffectProcessor.closeAllGestureEffect();
        }
    }

    /**
     * 设置手势:点赞特效资源（业务可后台下发可指定存储path）
     *
     * @param effectPath 特效路径
     */
    private void setGestureGoodEffect(String effectPath) {
        if (mEffectProcessor != null) {
            if (TextUtils.isEmpty(effectPath)) {
                mEffectProcessor.setGestureGoodEnable(false);
            } else {
                mEffectProcessor.setGestureGoodEnable(true);
            }
            mEffectProcessor.setGestureGoodEffect(effectPath);
        }
    }

    /**
     * 设置手势:单手比心特效资源（业务可后台下发可指定存储path）
     *
     * @param effectPath 特效路径
     */
    private void setGestureSingleLoveEffect(String effectPath) {
        if (mEffectProcessor != null) {
            if (TextUtils.isEmpty(effectPath)) {
                mEffectProcessor.setGestureSingleLoveEnable(false);
            } else {
                mEffectProcessor.setGestureSingleLoveEnable(true);
            }
            mEffectProcessor.setGestureSingleLovePath(effectPath);
        }
    }

    /**
     * 设置手势:双手比心特效资源（业务可后台下发可指定存储path）
     *
     * @param effectPath 特效路径
     */
    private void setGestureDoubleLoveEffect(String effectPath) {
        if (mEffectProcessor != null) {
            if (TextUtils.isEmpty(effectPath)) {
                mEffectProcessor.setGestureDoubleLoveEnable(false);
            } else {
                mEffectProcessor.setGestureDoubleLoveEnable(true);
            }
            mEffectProcessor.setGestureDoubleLovePath(effectPath);
        }
    }

    /**
     * 设置手势:666特效资源（业务可后台下发可指定存储path）
     *
     * @param effectPath 特效路径
     */
    private void setGestureSixEffect(String effectPath) {
        if (mEffectProcessor != null) {
            if (TextUtils.isEmpty(effectPath)) {
                mEffectProcessor.setGestureSixEnable(false);
            } else {
                mEffectProcessor.setGestureSixEnable(true);
            }
            mEffectProcessor.setGestureSixPath(effectPath);
        }
    }

    /**
     * 设置手势:比V 特效资源（业务可后台下发可指定存储path）
     *
     * @param effectPath 特效路径
     */
    private void setGestureVEffect(String effectPath) {
        if (mEffectProcessor != null) {
            if (TextUtils.isEmpty(effectPath)) {
                mEffectProcessor.setGestureVEnable(false);
            } else {
                mEffectProcessor.setGestureVEnable(true);
            }
            mEffectProcessor.setGestureVPath(effectPath);
        }
    }

    /**
     * 设置手势:OK 特效资源（业务可后台下发可指定存储path）
     *
     * @param effectPath 特效路径
     */
    private void setGestureOkEffect(String effectPath) {
        if (mEffectProcessor != null) {
            if (TextUtils.isEmpty(effectPath)) {
                mEffectProcessor.setGestureOkEnable(false);
            } else {
                mEffectProcessor.setGestureOkEnable(true);
            }
            mEffectProcessor.setGestureOkPath(effectPath);
        }
    }

    /**
     * 设置手势:手掌 特效资源（业务可后台下发可指定存储path）
     *
     * @param effectPath 特效路径
     */
    private void setGestureHandEffect(String effectPath) {
        if (mEffectProcessor != null) {
            if (TextUtils.isEmpty(effectPath)) {
                mEffectProcessor.setGestureHandEnable(false);
            } else {
                mEffectProcessor.setGestureHandEnable(true);
            }
            mEffectProcessor.setGestureHandPath(effectPath);
        }
    }

    /**
     * 开启美颜
     *
     * @param enable true:开启 or false：关闭
     */
    public void setBeautyEffectEnable(boolean enable) {
        if (mEffectProcessor != null) {
            mEffectProcessor.setBeautyEffectEnable(enable);
        }
    }

    /**
     * 设置手势特效资源（业务可后台下发可指定存储path）
     *
     * @param path 特效路径
     */
    private void setGestureEffectPath(String path) {
        if (mEffectProcessor != null) {
            if (TextUtils.isEmpty(path)) {
                mEffectProcessor.setGestureEffectEnable(false);
            } else {
                mEffectProcessor.setGestureEffectEnable(true);
            }
            mEffectProcessor.setGestureEffectPath(path);
        }
    }

    /**
     * 设置美颜特效资源（业务可后台下发可指定存储path）
     *
     * @param path 特效路径
     */
    private void setBeautyEffectPath(String path) {
        if (mEffectProcessor != null) {
            if (TextUtils.isEmpty(path)) {
                mEffectProcessor.setBeautyEffectEnable(false);
            } else {
                mEffectProcessor.setBeautyEffectEnable(true);
            }
            mEffectProcessor.setBeautyEffectPath(path);
        }
    }

    /**
     * 设置滤镜特效资源（业务可后台下发可指定存储path）
     *
     * @param path 特效路径
     */
    private void setFilterEffectPath(String path) {
        if (mEffectProcessor != null) {
            if (TextUtils.isEmpty(path)) {
                mEffectProcessor.setFilterEffectEnable(false);
            } else {
                mEffectProcessor.setFilterEffectEnable(true);
            }
            mEffectProcessor.setFilterEffectPath(path);
        }
    }

    /**
     * 设置贴纸特效资源（业务可后台下发可指定存储path）
     *
     * @param path 特效路径
     */
    private void setStickerEffectPath(String path) {
        if (mEffectProcessor != null) {
            if (TextUtils.isEmpty(path)) {
                mEffectProcessor.setStickerEffectEnable(false);
            } else {
                mEffectProcessor.setStickerEffectEnable(true);
            }
            mEffectProcessor.setStickerEffectPath(path);
        }
    }

    /**
     * 设置滤镜强度
     *
     * @param value 滤镜强度值
     */
    public void setFilterIntensity(int value) {
        mFilterHelper.setFilterIntensity(value);
    }

    /**
     * 是否准备好美颜数据
     *
     * @return beauty is ready
     */
    public boolean isBeautyReady() {
        return mBeautyHelper.isReady();
    }

    /**
     * 是否准备好滤镜数据
     *
     * @return filter is ready
     */
    public boolean isFilterReady() {
        return mFilterHelper.isReady();
    }
}
