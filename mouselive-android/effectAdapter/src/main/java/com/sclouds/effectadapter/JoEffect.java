package com.sclouds.effectadapter;

import android.content.Context;

import com.sclouds.datasource.effect.EffectSvc;
import com.sclouds.datasource.effect.IEffect;
import com.sclouds.datasource.effect.bean.BeautyOption;
import com.sclouds.effect.Accelerometer;
import com.sclouds.effect.EffectManager;
import com.thunder.livesdk.ThunderEngine;

/**
 * @author xipeitao
 * @description:
 * @date : 2020/6/17 4:00 PM
 */
public class JoEffect implements IEffect {

    private Accelerometer mAccelerometer;

    public JoEffect() {
        EffectManager.getIns();

        EffectSvc.getInstance().setEnable(this);
    }

    @Override
    public void init(Context context, ThunderEngine thunderEngine, String serialNumber) {
        mAccelerometer = new Accelerometer(context);
        mAccelerometer.start();
        EffectManager.getIns().init(context,thunderEngine,serialNumber);
    }

    @Override
    public void register() {
        EffectManager.getIns().register();
    }

    @Override
    public void unRegister() {
        EffectManager.getIns().unRegister();
    }

    @Override
    public void setDefaultBeautyEffect(String defBeautyPath) {
        EffectManager.getIns().setDefaultBeautyEffect(defBeautyPath);
    }

    @Override
    public BeautyOption getBeautyOption(int optionType, String optionName) {
        com.sclouds.effect.BeautyOption option =
                EffectManager.getIns().getBeautyOption(optionType,optionName);
        BeautyOption result = null;
        if (option != null){
            result = new BeautyOption();
            result.max = option.max;
            result.min = option.min;
            result.name = option.name;
            result.type = option.type;
            result.percent = option.percent;
            result.value = option.value;
        }
        return result;
    }

    @Override
    public void setBeautyOptionValue(int optionType, String optionName, int value) {
        EffectManager.getIns().setBeautyOptionValue(optionType,optionName,value);
    }

    @Override
    public void setEffectWithType(String type, String effectPath) {
        EffectManager.getIns().setEffectWithType(type,effectPath);
    }

    @Override
    public void closeAllGestureEffect() {
        EffectManager.getIns().closeAllGestureEffect();
    }

    @Override
    public void setBeautyEffectEnable(boolean enable) {
        EffectManager.getIns().setBeautyEffectEnable(enable);
    }

    @Override
    public void setFilterIntensity(int value) {
        EffectManager.getIns().setFilterIntensity(value);
    }

    @Override
    public boolean isBeautyReady() {
        return EffectManager.getIns().isBeautyReady();
    }

    @Override
    public boolean isFilterReady() {
        return EffectManager.getIns().isFilterReady();
    }
}
