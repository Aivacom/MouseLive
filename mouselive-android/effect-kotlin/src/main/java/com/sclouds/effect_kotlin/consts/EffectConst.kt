package com.sclouds.effect_kotlin.consts

/**
 * Created by zhouwen on 2020/4/22
 */
interface EffectConst {
    /**
     * 特效类型
     */
    interface Effect {
        companion object {
            /**
             * 美颜
             */
            const val EFFECT_BEAUTY = "beauty"

            /**
             * 滤镜
             */
            const val EFFECT_FILTER = "filter"

            /**
             * 贴纸
             */
            const val EFFECT_STICKER = "sticker"

            /**
             * 一个手势
             */
            const val EFFECT_GESTURE = "gesture"

            /**
             * 一组手势
             */
            const val EFFECT_GESTURES = "gestures"
        }
    }

    /**
     * 手势特效子类型：点赞，单手比心，双手比心，666，手掌，比V，OK
     */
    interface GestureEffectType {
        companion object {
            /**
             * 点赞
             */
            const val GESTURE_GOOD = "gesture_thumbsup"

            /**
             * 单手比心
             */
            const val GESTURE_SINGLE_LOVE = "gesture_onehandheart"

            /**
             * 双手比心
             */
            const val GESTURE_DOUBLE_LOVE = "gesture_twohandheart"

            /**
             * 666
             */
            const val GESTURE_SIX = "gesture_666"

            /**
             * 手掌
             */
            const val GESTURE_HAND = "gesture_palm"

            /**
             * 比V
             */
            const val GESTURE_V = "gesture_yeah"

            /**
             * OK
             */
            const val GESTURE_OK = "gesture_ok"
        }
    }

    companion object {
        /**
         * orangeFilter sdk sn: 鉴权串
         */
        const val OF_SERIAL_NAMBER = "eeb85a58-6cc5-11ea-8247-b42e995a6c82"
    }
}