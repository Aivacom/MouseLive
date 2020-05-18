package com.sclouds.common;

import android.content.Context;

/**
 * Created by zhouwen on 2020/4/9.
 */
public class AppContextUtil {

    private static Context mContext;

    public static void setContext(Context context){
        mContext = context;
    }

    public static Context getAppContext(){
        return mContext;
    }
}
