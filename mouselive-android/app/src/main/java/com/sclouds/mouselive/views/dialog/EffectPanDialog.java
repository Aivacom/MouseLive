package com.sclouds.mouselive.views.dialog;

import android.os.Bundle;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.view.Window;
import android.view.WindowManager;

import com.sclouds.basedroid.BaseDataBindDialog;
import com.sclouds.basedroid.ToastUtil;
import com.sclouds.datasource.bean.EffectTab;
import com.sclouds.datasource.flyservice.http.FlyHttpSvc;
import com.sclouds.datasource.flyservice.http.network.BaseObserver;
import com.sclouds.datasource.flyservice.http.network.CustomThrowable;
import com.sclouds.mouselive.R;
import com.sclouds.mouselive.adapters.MagicDialogPagerAdapter;
import com.sclouds.datasource.effect.bean.EffectDataManager;
import com.sclouds.mouselive.databinding.LayoutRoomFaceMenuBinding;
import com.sclouds.mouselive.views.EffectBeautyFragmrnt;
import com.sclouds.mouselive.views.EffectFilterFragmrnt;
import com.sclouds.mouselive.views.EffectGestureFragmrnt;
import com.sclouds.mouselive.views.EffectStickerFragmrnt;
import com.trello.rxlifecycle3.android.FragmentEvent;

import java.util.List;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.FragmentManager;
import io.reactivex.android.schedulers.AndroidSchedulers;

/**
 * 特效窗口
 */
public class EffectPanDialog extends BaseDataBindDialog<LayoutRoomFaceMenuBinding> {

    private static final String TAG = EffectPanDialog.class.getSimpleName();
    public static final String TAG_VERSION = "v0.1.0";

    public void show(@NonNull FragmentManager manager) {
        super.show(manager, TAG);
    }

    @Override
    public int getLayoutResId() {
        return R.layout.layout_room_face_menu;
    }

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
                             @Nullable Bundle savedInstanceState) {
        Window win = getDialog().getWindow();
        WindowManager.LayoutParams params = win.getAttributes();
        params.gravity = Gravity.BOTTOM;
        params.width = ViewGroup.LayoutParams.MATCH_PARENT;
        params.height = ViewGroup.LayoutParams.WRAP_CONTENT;
        win.setAttributes(params);
        return super.onCreateView(inflater, container, savedInstanceState);
    }

    @Override
    public void initView(View view) {
        mBinding.tvLoading.setVisibility(View.VISIBLE);
        mBinding.tabLayout.setVisibility(View.INVISIBLE);
        mBinding.vpMagicDialog.setVisibility(View.INVISIBLE);
    }

    @Override
    public void initData() {
        if (EffectDataManager.getIns().isLoadData()) {
            setAdapter();
        } else {
            loadEffectList(0);
        }
    }

    private void setAdapter() {
        mBinding.tvLoading.setVisibility(View.GONE);
        mBinding.tabLayout.setVisibility(View.VISIBLE);
        mBinding.vpMagicDialog.setVisibility(View.VISIBLE);

        MagicDialogPagerAdapter adapter =
                new MagicDialogPagerAdapter(getContext(), getChildFragmentManager());
        mBinding.vpMagicDialog.setAdapter(adapter);
        mBinding.tabLayout.setupWithViewPager(mBinding.vpMagicDialog);
    }

    private void loadEffectList(int retryCount) {
        mBinding.tvLoading.setVisibility(View.VISIBLE);
        showLoading(R.string.magic_load_data_loading);
        FlyHttpSvc.getInstance().getEffectList(TAG_VERSION)
                .observeOn(AndroidSchedulers.mainThread())
                .compose(bindUntilEvent(FragmentEvent.DESTROY))
                .subscribe(new BaseObserver<List<EffectTab>>(
                        getContext()) {
                    @Override
                    public void handleSuccess(@NonNull List<EffectTab> data) {
                        hideLoading();
                        mBinding.tvLoading.setVisibility(View.GONE);
                        if (data.isEmpty()) {
                            return;
                        }

                        EffectDataManager.getIns().loadData(getContext(), data);
                        setAdapter();
                    }

                    public void handleError(CustomThrowable e) {
                        super.handleError(e);
                        if (retryCount <= 3) {
                            loadEffectList(retryCount + 1);
                        } else {
                            hideLoading();
                            mBinding.tvLoading.setVisibility(View.GONE);
                            ToastUtil.showToast(getContext(), R.string.magic_load_data_fail);
                            dismiss();
                        }
                    }
                });
    }

    @Override
    public void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setStyle(STYLE_NORMAL, R.style.Dialog_Bottom_FullScreen);
    }

    public static void reset() {
        EffectBeautyFragmrnt.reset();
        EffectFilterFragmrnt.reset();
        EffectGestureFragmrnt.reset();
        EffectStickerFragmrnt.reset();
    }
}