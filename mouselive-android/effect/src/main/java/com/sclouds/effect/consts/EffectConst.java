package com.sclouds.effect.consts;

/**
 * Created by zhouwen on 2020/4/9.
 */
public interface EffectConst {
    /**
     * 特效类型
     */
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
}
