package com.sclouds.mouselive.adapters;

import android.content.Context;
import android.view.View;
import android.widget.ImageView;
import android.widget.ProgressBar;

import com.bumptech.glide.Glide;
import com.sclouds.basedroid.BaseAdapter;
import com.sclouds.basedroid.LogUtils;
import com.sclouds.datasource.flyservice.http.FlyHttpSvc;
import com.sclouds.datasource.flyservice.http.network.FileObserver;
import com.sclouds.mouselive.R;
import com.sclouds.datasource.effect.bean.Effect;
import com.sclouds.datasource.event.EventEffectDowned;
import com.sclouds.mouselive.viewmodel.BaseRoomViewModel;
import com.trello.rxlifecycle3.android.FragmentEvent;
import com.trello.rxlifecycle3.components.support.RxFragment;

import org.greenrobot.eventbus.EventBus;

import java.io.File;
import java.util.List;

import androidx.annotation.MainThread;
import androidx.annotation.NonNull;
import io.reactivex.android.schedulers.AndroidSchedulers;
import io.reactivex.schedulers.Schedulers;

/**
 * 手势adapter
 */
public class GesturePanelAdapter extends BaseAdapter<Effect, GesturePanelAdapter.ViewHolder> {

    public GesturePanelAdapter(Context context, @NonNull List<Effect> data) {
        super(context, data);
    }

    @Override
    protected int getLayoutId(int viewType) {
        return R.layout.item_effect_gesture;
    }

    @Override
    protected ViewHolder createViewHolder(@NonNull View itemView) {
        return new ViewHolder(itemView);
    }

    class ViewHolder extends BaseAdapter.BaseViewHolder<Effect> {

        private ImageView imageView;
        private ImageView downloadView;
        private ImageView backgoundView;
        private ImageView gouView;
        private ProgressBar loadingView;

        public ViewHolder(@NonNull View itemView) {
            super(itemView);
            imageView = itemView.findViewById(R.id.imgEffectGesture);
            downloadView = itemView.findViewById(R.id.imgEffectGestureDownload);
            backgoundView = itemView.findViewById(R.id.imgEffectGestureBg);
            gouView = itemView.findViewById(R.id.imgEffectGestureGou);
            loadingView = itemView.findViewById(R.id.imgEffectGestureLoading);
        }

        @Override
        protected void bind(@NonNull Effect effect) {
            if (effect.getThumb() == null) {
                Glide.with(mContext).load(R.mipmap.ic_effect_forbid).into(imageView);
                downloadView.setVisibility(View.GONE);
                backgoundView.setVisibility(View.GONE);
                gouView.setVisibility(View.GONE);
                loadingView.setVisibility(View.GONE);
            } else {
                Glide.with(mContext).load(effect.getThumb()).into(imageView);
                if (effect.getDownloadStatus() == Effect.DownloadStatus.Undownload) {
                    loadingView.setVisibility(View.GONE);
                    downloadView.setVisibility(View.VISIBLE);
                } else if (effect.getDownloadStatus() == Effect.DownloadStatus.Downloading) {
                    loadingView.setVisibility(View.VISIBLE);
                    downloadView.setVisibility(View.GONE);
                } else {
                    loadingView.setVisibility(View.GONE);
                    downloadView.setVisibility(View.GONE);
                }

                if (effect.isSelected()) {
                    backgoundView.setVisibility(View.VISIBLE);
                    gouView.setVisibility(View.VISIBLE);
                } else {
                    backgoundView.setVisibility(View.GONE);
                    gouView.setVisibility(View.GONE);
                }
            }
        }
    }

    @MainThread
    public void setSelect(int position, RxFragment rxFragment) {
        if (mData == null) {
            return;
        }

        Effect effect = mData.get(position);
        if (position == 0) {
            for (Effect effectTemp : mData) {
                effectTemp.setSelected(false);
            }

            notifyDataSetChanged();
            return;
        }

        effect.setSelected(!effect.isSelected());
        if (effect.getDownloadStatus() == Effect.DownloadStatus.Undownload) {
            effect.setDownloadStatus(Effect.DownloadStatus.Downloading);
            download(effect, rxFragment);
        }
        notifyDataSetChanged();
    }

    private void download(Effect effect, RxFragment rxFragment) {
        LogUtils.d(BaseRoomViewModel.TAG, effect.getName() + " download start");
        FlyHttpSvc.getInstance().download(effect.getUrl())
                .subscribeOn(Schedulers.io())
                .compose(rxFragment.bindUntilEvent(FragmentEvent.DESTROY))
                .observeOn(AndroidSchedulers.mainThread())
                .subscribe(new FileObserver(mContext, new File(effect.getPath())) {
                    @Override
                    public void onError(Throwable e) {
                        LogUtils.e(BaseRoomViewModel.TAG,
                                effect.getName() + " download onError " + e.getMessage());
                        effect.setDownloadStatus(Effect.DownloadStatus.Undownload);
                        notifyDataSetChanged();
                    }

                    @Override
                    public void onComplete() {
                        LogUtils.d(BaseRoomViewModel.TAG,
                                effect.getName() + " download onComplete");
                        effect.setDownloadStatus(Effect.DownloadStatus.Download);
                        notifyDataSetChanged();
                        EventBus.getDefault().post(new EventEffectDowned(effect));
                    }
                });
    }
}
