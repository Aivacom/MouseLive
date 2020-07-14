package com.sclouds.mouselive.views;

import android.view.View;

import com.sclouds.basedroid.BaseAdapter;
import com.sclouds.basedroid.BaseFragment;
import com.sclouds.datasource.bean.EffectTab;
import com.sclouds.mouselive.R;
import com.sclouds.mouselive.adapters.BeautyPanelAdapter;
import com.sclouds.mouselive.databinding.LayoutRoomStickerBinding;
import com.sclouds.datasource.event.EventEffectDowned;
import com.sclouds.datasource.effect.EffectSvc;
import com.sclouds.datasource.effect.IEffect;
import com.sclouds.datasource.effect.bean.Effect;
import com.sclouds.datasource.effect.bean.EffectDataManager;

import org.greenrobot.eventbus.EventBus;
import org.greenrobot.eventbus.Subscribe;
import org.greenrobot.eventbus.ThreadMode;

import java.io.File;
import java.util.ArrayList;
import java.util.List;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.util.ObjectsCompat;
import androidx.lifecycle.Observer;
import androidx.recyclerview.widget.GridLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

/**
 * 魔法特效-表情
 *
 * @author chenhengfei@yy.com
 * @since 2020/04/24
 */
public class EffectStickerFragmrnt extends BaseFragment<LayoutRoomStickerBinding>
        implements BaseAdapter.OnItemClickListener {

    private static final int DEFAULT_VALUE = -1;
    private static int selecteIndex = DEFAULT_VALUE;
    public static void reset() {
        selecteIndex = DEFAULT_VALUE;
    }

    @Nullable
    private BeautyPanelAdapter adapter;

    public static EffectStickerFragmrnt newInstance() {
        EffectStickerFragmrnt fragment = new EffectStickerFragmrnt();
        return fragment;
    }

    @Override
    public void initView(View view) {
        GridLayoutManager layoutManager =
                new GridLayoutManager(getContext(), 5, RecyclerView.VERTICAL, false);
        mBinding.rvEffectSticker.setLayoutManager(layoutManager);
    }

    @Override
    public void initData() {
        if (!EventBus.getDefault().isRegistered(this)) {
            EventBus.getDefault().register(this);
        }

        EffectDataManager.getIns().observeEmojo(this, new Observer<EffectTab>() {
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

        if (EffectDataManager.getIns().getEmojoEffects() != null) {
            loadData(EffectDataManager.getIns().getEmojoEffects());
        }
    }

    @Override
    public int getLayoutResId() {
        return R.layout.layout_room_sticker;
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
                if (new File(effect.getPath()).exists()) {
                    effect.setDownloadStatus(Effect.DownloadStatus.Download);
                } else {
                    effect.setDownloadStatus(Effect.DownloadStatus.Undownload);
                }

                list.add(effect);
            }
        }

        adapter = new BeautyPanelAdapter(getContext(), list, IEffect.Effect.EFFECT_STICKER);
        mBinding.rvEffectSticker.setAdapter(adapter);
        adapter.setOnItemClickListener(this);

        //加载之前设置数据
        adapter.setSelecteIndex(selecteIndex);
    }

    @Override
    public void onItemClick(View view, int position) {
        if (adapter == null) {
            return;
        }

        Effect effect = adapter.getDataAtPosition(position);
        if (effect == null) {
            return;
        }

        selecteIndex = position;

        if (position == 0) {
            //清空状态，传一个空字符串的path
            EffectSvc.getInstance().setEffectWithType(IEffect.Effect.EFFECT_STICKER, "");
        } else if (effect.getDownloadStatus() == Effect.DownloadStatus.Download) {
            EffectSvc.getInstance()
                    .setEffectWithType(IEffect.Effect.EFFECT_STICKER, effect.getPath());
        }
        adapter.selecteItem(position, this);
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
                    EffectSvc.getInstance()
                            .setEffectWithType(IEffect.Effect.EFFECT_STICKER, effect.getPath());
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
