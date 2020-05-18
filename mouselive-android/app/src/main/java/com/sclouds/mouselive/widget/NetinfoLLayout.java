package com.sclouds.mouselive.widget;

import android.content.Context;
import android.graphics.Color;
import android.util.AttributeSet;
import android.util.TypedValue;
import android.view.ViewGroup;
import android.widget.LinearLayout;
import android.widget.TextView;

import com.sclouds.datasource.bean.User;
import com.sclouds.mouselive.R;
import com.thunder.livesdk.ThunderNotification;
import com.thunder.livesdk.ThunderRtcConstant;

import androidx.annotation.Nullable;

/**
 * 网络码率日志界面封装
 *
 * @author Aslan chenhengfei@yy.com
 * @since 2020/03/01
 */
public class NetinfoLLayout extends LinearLayout {

    static String txq;
    static String rxq;
    static String strNetQuality1;
    static String strNetQuality2;
    static String strNetQuality3;
    static String strNetQuality4;
    static String strNetQuality5;
    static String strNetQuality6;
    static String strNetUnknow;

    private TextView uid;
    private TextView name;

    private TextView txnetQuality;//上行网络质量
    private TextView txQuality;//上行
    private TextView txQualityM;//上行

    private TextView rxnetQuality;//下行网络质量
    private TextView rxQuality;//下行
    private TextView rxQualityM;//下行

    private int textSize = 0;

    public NetinfoLLayout(Context context) {
        super(context);
        init();
    }

    public NetinfoLLayout(Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
        init();
    }

    public NetinfoLLayout(Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        init();
    }

    private void init() {
        textSize = getResources().getDimensionPixelSize(R.dimen.room_contributions_text_size);

        setOrientation(VERTICAL);

        uid = createTextView();
        addView(uid, ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.WRAP_CONTENT);
        name = createTextView();
        addView(name, ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.WRAP_CONTENT);

        //上行
        txnetQuality = createTextView();
        addView(txnetQuality, ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.WRAP_CONTENT);

        txQuality = createTextView();
        addView(txQuality, ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.WRAP_CONTENT);

        txQualityM = createTextView();
        addView(txQualityM, ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.WRAP_CONTENT);

        //下行
        rxnetQuality = createTextView();
        addView(rxnetQuality, ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.WRAP_CONTENT);

        rxQuality = createTextView();
        addView(rxQuality, ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.WRAP_CONTENT);

        rxQualityM = createTextView();
        addView(rxQualityM, ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.WRAP_CONTENT);

        txq = getContext().getString(R.string.bitrates_up);
        rxq = getContext().getString(R.string.bitrates_down);

        strNetQuality1 = getContext().getString(R.string.net_quality1);
        strNetQuality2 = getContext().getString(R.string.net_quality2);
        strNetQuality3 = getContext().getString(R.string.net_quality3);
        strNetQuality4 = getContext().getString(R.string.net_quality4);
        strNetQuality5 = getContext().getString(R.string.net_quality5);
        strNetQuality6 = getContext().getString(R.string.net_quality6);
        strNetUnknow = getContext().getString(R.string.net_unknown);

        this.txnetQuality.setVisibility(GONE);
        this.rxnetQuality.setVisibility(GONE);
        this.txQuality.setVisibility(GONE);
        this.txQualityM.setVisibility(GONE);
        this.rxQuality.setVisibility(GONE);
        this.rxQualityM.setVisibility(GONE);
    }

    private TextView createTextView() {
        TextView txt = new TextView(getContext());
        txt.setTextColor(Color.WHITE);
        txt.setTextSize(TypedValue.COMPLEX_UNIT_PX, textSize);
        txt.setPadding(0, 5, 0, 5);
        return txt;
    }

    public void setUser(User user) {
        uid.setText(String.valueOf(user.getUid()));
        name.setText(user.getNickName());
    }

    public void setNetworkInfo(int txquality, int rxquality) {
        this.txnetQuality.setVisibility(VISIBLE);
        this.rxnetQuality.setVisibility(VISIBLE);

        this.txnetQuality
                .setText(getContext().getString(R.string.net_quality, getQuality(txquality)));
        this.rxnetQuality
                .setText(getContext().getString(R.string.net_quality, getQuality(rxquality)));
    }

    private String getQuality(int quality) {
        if (quality == ThunderRtcConstant.NetworkQuality.THUNDER_QUALITY_UNKNOWN) {
            return strNetUnknow;
        } else if (quality == ThunderRtcConstant.NetworkQuality.THUNDER_QUALITY_EXCELLENT) {
            return strNetQuality1;
        } else if (quality == ThunderRtcConstant.NetworkQuality.THUNDER_QUALITY_GOOD) {
            return strNetQuality2;
        } else if (quality == ThunderRtcConstant.NetworkQuality.THUNDER_QUALITY_POOR) {
            return strNetQuality3;
        } else if (quality == ThunderRtcConstant.NetworkQuality.THUNDER_QUALITY_BAD) {
            return strNetQuality4;
        } else if (quality == ThunderRtcConstant.NetworkQuality.THUNDER_QUALITY_VBAD) {
            return strNetQuality5;
        } else if (quality == ThunderRtcConstant.NetworkQuality.THUNDER_QUALITY_DOWN) {
            return strNetQuality6;
        } else {
            return strNetUnknow;
        }
    }

    public void setRoomStats(@Nullable ThunderNotification.RoomStats stats) {
        if (stats == null) {
            return;
        }

        this.txQuality.setVisibility(VISIBLE);
        this.txQualityM.setVisibility(VISIBLE);
        this.rxQuality.setVisibility(VISIBLE);
        this.rxQualityM.setVisibility(VISIBLE);

        this.txQuality
                .setText(getContext().getString(R.string.bitrates_up, stats.txBitrate / 8192));
        this.txQualityM.setText(getContext()
                .getString(R.string.bitrates_m, stats.txAudioBitrate / 8192,
                        stats.txVideoBitrate / 8192));

        this.rxQuality
                .setText(getContext().getString(R.string.bitrates_down, stats.rxBitrate / 8192));
        this.rxQualityM.setText(getContext()
                .getString(R.string.bitrates_m, stats.rxAudioBitrate / 8192,
                        stats.rxVideoBitrate / 8192));
    }
}
