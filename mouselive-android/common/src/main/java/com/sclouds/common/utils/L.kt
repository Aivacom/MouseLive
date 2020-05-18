package com.sclouds.datasource.of.utils

import android.util.Log

/**
 * Created by zhouwen on 2020/02/24.
 * Description: log debug
 */
object L {
    var DEBUG = true
    /**
     * log
     *
     * @param type tag's type
     * @param msg  message
     */
    private fun log(type: Int, msg: String) {
        if (!DEBUG) {
            return
        }
        val tag = stackTraceInfo
        when (type) {
            Log.DEBUG -> Log.d(tag, msg)
            Log.INFO -> Log.i(tag, msg)
            Log.VERBOSE -> Log.v(tag, msg)
            Log.ERROR -> Log.e(tag, msg)
            Log.WARN -> Log.w(tag, msg)
        }
    }

    /**
     * debug
     *
     * @param msg     message
     * @param objects objects
     */
    fun d(msg: String, vararg objects: Any?) {
        if (objects == null) {
            log(Log.DEBUG, msg)
        } else {
            log(Log.DEBUG, String.format(msg, *objects))
        }
    }

    /**
     * info
     *
     * @param msg     message
     * @param objects objects
     */
    fun i(msg: String, vararg objects: Any?) {
        if (objects == null) {
            log(Log.INFO, msg)
        } else {
            log(Log.INFO, String.format(msg, *objects))
        }
    }

    /**
     * verbose
     *
     * @param msg     message
     * @param objects objects
     */
    fun v(msg: String, vararg objects: Any?) {
        if (objects == null) {
            log(Log.VERBOSE, msg)
        } else {
            log(Log.VERBOSE, String.format(msg, *objects))
        }
    }

    /**
     * error
     *
     * @param msg     message
     * @param objects objects
     */
    @JvmStatic
    open fun e(msg: String, vararg objects: Any?) {
        if (objects == null) {
            log(Log.ERROR, msg)
        } else {
            log(Log.ERROR, String.format(msg, *objects))
        }
    }

    /**
     * warn
     *
     * @param msg     message
     * @param objects objects
     */
    fun w(msg: String, vararg objects: Any?) {
        if (objects == null) {
            log(Log.WARN, msg)
        } else {
            log(Log.WARN, String.format(msg, *objects))
        }
    }

    val stackTraceInfo: String
        get() {
            val stackTrace =
                Thread.currentThread().stackTrace[5]
            val className = stackTrace.className
            return className.substring(className.lastIndexOf('.') + 1) + ">>" + stackTrace.methodName + "#" + stackTrace.lineNumber
        }
}