package com.sclouds.mouselive.bean.effect;

import com.sclouds.effect.BeautyOption;

public class Effect extends com.sclouds.datasource.bean.Effect {
    public enum DownloadStatus {
        Undownload, Downloading, Download
    }

    private DownloadStatus mDownloadStatus = DownloadStatus.Undownload;
    private boolean isSelected = false;
    private BeautyOption option;

    public Effect() {
        super();
    }

    public Effect(com.sclouds.datasource.bean.Effect effect) {
        super(effect);
    }

    public DownloadStatus getDownloadStatus() {
        return mDownloadStatus;
    }

    public void setDownloadStatus(DownloadStatus downloadStatus) {
        mDownloadStatus = downloadStatus;
    }

    public boolean isSelected() {
        return isSelected;
    }

    public void setSelected(boolean selected) {
        isSelected = selected;
    }

    public BeautyOption getOption() {
        return option;
    }

    public void setOption(BeautyOption option) {
        this.option = option;
    }
}
