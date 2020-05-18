package com.sclouds.basedroid;

import com.yy.spidercrab.SCLog;
import com.yy.spidercrab.SCLogger;
import com.yy.spidercrab.manager.SCLogFileConfig;
import com.yy.spidercrab.model.SCLogLevel;
import com.yy.spidercrab.model.SCLogModule;

public final class LogUtils {
    private static final String MODULE_NAME = "MouseLive_android";
    private static final boolean DEBUG = BuildConfig.DEBUG;

    static {
        SCLog.addLogger(new SCLogger(new SCLogModule(MODULE_NAME), new FlyLogFormat(),
                new SCLogFileConfig()));
        SCLog.changeLogLevel(MODULE_NAME, SCLogLevel.VERBOSE);
    }

    public static void i(String tag, String log) {
        SCLog.i(MODULE_NAME, tag, null, null, 0, getDebugLog(tag,log));
    }

    public static void w(String tag, String log) {
        SCLog.w(MODULE_NAME, tag, null, null, 0, getDebugLog(tag,log));
    }

    public static void e(String tag, String log) {
        SCLog.e(MODULE_NAME, tag, null, null, 0, getDebugLog(tag,log));
    }

    public static void d(String tag, String log) {
        SCLog.d(MODULE_NAME, tag, null, null, 0, getDebugLog(tag,log));
    }

    public static void v(String tag, String log) {
        SCLog.i(MODULE_NAME, tag, null, null, 0, getDebugLog(tag,log));
    }

    public static void e(String tag, String log, Exception error) {
        SCLog.e(MODULE_NAME, tag, null, null, 0, getDebugLog(tag,log) + " exception: " + error.getMessage());
    }

    private static String getDebugLog(String tag,String log) {
        if (DEBUG)
            return tag+": "+log;
        else
            return log;
    }
}
