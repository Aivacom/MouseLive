package com.sclouds.mouselive.adapters;

import android.content.Context;
import android.graphics.Color;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.ProgressBar;
import android.widget.TextView;

import com.bumptech.glide.Glide;
import com.bumptech.glide.load.resource.bitmap.RoundedCorners;
import com.bumptech.glide.request.RequestOptions;
import com.sclouds.basedroid.BaseAdapter;
import com.sclouds.basedroid.LogUtils;
import com.sclouds.basedroid.util.AppUtil;
import com.sclouds.datasource.flyservice.http.FlyHttpSvc;
import com.sclouds.datasource.flyservice.http.network.FileObserver;
import com.sclouds.effect.consts.EffectConst;
import com.sclouds.mouselive.R;
import com.sclouds.mouselive.bean.effect.Effect;
import com.sclouds.mouselive.event.EventEffectDowned;
import com.sclouds.mouselive.viewmodel.BaseRoomViewModel;
import com.trello.rxlifecycle3.android.FragmentEvent;
import com.trello.rxlifecycle3.components.support.RxFragment;

import org.greenrobot.eventbus.EventBus;

import java.io.File;
import java.util.List;

import androidx.annotation.LayoutRes;
import androidx.annotation.MainThread;
import androidx.annotation.NonNull;

import io.reactivex.android.schedulers.AndroidSchedulers;
import io.reactivex.schedulers.Schedulers;

/**
 * 美颜adapter
 */
public class BeautyPanelAdapter extends BaseAdapter<Effect, BeautyPanelAdapter.ViewHolder> {

    private int selecteIndex = -1;

    private String type = EffectConst.Effect.EFFECT_BEAUTY;

    public BeautyPanelAdapter(Context context, List<Effect> data, String type) {
        super(context, data);
        this.type = type;
    }

    @LayoutRes
    @Override
    protected int getLayoutId(int viewType) {
        return R.layout.item_effect_beauty;
    }

    @NonNull
    @Override
    protected ViewHolder createViewHolder(@NonNull View itemView) {
        return new ViewHolder(itemView);
    }

    private RequestOptions roundOptions = new RequestOptions().transform(new RoundedCorners(10));

    class ViewHolder extends BaseAdapter.BaseViewHolder<Effect> {

        private ImageView imageView;
        private TextView textView;
        private ProgressBar loadingView;
        private ImageView downloadView;
        private ImageView backgoundView;
        private ImageView gouView;

        ViewGroup.MarginLayoutParams layoutParams;

        public ViewHolder(View itemView) {
            super(itemView);

            layoutParams = (ViewGroup.MarginLayoutParams) itemView.getLayoutParams();

            imageView = itemView.findViewById(R.id.imgEffectBeauty);
            textView = itemView.findViewById(R.id.tvEffectBeauty);
            loadingView = itemView.findViewById(R.id.imgEffectBeautyLoading);
            downloadView = itemView.findViewById(R.id.imgEffectBeautyDownload);
            backgoundView = itemView.findViewById(R.id.imgEffectBeautyBg);
            gouView = itemView.findViewById(R.id.imgEffectBeautyGou);
        }

        @Override
        protected void bind(@NonNull Effect effect) {
            if (effect.getThumb() == null) {
                downloadView.setVisibility(View.GONE);
                loadingView.setVisibility(View.GONE);
                backgoundView.setVisibility(View.GONE);

                if (type.equals(EffectConst.Effect.EFFECT_STICKER)) {
                    Glide.with(mContext).load(R.mipmap.ic_effect_forbid).apply(roundOptions)
                            .into(imageView);
                    layoutParams
                            .setMargins(AppUtil.dip2px(5), AppUtil.dip2px(15), AppUtil.dip2px(5),
                                    0);
                    textView.setVisibility(View.GONE);
                } else {
                    Glide.with(mContext).load(R.drawable.beauty_original).apply(roundOptions)
                            .into(imageView);
                    layoutParams.setMargins(AppUtil.dip2px(5), 0, AppUtil.dip2px(5), 0);
                    textView.setVisibility(View.VISIBLE);
//                    textView.setText(effect.getName());
                    setText(textView, effect);
                    textView.setTextColor(Color.parseColor("#FFFFFF"));
                }
            } else {
                if (type.equals(EffectConst.Effect.EFFECT_STICKER)) {
                    layoutParams
                            .setMargins(AppUtil.dip2px(5), AppUtil.dip2px(15), AppUtil.dip2px(5),
                                    0);
                    textView.setVisibility(View.GONE);
                } else {
                    layoutParams.setMargins(AppUtil.dip2px(5), 0, AppUtil.dip2px(5), 0);
                    textView.setVisibility(View.VISIBLE);
                }

//                textView.setText(effect.getName());
                setText(textView, effect);
                Glide.with(mContext).load(effect.getThumb()).apply(roundOptions).into(imageView);
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

                if (selecteIndex == getAdapterPosition()) {
                    backgoundView.setVisibility(View.VISIBLE);
                    textView.setTextColor(Color.parseColor("#30DDBD"));
                } else {
                    backgoundView.setVisibility(View.GONE);
                    textView.setTextColor(Color.parseColor("#FFFFFF"));
                }
            }
        }
    }

    public int getSelecteIndex() {
        return selecteIndex;
    }

    public void setSelecteIndex(int selecteIndex) {
        this.selecteIndex = selecteIndex;
    }

    @MainThread
    public void selecteItem(int position, RxFragment rxFragment) {
        if (mData == null) {
            return;
        }

        if (selecteIndex >= 0 && !mData.isEmpty()) {
            //还原之前选择
            Effect effect = mData.get(selecteIndex);
            effect.setSelected(false);
            notifyItemChanged(selecteIndex);
        }

        this.selecteIndex = position;

        Effect effect = mData.get(position);
        effect.setSelected(true);
        if (effect.getDownloadStatus() == Effect.DownloadStatus.Undownload) {
            effect.setDownloadStatus(Effect.DownloadStatus.Downloading);
            download(effect, rxFragment, position);
        }
        notifyDataSetChanged();
    }

    private void download(Effect effect, RxFragment rxFragment, int position) {
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

    private void setText(TextView tv, Effect effect) {
        switch (effect.getResourceTypeName()) {
            case "Opacity":
                tv.setText(mContext.getString(R.string.effect_skin));
                break;
            case "Intensity":
                tv.setText(mContext.getString(R.string.effect_whiten));
                break;
            case "ThinfaceIntensity":
                tv.setText(mContext.getString(R.string.effect_slim));
                break;
            case "SmallfaceIntensity":
                tv.setText(mContext.getString(R.string.effect_resize));
                break;
            case "SquashedFaceIntensity":
                tv.setText(mContext.getString(R.string.effect_cheek));
                break;
            case "ForeheadLiftingIntensity":
                tv.setText(mContext.getString(R.string.effect_forehead_height));
                break;
            case "WideForeheadIntensity":
                tv.setText(mContext.getString(R.string.effect_forehead_width));
                break;
            case "BigSmallEyeIntensity":
                tv.setText(mContext.getString(R.string.effect_eye_size));
                break;
            case "EyesOffset":
                tv.setText(mContext.getString(R.string.effect_distance));
                break;
            case "EyesRotationIntensity":
                tv.setText(mContext.getString(R.string.effect_slant));
                break;
            case "ThinNoseIntensity":
                tv.setText(mContext.getString(R.string.effect_slim_n));
                break;
            case "LongNoseIntensity":
                tv.setText(mContext.getString(R.string.effect_length));
                break;
            case "ThinNoseBridgeIntensity":
                tv.setText(mContext.getString(R.string.effect_bridge));
                break;
            case "ThinmouthIntensity":
                tv.setText(mContext.getString(R.string.effect_resize_m));
                break;
            case "MovemouthIntensity":
                tv.setText(mContext.getString(R.string.effect_position));
                break;
            case "ChinLiftingIntensity":
                tv.setText(mContext.getString(R.string.effect_chin));
                break;
            case "holiday":
                tv.setText(mContext.getString(R.string.effect_holiday));
                break;
            case "clear":
                tv.setText(mContext.getString(R.string.effect_clear));
                break;
            case "warm":
                tv.setText(mContext.getString(R.string.effect_warm));
                break;
            case "fresh":
                tv.setText(mContext.getString(R.string.effect_fresh));
                break;
            case "creamy":
                tv.setText(mContext.getString(R.string.effect_creamy));
                break;
            default:
                tv.setText(effect.getName());
                break;
        }
    }
}
