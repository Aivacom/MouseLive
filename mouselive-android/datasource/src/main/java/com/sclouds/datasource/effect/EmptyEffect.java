package com.sclouds.datasource.effect;

import android.content.Context;

import com.sclouds.datasource.effect.bean.BeautyOption;
import com.thunder.livesdk.ThunderEngine;

/**
 * @author xipeitao
 * @description:
 * @date : 2020/6/17 11:39 AM
 */
class EmptyEffect implements IEffect {
    @Override
    public void init(Context context, ThunderEngine mThunderEngine, String serialNumber) {

    }

    @Override
    public void register() {

    }

    @Override
    public void unRegister() {

    }

    @Override
    public void setDefaultBeautyEffect(String defBeautyPath) {

    }

    @Override
    public BeautyOption getBeautyOption(int optionType, String optionName) {
        return null;
    }

    @Override
    public void setBeautyOptionValue(int optionType, String optionName, int value) {

    }

    @Override
    public void setEffectWithType(String type, String effectPath) {

    }

    @Override
    public void closeAllGestureEffect() {

    }

    @Override
    public void setBeautyEffectEnable(boolean enable) {

    }

    @Override
    public void setFilterIntensity(int value) {

    }

    @Override
    public boolean isBeautyReady() {
        return false;
    }

    @Override
    public boolean isFilterReady() {
        return false;
    }
}
