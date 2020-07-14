package com.sclouds.datasource.effect.bean;

import android.content.Context;

import com.sclouds.basedroid.LogUtils;
import com.sclouds.datasource.bean.Effect;
import com.sclouds.datasource.bean.EffectTab;
import com.sclouds.datasource.effect.EffectSvc;
import com.sclouds.datasource.event.EventEffectDowned;
import com.sclouds.datasource.flyservice.http.FlyHttpSvc;
import com.sclouds.datasource.flyservice.http.network.FileObserver;

import org.greenrobot.eventbus.EventBus;

import java.io.File;
import java.util.List;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.lifecycle.LifecycleOwner;
import androidx.lifecycle.MutableLiveData;
import androidx.lifecycle.Observer;

/**
 * 特效数据管理类
 * created by chenshibiao on 2020-04-21.
 */
public class EffectDataManager {

    private static final String TAG = EffectDataManager.class.getSimpleName();

    private static EffectDataManager mEffectDataManager;

    /**
     * 是否已经加载过数据
     */
    private boolean isLoadData = false;

    /**
     * 美颜默认值是否已经设置
     */
    private boolean isBeautyDefaultCompleted = false;

    private MutableLiveData<EffectTab> mLiveDataBeauty = new MutableLiveData<>();
    private MutableLiveData<EffectTab> mLiveDataFilter = new MutableLiveData<>();
    private MutableLiveData<EffectTab> mLiveDataEmojo = new MutableLiveData<>();
    private MutableLiveData<EffectTab> mLiveDataGesture = new MutableLiveData<>();

    public static EffectDataManager getIns() {
        if (mEffectDataManager == null) {
            synchronized (EffectDataManager.class) {
                if (mEffectDataManager == null) {
                    mEffectDataManager = new EffectDataManager();
                }
            }
        }

        return mEffectDataManager;
    }

    public boolean isLoadData() {
        return isLoadData;
    }

    public void loadData(Context context, @NonNull List<EffectTab> list) {
        for (EffectTab effectTab : list) {
            List<Effect> effects = effectTab.getIcons();
            for (int i = 0; i < effects.size(); i++) {
                Effect effect = effects.get(i);

                String md5 = effect.getMd5();
                String path =
                        context.getFilesDir().getAbsolutePath() + "/orangefilter/effects/" + md5 +
                                ".zip";
                effect.setPath(path);

                if ("Beauty".equals(effectTab.getGroupType()) ||
                        "Filter".equals(effectTab.getGroupType())) {
                    //美颜需要设置一个默认值，就设置第一个
                    boolean needSetDefault = ("Beauty".equals(effectTab.getGroupType()) && i == 0);
                    autoDownloadEffectData(context, effectTab, effect, needSetDefault);
                }
            }

            if ("Beauty".equals(effectTab.getGroupType())) {
                //美颜需要等设置默认值之后进行数据通知
            } else if ("Filter".equals(effectTab.getGroupType())) {
                mLiveDataFilter.postValue(effectTab);
            } else if ("Sticker".equals(effectTab.getGroupType())) {
                mLiveDataEmojo.postValue(effectTab);
            } else if ("Gesture".equals(effectTab.getGroupType())) {
                mLiveDataGesture.postValue(effectTab);
            }
        }
        isLoadData = true;
    }

    /**
     * 下载特效数据
     *
     * @param needSetDefault 美颜需要设置一个默认值，就设置第一个，必须提前设置好，在开始直播之前设置，否则不能正常使用美颜特效
     */
    private void autoDownloadEffectData(@NonNull Context context, @NonNull EffectTab effectTab,
                                        @NonNull Effect effect, boolean needSetDefault) {
        //已经存在，就不需要下载
        if (new File(effect.getPath()).exists()) {
            if ("Beauty".equals(effectTab.getGroupType()) && needSetDefault &&
                    !isBeautyDefaultCompleted) {

                EffectSvc.getInstance().setDefaultBeautyEffect(effect.getPath());
                isBeautyDefaultCompleted = true;
                mLiveDataBeauty.postValue(effectTab);
            }
            return;
        }

        FlyHttpSvc.getInstance().download(effect.getUrl())
                .subscribe(new FileObserver(context, new File(effect.getPath())) {

                    @Override
                    public void onError(Throwable e) {
                        LogUtils.e(TAG, effect.getName() + " 下载失败");
                    }

                    @Override
                    public void onComplete() {
                        LogUtils.d(TAG, effect.getName() + " 下载成功");
                        if ("Beauty".equals(effectTab.getGroupType()) && needSetDefault &&
                                !isBeautyDefaultCompleted) {
                            isBeautyDefaultCompleted = true;
                            EffectSvc.getInstance().setDefaultBeautyEffect(effect.getPath());
                            mLiveDataBeauty.postValue(effectTab);
                        }
                        EventBus.getDefault().post(new EventEffectDowned(effect));
                    }
                });
    }

    public void observeBeauty(@NonNull LifecycleOwner owner,
                              @NonNull Observer<EffectTab> observer) {
        mLiveDataBeauty.observe(owner, observer);
    }

    public void observeFilter(@NonNull LifecycleOwner owner,
                              @NonNull Observer<EffectTab> observer) {
        mLiveDataFilter.observe(owner, observer);
    }

    public void observeEmojo(@NonNull LifecycleOwner owner,
                             @NonNull Observer<EffectTab> observer) {
        mLiveDataEmojo.observe(owner, observer);
    }

    public void observeGesture(@NonNull LifecycleOwner owner,
                               @NonNull Observer<EffectTab> observer) {
        mLiveDataGesture.observe(owner, observer);
    }

    @Nullable
    public EffectTab getBeautyEffects() {
        return mLiveDataBeauty.getValue();
    }

    @Nullable
    public EffectTab getFilterEffects() {
        return mLiveDataFilter.getValue();
    }

    @Nullable
    public EffectTab getEmojoEffects() {
        return mLiveDataEmojo.getValue();
    }

    @Nullable
    public EffectTab getGestureEffects() {
        return mLiveDataGesture.getValue();
    }
}
