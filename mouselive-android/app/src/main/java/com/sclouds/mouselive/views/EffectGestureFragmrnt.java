package com.sclouds.mouselive.views;

import android.text.TextUtils;
import android.view.View;

import com.sclouds.basedroid.BaseAdapter;
import com.sclouds.basedroid.BaseFragment;
import com.sclouds.datasource.bean.EffectTab;
import com.sclouds.mouselive.R;
import com.sclouds.mouselive.adapters.GesturePanelAdapter;
import com.sclouds.datasource.effect.EffectSvc;
import com.sclouds.datasource.effect.IEffect;
import com.sclouds.datasource.effect.bean.Effect;
import com.sclouds.datasource.effect.bean.EffectDataManager;
import com.sclouds.mouselive.databinding.LayoutRoomGestureBinding;
import com.sclouds.datasource.event.EventEffectDowned;

import org.greenrobot.eventbus.EventBus;
import org.greenrobot.eventbus.Subscribe;
import org.greenrobot.eventbus.ThreadMode;

import java.io.File;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.util.ObjectsCompat;
import androidx.lifecycle.Observer;
import androidx.recyclerview.widget.GridLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

/**
 * 魔法特效-手势
 *
 * @author chenhengfei@yy.com
 * @since 2020/04/24
 */
public class EffectGestureFragmrnt extends BaseFragment<LayoutRoomGestureBinding>
        implements BaseAdapter.OnItemClickListener {

    private static Set<String> selected = new HashSet<>();

    public static void reset() {
        selected.clear();
    }

    @Nullable
    private GesturePanelAdapter adapter;

    public static EffectGestureFragmrnt newInstance() {
        EffectGestureFragmrnt fragment = new EffectGestureFragmrnt();
        return fragment;
    }

    @Override
    public void initView(View view) {
        GridLayoutManager layoutManager =
                new GridLayoutManager(getContext(), 5, RecyclerView.VERTICAL, false);
        mBinding.rvEffectGesture.setLayoutManager(layoutManager);
    }

    @Override
    public void initData() {
        if (!EventBus.getDefault().isRegistered(this)) {
            EventBus.getDefault().register(this);
        }

        EffectDataManager.getIns().observeGesture(this, new Observer<EffectTab>() {
            @Override
            public void onChanged(@Nullable EffectTab effectTab) {
                if (effectTab == null) {
                    if (adapter != null) {
                        adapter.clear();
                    }
                    return;
                }

                loadData(effectTab);
            }
        });

        if (EffectDataManager.getIns().getGestureEffects() != null) {
            loadData(EffectDataManager.getIns().getGestureEffects());
        }
    }

    @Override
    public int getLayoutResId() {
        return R.layout.layout_room_gesture;
    }

    private void loadData(@NonNull EffectTab effectTab) {
        List<Effect> list = new ArrayList<>();
        Effect effect = new Effect();
        effect.setName(getString(R.string.room_magic_original));
        effect.setDownloadStatus(Effect.DownloadStatus.Download);
        list.add(effect);

        List<com.sclouds.datasource.bean.Effect> effects = effectTab.getIcons();
        if (effects != null && !effects.isEmpty()) {
            for (com.sclouds.datasource.bean.Effect effectTemp : effects) {
                effect = new Effect(effectTemp);
                if (selected.contains(effect.getName())) {
                    effect.setSelected(true);
                } else {
                    effect.setSelected(false);
                }

                if (new File(effect.getPath()).exists()) {
                    effect.setDownloadStatus(Effect.DownloadStatus.Download);
                } else {
                    effect.setDownloadStatus(Effect.DownloadStatus.Undownload);
                }

                list.add(effect);
            }
        }

        adapter = new GesturePanelAdapter(getContext(), list);
        mBinding.rvEffectGesture.setAdapter(adapter);
        adapter.setOnItemClickListener(this);
    }

    @Override
    public void onItemClick(@NonNull View view, int position) {
        if (adapter == null) {
            return;
        }

        Effect effect = adapter.getDataAtPosition(position);
        if (effect == null) {
            return;
        }

        adapter.setSelect(position, this);

        if (position == 0) {
            //清除所有手势特效
            selected.clear();
            EffectSvc.getInstance().closeAllGestureEffect();
        } else if (effect.getDownloadStatus() == Effect.DownloadStatus.Download) {
            if (effect.isSelected()) {
                //设置单个手势
                selected.add(effect.getName());
                EffectSvc.getInstance().setEffectWithType(getType(effect), effect.getPath());
            } else {
                //取消单个手势
                selected.remove(effect.getName());
                EffectSvc.getInstance().setEffectWithType(getType(effect), "");
            }
        }
    }

    private String getType(Effect effect) {
        //类型
        if (TextUtils.equals(effect.getResourceTypeName(), "gesture_666")) {
            //666
            return IEffect.GestureEffectType.GESTURE_SIX;
        } else if (TextUtils.equals(effect.getResourceTypeName(), "gesture_ok")) {
            //OK
            return IEffect.GestureEffectType.GESTURE_OK;
        } else if (TextUtils.equals(effect.getResourceTypeName(), "gesture_onehandheart")) {
            //单手比芯
            return IEffect.GestureEffectType.GESTURE_SINGLE_LOVE;
        } else if (TextUtils.equals(effect.getResourceTypeName(), "gesture_palm")) {
            //手掌
            return IEffect.GestureEffectType.GESTURE_HAND;
        } else if (TextUtils.equals(effect.getResourceTypeName(), "gesture_thumbsup")) {
            //拇指点赞
            return IEffect.GestureEffectType.GESTURE_GOOD;
        } else if (TextUtils.equals(effect.getResourceTypeName(), "gesture_twohandheart")) {
            //双手比芯
            return IEffect.GestureEffectType.GESTURE_DOUBLE_LOVE;
        } else if (TextUtils.equals(effect.getResourceTypeName(), "gesture_yeah")) {
            //比V
            return IEffect.GestureEffectType.GESTURE_V;
        }
        return null;
    }

    @Subscribe(threadMode = ThreadMode.MAIN)
    public void onEventEffectDowned(EventEffectDowned event) {
        if (adapter == null) {
            return;
        }

        //特效下载完成后，进行设置
        int size = adapter.getItemCount();
        for (int i = 0; i < size; i++) {
            Effect effect = adapter.getDataAtPosition(i);
            if (effect == null) {
                return;
            }

            if (ObjectsCompat.equals(effect, event.getEffect())) {
                effect.setDownloadStatus(Effect.DownloadStatus.Download);
                adapter.notifyItemChanged(i);

                if (effect.isSelected()) {
                    selected.add(effect.getName());
                    EffectSvc.getInstance().setEffectWithType(getType(effect), effect.getPath());
                }
                return;
            }
        }
    }

    @Override
    public void onDestroy() {
        if (EventBus.getDefault().isRegistered(this)) {
            EventBus.getDefault().unregister(this);
        }
        super.onDestroy();
    }
}
