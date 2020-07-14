package com.sclouds.effect_kotlin

import android.content.Context
import android.text.TextUtils
import com.orangefilter.OrangeFilter
import com.sclouds.effect_kotlin.consts.EffectConst
import com.sclouds.effect_kotlin.utils.BeautyHelper
import com.sclouds.effect_kotlin.utils.FilterHelper
import com.thunder.livesdk.ThunderEngine
import java.io.File
import java.util.logging.Logger

/**
 * Created by zhouwen on 2020/4/22.
 * 特效接口类--美颜,滤镜,贴纸,手势功能接口管理类
 */
class EffectManager {
    private var mVenusModelPath: String? = null
    private var mDefaultBeautyPath: String? = null

    // 是否已经注册过registerVideoCaptureTextureObserver等相关
    private var mHasRegister = false
    private var mGpuBeauty: EffectCaptureProcessor? = null
    private var mVideoCaptureWrapper: EffectCaptureProcessor.VideoCaptureWrapper? = null
    private val mBeautyHelper = BeautyHelper()
    private val mFilterHelper = FilterHelper()
    private val mOption = BeautyOption()

    private var mThunderEngine: ThunderEngine? = null

    /**
     * 初始化
     * @param context 上下文
     * @param serialNumber 鉴权串（需要业务方通过技术支持内部申请）
     */
    fun init(context: Context, mThunderEngine: ThunderEngine, serialNumber: String) {
        sLogger.info("chowen#init>>>>>>>")
        this.mThunderEngine = mThunderEngine

        OrangeFilter.setLogLevel(OrangeFilter.OF_LogLevel_Debug)
        // extract assets 加载美颜，滤镜相关数据模型
        mVenusModelPath = context.filesDir.path + "/orangefilter/models/venus_models"
        val modelDir = File(mVenusModelPath)
        if (!(modelDir.isDirectory && modelDir.exists())) {
            val isSuc = File("$mVenusModelPath/face").mkdirs()
            sLogger.info("initOfSdk#isSuc=$isSuc")
            OrangeFilter.extractAssetsDir(
                    context.assets,
                    "models/venus_models/face",
                    "$mVenusModelPath/face"
            )
            File("$mVenusModelPath/segment").mkdirs()
            OrangeFilter.extractAssetsDir(
                    context.assets,
                    "models/venus_models/segment",
                    "$mVenusModelPath/segment"
            )
            File("$mVenusModelPath/gesture").mkdirs()
            OrangeFilter.extractAssetsDir(
                    context.assets,
                    "models/venus_models/gesture",
                    "$mVenusModelPath/gesture"
            )
        }
        val effectPath = context.filesDir.path + "/orangefilter/effects"
        val effectDir = File(effectPath)
        if (!(effectDir.isDirectory && effectDir.exists())) {
            effectDir.mkdirs()
            OrangeFilter.extractAssetsDir(context.assets, "effects", effectPath)
        }

        // check license 鉴权
        val ofLicenseName = "of_offline_license.license"
        val ofLicensePath = context.filesDir.path + "/" + ofLicenseName
        val ret = OrangeFilter.checkSerialNumber(context, serialNumber, ofLicensePath)
        if (ret != OrangeFilter.OF_Result_Success) {
            sLogger.severe("OrangeFilter license invalid. ret = [$ret]")
        } else {
            sLogger.info("OrangeFilter license valid. ret = [$ret]")
        }
    }

    /**
     * 注意，register函数需要在startVideoPreview紧挨着下面调用
     */
    fun register() {
        if (mThunderEngine != null) {
            sLogger.severe("GPUImageBeautyOrangeFilter register")
            mGpuBeauty = EffectCaptureProcessor(mVenusModelPath)
            mGpuBeauty?.setEffectHelper(mBeautyHelper, mFilterHelper)
            mThunderEngine?.registerVideoCaptureTextureObserver(mGpuBeauty)
            mVideoCaptureWrapper = mGpuBeauty?.VideoCaptureWrapper()
            mThunderEngine?.registerVideoCaptureFrameObserver(mVideoCaptureWrapper)
        }
        if (!TextUtils.isEmpty(mDefaultBeautyPath)) {
            setBeautyEffectPath(mDefaultBeautyPath)
        }
        mHasRegister = true
    }

    /**
     * 注意，unRegister函数需要在stopVideoPreview后调用
     */
    fun unRegister() {
        if (mThunderEngine != null) {
            sLogger.severe("GPUImageBeautyOrangeFilter unRegister")
            mThunderEngine?.registerVideoCaptureTextureObserver(null)
            mThunderEngine?.registerVideoCaptureFrameObserver(null)
            mGpuBeauty = null
            mVideoCaptureWrapper = null
        }
        mHasRegister = false
    }

    /**
     * 进入房间--设置美颜默认特效包路径：可默认显示美颜特效
     *
     * @param defBeautyPath 特效包路径
     */
    fun setDefaultBeautyEffect(defBeautyPath: String?) {
        mDefaultBeautyPath = defBeautyPath
        if (mHasRegister) {
            setBeautyEffectPath(defBeautyPath)
        }
    }

    /**
     * 获取美颜整形 Filter 参数数据
     * @param optionType  详见{@link BeautyHelper#（FILTER_INDEX_WHITE，FILTER_INDEX_BEAUTY，FILTER_INDEX_FACELIFTING）}
     * @param optionName  详见{@link BeautyHelper# BEAUTY_OPTION_NAMES}
     * @return BeautyOption
     */
    fun getBeautyOption(optionType: Int, optionName: String?): BeautyOption {
        mOption.min = mBeautyHelper.getBeautyOptionMinValue(optionType, optionName)
        mOption.max = mBeautyHelper.getBeautyOptionMaxValue(optionType, optionName)
        mOption.value = mBeautyHelper.getBeautyOptionValue(optionType, optionName)
        mOption.percent = (mOption.value - mOption.min) * 100 / (mOption.max - mOption.min)
        return mOption
    }

    /**
     * 美颜整形
     *
     * @param optionType  详见{@link BeautyHelper#（FILTER_INDEX_WHITE，FILTER_INDEX_BEAUTY，FILTER_INDEX_FACELIFTING）}
     *                    FILTER_INDEX_WHITE:美白
     *                    FILTER_INDEX_BEAUTY:美肤
     *                    FILTER_INDEX_FACELIFTING:整形一类
     * @param optionName  详见{@link BeautyHelper# BEAUTY_OPTION_NAMES}
     * @param value 修改特效value
     */
    fun setBeautyOptionValue(optionType: Int, optionName: String?, value: Int) {
        mBeautyHelper.setBeautyOptionValue(optionType, optionName, value)
    }

    /**
     * 设置美颜，滤镜，表情，手势(点赞，单手比心，双手比心，666，手掌，比V，OK)
     *
     * @param type:       类型  详见[EffectConst.Effect]
     * @param effectPath: 特效资源path:后台下发(业务可选)
     */
    fun setEffectWithType(type: String?, effectPath: String?) {
        when (type) {
            EffectConst.Effect.EFFECT_BEAUTY -> setBeautyEffectPath(effectPath)
            EffectConst.Effect.EFFECT_FILTER -> setFilterEffectPath(effectPath)
            EffectConst.Effect.EFFECT_STICKER -> setStickerEffectPath(effectPath)
            EffectConst.Effect.EFFECT_GESTURE -> setGestureEffectPath(effectPath)
            EffectConst.GestureEffectType.GESTURE_GOOD -> setGestureGoodEffect(effectPath)
            EffectConst.GestureEffectType.GESTURE_SINGLE_LOVE -> setGestureSingleLoveEffect(
                    effectPath)
            EffectConst.GestureEffectType.GESTURE_DOUBLE_LOVE -> setGestureDoubleLoveEffect(
                    effectPath)
            EffectConst.GestureEffectType.GESTURE_SIX -> setGestureSixEffect(effectPath)
            EffectConst.GestureEffectType.GESTURE_HAND -> setGestureHandEffect(effectPath)
            EffectConst.GestureEffectType.GESTURE_V -> setGestureVEffect(effectPath)
            EffectConst.GestureEffectType.GESTURE_OK -> setGestureOkEffect(effectPath)
            else -> {

            }
        }
    }

    /**
     * 关闭所有手势
     */
    fun closeAllGestureEffect() {
        if (mGpuBeauty != null) {
            mGpuBeauty?.closeAllGestureEffect()
        }
    }

    /**
     * 设置手势:点赞特效资源（业务可后台下发可指定存储path）
     *
     * @param effectPath 特效路径
     */
    private fun setGestureGoodEffect(effectPath: String?) {
        if (mGpuBeauty != null) {
            if (TextUtils.isEmpty(effectPath)) {
                mGpuBeauty?.setGestureGoodEnable(false)
            } else {
                mGpuBeauty?.setGestureGoodEnable(true)
            }
            mGpuBeauty?.setGestureGoodEffect(effectPath)
        }
    }

    /**
     * 设置手势:单手比心特效资源（业务可后台下发可指定存储path）
     *
     * @param effectPath 特效路径
     */
    private fun setGestureSingleLoveEffect(effectPath: String?) {
        if (mGpuBeauty != null) {
            if (TextUtils.isEmpty(effectPath)) {
                mGpuBeauty?.setGestureSingleLoveEnable(false)
            } else {
                mGpuBeauty?.setGestureSingleLoveEnable(true)
            }
            mGpuBeauty?.setGestureSingleLovePath(effectPath)
        }
    }

    /**
     * 设置手势:双手比心特效资源（业务可后台下发可指定存储path）
     *
     * @param effectPath 特效路径
     */
    private fun setGestureDoubleLoveEffect(effectPath: String?) {
        if (mGpuBeauty != null) {
            if (TextUtils.isEmpty(effectPath)) {
                mGpuBeauty?.setGestureDoubleLoveEnable(false)
            } else {
                mGpuBeauty?.setGestureDoubleLoveEnable(true)
            }
            mGpuBeauty?.setGestureDoubleLovePath(effectPath)
        }
    }

    /**
     * 设置手势:666特效资源（业务可后台下发可指定存储path）
     *
     * @param effectPath 特效路径
     */
    private fun setGestureSixEffect(effectPath: String?) {
        if (mGpuBeauty != null) {
            if (TextUtils.isEmpty(effectPath)) {
                mGpuBeauty?.setGestureSixEnable(false)
            } else {
                mGpuBeauty?.setGestureSixEnable(true)
            }
            mGpuBeauty?.setGestureSixPath(effectPath)
        }
    }

    /**
     * 设置手势:比V 特效资源（业务可后台下发可指定存储path）
     *
     * @param effectPath 特效路径
     */
    private fun setGestureVEffect(effectPath: String?) {
        if (mGpuBeauty != null) {
            if (TextUtils.isEmpty(effectPath)) {
                mGpuBeauty?.setGestureVEnable(false)
            } else {
                mGpuBeauty?.setGestureVEnable(true)
            }
            mGpuBeauty?.setGestureVPath(effectPath)
        }
    }

    /**
     * 设置手势:OK 特效资源（业务可后台下发可指定存储path）
     *
     * @param effectPath 特效路径
     */
    private fun setGestureOkEffect(effectPath: String?) {
        if (mGpuBeauty != null) {
            if (TextUtils.isEmpty(effectPath)) {
                mGpuBeauty?.setGestureOkEnable(false)
            } else {
                mGpuBeauty?.setGestureOkEnable(true)
            }
            mGpuBeauty?.setGestureOkPath(effectPath)
        }
    }

    /**
     * 设置手势:手掌 特效资源（业务可后台下发可指定存储path）
     *
     * @param effectPath 特效路径
     */
    private fun setGestureHandEffect(effectPath: String?) {
        if (mGpuBeauty != null) {
            if (TextUtils.isEmpty(effectPath)) {
                mGpuBeauty?.setGestureHandEnable(false)
            } else {
                mGpuBeauty?.setGestureHandEnable(true)
            }
            mGpuBeauty?.setGestureHandPath(effectPath)
        }
    }

    /**
     * 开启美颜
     *
     * @param enable true:开启 or false：关闭
     */
    fun setBeautyEffectEnable(enable: Boolean) {
        if (mGpuBeauty != null) {
            mGpuBeauty?.setBeautyEffectEnable(enable)
        }
    }

    /**
     * 设置手势特效资源（业务可后台下发可指定存储path）
     *
     * @param path 特效路径
     */
    private fun setGestureEffectPath(path: String?) {
        if (mGpuBeauty != null) {
            if (TextUtils.isEmpty(path)) {
                mGpuBeauty?.setGestureEffectEnable(false)
            } else {
                mGpuBeauty?.setGestureEffectEnable(true)
            }
            mGpuBeauty?.setGestureEffectPath(path)
        }
    }

    /**
     * 设置美颜特效资源（业务可后台下发可指定存储path）
     *
     * @param path 特效路径
     */
    private fun setBeautyEffectPath(path: String?) {
        if (mGpuBeauty != null) {
            if (TextUtils.isEmpty(path)) {
                mGpuBeauty?.setBeautyEffectEnable(false)
            } else {
                mGpuBeauty?.setBeautyEffectEnable(true)
            }
            mGpuBeauty?.setBeautyEffectPath(path)
        }
    }

    /**
     * 设置滤镜特效资源（业务可后台下发可指定存储path）
     *
     * @param path 特效路径
     */
    private fun setFilterEffectPath(path: String?) {
        if (mGpuBeauty != null) {
            if (TextUtils.isEmpty(path)) {
                mGpuBeauty?.setFilterEffectEnable(false)
            } else {
                mGpuBeauty?.setFilterEffectEnable(true)
            }
            mGpuBeauty?.setFilterEffectPath(path)
        }
    }

    /**
     * 设置贴纸特效资源（业务可后台下发可指定存储path）
     *
     * @param path 特效路径
     */
    private fun setStickerEffectPath(path: String?) {
        if (mGpuBeauty != null) {
            if (TextUtils.isEmpty(path)) {
                mGpuBeauty?.setStickerEffectEnable(false)
            } else {
                mGpuBeauty?.setStickerEffectEnable(true)
            }
            mGpuBeauty?.setStickerEffectPath(path)
        }
    }

    /**
     * 设置滤镜强度
     *
     * @param value 滤镜强度值
     */
    fun setFilterIntensity(value: Int) {
        mFilterHelper.filterIntensity = value
    }

    /**
     * 是否准备好美颜数据
     *
     * @return beauty is ready
     */
    val isBeautyReady: Boolean
        get() = mBeautyHelper.isReady

    /**
     * 是否准备好滤镜数据
     *
     * @return filter is ready
     */
    val isFilterReady: Boolean
        get() = mFilterHelper.isReady

    companion object {
        private val sLogger = Logger.getLogger("FaceEffectManager")
        private var sEffectManager: EffectManager? = null
        val ins: EffectManager?
            get() {
                if (sEffectManager == null) {
                    synchronized(EffectManager::class.java) {
                        if (sEffectManager == null) {
                            sEffectManager = EffectManager()
                        }
                    }
                }
                return sEffectManager
            }
    }
}