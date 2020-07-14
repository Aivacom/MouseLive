package com.sclouds.datasource.effect;

import android.content.Context;

import com.sclouds.datasource.effect.bean.BeautyOption;
import com.thunder.livesdk.ThunderEngine;

/**
 * @author xipeitao
 * @description:
 * @date : 2020/6/17 9:56 AM
 */
public interface IEffect {

    /**
     * 特效类型
     */
    public interface Effect {
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

    /**
     * 初始化
     *
     * @param context      上下文
     * @param serialNumber 鉴权串（需要业务方通过技术支持内部申请）
     */
    public void init(Context context, ThunderEngine mThunderEngine, String serialNumber);

    /**
     * 注意，register函数需要在startVideoPreview紧挨着下面调用
     */
    public void register();

    /**
     * 注意，unRegister函数需要在stopVideoPreview后调用
     */
    public void unRegister();

    /**
     * 进入房间--设置美颜默认特效包路径：可默认显示美颜特效
     *
     * @param defBeautyPath 特效包路径
     */
    public void setDefaultBeautyEffect(String defBeautyPath);

    /**
     * 获取美颜整形 Filter 参数数据
     *
     * @param optionType 详见{@link BeautyHelper#（FILTER_INDEX_WHITE，FILTER_INDEX_BEAUTY，FILTER_INDEX_FACELIFTING）}
     * @param optionName 详见{@link BeautyHelper# BEAUTY_OPTION_NAMES}
     * @return BeautyOption
     */
    public BeautyOption getBeautyOption(int optionType, String optionName);

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
    public void setBeautyOptionValue(int optionType, String optionName, int value);


    /**
     * 设置美颜，滤镜，表情，手势(点赞，单手比心，双手比心，666，手掌，比V，OK)
     *
     * @param type:       类型  详见{@link com.sclouds.effect.consts.EffectConst.Effect}
     * @param effectPath: 特效资源path:后台下发(业务可选)
     */
    public void setEffectWithType(String type, String effectPath);

    /**
     * 关闭所有手势
     */
    public void closeAllGestureEffect();


    /**
     * 开启美颜
     *
     * @param enable true:开启 or false：关闭
     */
    public void setBeautyEffectEnable(boolean enable);

    /**
     * 设置滤镜强度
     *
     * @param value 滤镜强度值
     */
    public void setFilterIntensity(int value);

    /**
     * 是否准备好美颜数据
     *
     * @return beauty is ready
     */
    public boolean isBeautyReady();

    /**
     * 是否准备好滤镜数据
     *
     * @return filter is ready
     */
    public boolean isFilterReady();


}
