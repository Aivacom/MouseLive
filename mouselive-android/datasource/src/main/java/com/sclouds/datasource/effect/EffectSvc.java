package com.sclouds.datasource.effect;

import android.content.Context;

import com.sclouds.datasource.effect.bean.BeautyOption;
import com.thunder.livesdk.ThunderEngine;

/**
 * @author xipeitao
 * @description: 美颜模块，可选择性的加载
 * @date : 2020/6/17 9:46 AM
 */
public class EffectSvc implements IEffect{

    private static final String TAG = "EffectModule";


    private IEffect mIEffectImpl;

    private static EffectSvc sInstance;
    private Context mContext;
    private ThunderEngine mThunderEngine;
    private String mSerialNumber;
    private boolean isInited;
    private boolean isRegisted;

    private EffectSvc() {
    }

    public static void loadIfNeed() {
        Class<?> threadClazz = null;
        try {
            threadClazz = Class.forName("com.sclouds.effectadapter.JoEffect");
            threadClazz.newInstance();
        } catch (ClassNotFoundException e) {
            e.printStackTrace();
        } catch (IllegalAccessException e) {
            e.printStackTrace();
        } catch (InstantiationException e) {
            e.printStackTrace();
        }
    }

    public boolean isEnable() {
        return mIEffectImpl == null;
    }

    public void setEnable(IEffect effect) {
        if (effect == null) {
            effect = new EmptyEffect();
        } else {
            if (isInited) {
                effect.init(mContext, mThunderEngine, mSerialNumber);
                if (isRegisted) effect.register();
            }
        }
        this.mIEffectImpl = effect;
    }

    public static synchronized EffectSvc getInstance() {
        if (sInstance == null)
            sInstance = new EffectSvc();
        return sInstance;
    }

    @Override
    public synchronized void init(Context context, ThunderEngine thunderEngine, String serialNumber) {
        mContext = context;
        mThunderEngine = thunderEngine;
        mSerialNumber = serialNumber;
        if (mIEffectImpl != null)
            mIEffectImpl.init(context,thunderEngine,serialNumber);
        isInited = true;
    }



    @Override
    public synchronized void register() {
        if (mIEffectImpl != null)
            mIEffectImpl.register();
        isRegisted = true;

    }

    @Override
    public synchronized void unRegister() {
        if (mIEffectImpl != null)
            mIEffectImpl.unRegister();
        isRegisted = false;
    }

    @Override
    public void setDefaultBeautyEffect(String defBeautyPath) {
        if (mIEffectImpl != null)
            mIEffectImpl.setDefaultBeautyEffect(defBeautyPath);
    }

    @Override
    public BeautyOption getBeautyOption(int optionType, String optionName) {
        if (mIEffectImpl != null)
            return mIEffectImpl.getBeautyOption(optionType,optionName);
        return null;
    }

    @Override
    public void setBeautyOptionValue(int optionType, String optionName, int value) {
        if (mIEffectImpl != null)
            mIEffectImpl.setBeautyOptionValue(optionType,optionName,value);
    }

    @Override
    public void setEffectWithType(String type, String effectPath) {
        if (mIEffectImpl != null)
            mIEffectImpl.setEffectWithType(type,effectPath);
    }

    @Override
    public void closeAllGestureEffect() {
        if (mIEffectImpl != null)
            mIEffectImpl.closeAllGestureEffect();
    }

    @Override
    public void setBeautyEffectEnable(boolean enable) {
        if (mIEffectImpl != null)
            mIEffectImpl.setBeautyEffectEnable(enable);
    }

    @Override
    public void setFilterIntensity(int value) {
        if (mIEffectImpl != null)
            mIEffectImpl.setFilterIntensity(value);
    }

    @Override
    public boolean isBeautyReady() {
        if (mIEffectImpl != null)
           return mIEffectImpl.isBeautyReady();
        return false;
    }

    @Override
    public boolean isFilterReady() {
        if (mIEffectImpl != null)
            return mIEffectImpl.isFilterReady();
        return false;
    }
}
