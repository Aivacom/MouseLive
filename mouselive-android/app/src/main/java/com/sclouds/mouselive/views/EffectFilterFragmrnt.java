package com.sclouds.mouselive.views;

import android.annotation.SuppressLint;
import android.os.Handler;
import android.os.HandlerThread;
import android.os.Message;
import android.view.MotionEvent;
import android.view.View;

import com.sclouds.basedroid.BaseAdapter;
import com.sclouds.basedroid.BaseFragment;
import com.sclouds.datasource.bean.EffectTab;
import com.sclouds.effect.BeautyOption;
import com.sclouds.effect.EffectManager;
import com.sclouds.effect.consts.EffectConst;
import com.sclouds.mouselive.R;
import com.sclouds.mouselive.adapters.BeautyPanelAdapter;
import com.sclouds.mouselive.bean.effect.Effect;
import com.sclouds.mouselive.bean.effect.EffectDataManager;
import com.sclouds.mouselive.databinding.LayoutRoomBeautyBinding;
import com.sclouds.mouselive.event.EventEffectDowned;
import com.sclouds.mouselive.event.EventLeaveRoom;
import com.warkiz.widget.IndicatorSeekBar;
import com.warkiz.widget.OnSeekChangeListener;
import com.warkiz.widget.SeekParams;

import org.greenrobot.eventbus.EventBus;
import org.greenrobot.eventbus.Subscribe;
import org.greenrobot.eventbus.ThreadMode;

import java.io.File;
import java.util.ArrayList;
import java.util.List;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.Size;
import androidx.core.util.ObjectsCompat;
import androidx.lifecycle.Observer;
import androidx.recyclerview.widget.LinearLayoutManager;

/**
 * 魔法特效-过滤
 *
 * @author chenhengfei@yy.com
 * @since 2020/04/24
 */
public class EffectFilterFragmrnt extends BaseFragment<LayoutRoomBeautyBinding>
        implements BaseAdapter.OnItemClickListener, View.OnClickListener {

    private static final int DEFAULT_VALUE = -1;
    //记住之前选择，退出房间重置
    private static int selecteIndex = DEFAULT_VALUE;

    public static void reset() {
        selecteIndex = DEFAULT_VALUE;
    }


    @Nullable
    private BeautyPanelAdapter adapter;

    public static EffectFilterFragmrnt newInstance() {
        EffectFilterFragmrnt fragment = new EffectFilterFragmrnt();
        return fragment;
    }

    @Override
    public void initView(View view) {
        mBinding.tvEffectBeautyDefault.setOnClickListener(this);

        LinearLayoutManager layoutManager =
                new LinearLayoutManager(getContext(), LinearLayoutManager.HORIZONTAL, false);
        mBinding.rvEffectBeauty.setLayoutManager(layoutManager);

        //滤镜滑动条
        mBinding.seekEffectBeauty.setOnSeekChangeListener(new OnSeekChangeListener() {
            @Override
            public void onSeeking(SeekParams seekParams) {
                if (!seekParams.fromUser) {
                    return;
                }

                if (adapter == null) {
                    return;
                }

                int selecteIndex = adapter.getSelecteIndex();
                if (selecteIndex >= 0 && EffectManager.getIns().isFilterReady()) {
                    Effect effect = adapter.getDataAtPosition(selecteIndex);
                    effect.getOption().value = seekParams.progress;
                    adapter.notifyItemChanged(selecteIndex);

                    Message message = Message.obtain();
                    message.arg1 = seekParams.progress;
                    message.obj = effect;
                    mHandler.sendMessage(message);
                }
            }

            @Override
            public void onStartTrackingTouch(IndicatorSeekBar seekBar) {

            }

            @Override
            public void onStopTrackingTouch(IndicatorSeekBar seekBar) {

            }
        });

        setOriginalTouch();
    }

    /**
     * 手指按住第一个“原图”取消所有效果
     */
    @SuppressLint("ClickableViewAccessibility")
    private void setOriginalTouch() {
        mBinding.ilOrginal.setOnTouchListener(new View.OnTouchListener() {
            @Override
            public boolean onTouch(View view, MotionEvent motionEvent) {
                if (adapter == null) {
                    return false;
                }

                final int action = motionEvent.getAction() & MotionEvent.ACTION_MASK;
                switch (action) {
                    case MotionEvent.ACTION_DOWN:
                        //关闭滤镜
                        EffectManager.getIns()
                                .setEffectWithType(EffectConst.Effect.EFFECT_FILTER, "");
                        break;
                    case MotionEvent.ACTION_UP:
                    case MotionEvent.ACTION_CANCEL:
                        //恢复打开滤镜
                        Effect effect = adapter.getDataAtPosition(selecteIndex);
                        EffectManager.getIns().setEffectWithType(EffectConst.Effect.EFFECT_FILTER,
                                effect.getPath());
                        break;
                    default:
                        break;
                }
                return true;
            }
        });
    }

    @Override
    public void initData() {
        if (!EventBus.getDefault().isRegistered(this)) {
            EventBus.getDefault().register(this);
        }

        startSeekThread();

        EffectDataManager.getIns().observeFilter(this, new Observer<EffectTab>() {
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

        if (EffectDataManager.getIns().getFilterEffects() != null) {
            loadData(EffectDataManager.getIns().getFilterEffects());
        }
    }

    @Override
    public int getLayoutResId() {
        return R.layout.layout_room_beauty;
    }

    /**
     * 滤镜选项恢复默认值
     * 滤镜默认值都是100，所以没有特殊取值
     */
    private void resetDefaultFilter() {
        if (adapter == null) {
            return;
        }

        int defaultValue = 100;

        if (selecteIndex >= 0) {
            Effect effect = adapter.getDataAtPosition(selecteIndex);
            effect.getOption().value = defaultValue;
            mBinding.seekEffectBeauty.setProgress(defaultValue);

            EffectManager.getIns().setFilterIntensity(defaultValue);
        }
    }

    private void loadData(@NonNull EffectTab effectTab) {
        List<Effect> list = new ArrayList<>();
        Effect effect = null;

        List<com.sclouds.datasource.bean.Effect> effects = effectTab.getIcons();
        if (effects != null && !effects.isEmpty()) {
            for (com.sclouds.datasource.bean.Effect effectTemp : effects) {
                effect = new Effect(effectTemp);
                if (new File(effect.getPath()).exists()) {
                    effect.setDownloadStatus(Effect.DownloadStatus.Download);
                } else {
                    effect.setDownloadStatus(Effect.DownloadStatus.Undownload);
                }

                BeautyOption option = new BeautyOption();
                option.type = effect.getOperationType();
                option.name = effect.getResourceTypeName();
                option.min = 0;
                option.max = 100;
                option.percent = 100;
                option.value = 100;

                effect.setOption(option);

                list.add(effect);
            }
        }

        adapter = new BeautyPanelAdapter(getContext(), list, EffectConst.Effect.EFFECT_FILTER);
        mBinding.rvEffectBeauty.setAdapter(adapter);
        adapter.setOnItemClickListener(this);

        //加载之前设置数据
        adapter.setSelecteIndex(selecteIndex);
        if (selecteIndex < 0) {
            mBinding.seekEffectBeauty.setEnabled(false);
            mBinding.tvEffectBeautyDefault.setEnabled(false);
        } else {
            mBinding.seekEffectBeauty.setEnabled(true);
            mBinding.tvEffectBeautyDefault.setEnabled(true);
            mBinding.seekEffectBeauty.setProgress(list.get(selecteIndex).getOption().value);
        }
    }

    @Override
    public void onItemClick(@NonNull View view, @Size(min = 0) int position) {
        if (adapter == null) {
            return;
        }

        Effect effect = adapter.getDataAtPosition(position);
        if (effect == null) {
            return;
        }

        if (effect.getDownloadStatus() == Effect.DownloadStatus.Download) {
            mBinding.seekEffectBeauty.setEnabled(true);
            mBinding.tvEffectBeautyDefault.setEnabled(true);

            BeautyOption option = effect.getOption();
            mBinding.seekEffectBeauty.setMax(option.max);
            mBinding.seekEffectBeauty.setMin(option.min);
            mBinding.seekEffectBeauty.setProgress(option.value);
            EffectManager.getIns()
                    .setEffectWithType(EffectConst.Effect.EFFECT_FILTER, effect.getPath());
        }
        adapter.selecteItem(position, this);
        selecteIndex = position;
    }

    @Override
    public void onClick(View v) {
        switch (v.getId()) {
            case R.id.tvEffectBeautyDefault:
                resetDefaultFilter();
                break;
            default:
                break;
        }
    }

    private HandlerThread mHandlerThread;
    private Handler mHandler;

    private void startSeekThread() {
        mHandlerThread = new HandlerThread("SeekThreadFilter");
        mHandlerThread.start();

        mHandler = new Handler(mHandlerThread.getLooper(), new Handler.Callback() {
            @Override
            public boolean handleMessage(@NonNull Message msg) {
                int progress = msg.arg1;
                Effect effect = (Effect) msg.obj;
                EffectManager.getIns().setFilterIntensity(progress);
                return false;
            }
        });
    }

    private void stopSeekThread() {
        if (mHandler != null) {
            mHandler.removeMessages(0);
        }

        if (mHandlerThread != null) {
            mHandlerThread.quit();
        }
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
                    mBinding.seekEffectBeauty.setEnabled(true);
                    mBinding.tvEffectBeautyDefault.setEnabled(true);

                    BeautyOption option = effect.getOption();
                    mBinding.seekEffectBeauty.setMax(option.max);
                    mBinding.seekEffectBeauty.setMin(option.min);
                    mBinding.seekEffectBeauty.setProgress(option.value);
                    EffectManager.getIns()
                            .setEffectWithType(EffectConst.Effect.EFFECT_FILTER, effect.getPath());
                }
                return;
            }
        }
    }

    @Override
    public void onDestroy() {
        stopSeekThread();

        if (EventBus.getDefault().isRegistered(this)) {
            EventBus.getDefault().unregister(this);
        }
        super.onDestroy();
    }
}
