package com.sclouds.datasource.flyservice.http.network;

import android.content.Context;
import android.net.ParseException;
import android.os.SystemClock;

import com.google.gson.JsonParseException;
import com.sclouds.basedroid.net.NetworkMgr;
import com.sclouds.basedroid.util.AppUtil;
import com.sclouds.datasource.flyservice.http.network.model.HttpResponse;

import org.apache.http.conn.ConnectTimeoutException;
import org.json.JSONException;

import java.net.ConnectException;

import io.reactivex.Observer;
import io.reactivex.disposables.Disposable;
import retrofit2.HttpException;

public abstract class BaseObserver<T> implements Observer<T> {

    private static final String TAG = BaseObserver.class.getSimpleName();
    private static long lastToastNetwork;
    private Context context;

    private static final int TOKENINVALID = 400;
    private static final int UNAUTHORIZED = 401;
    private static final int FORBIDDEN = 403;
    private static final int NOT_FOUND = 404;
    private static final int REQUEST_TIMEOUT = 408;
    private static final int INTERNAL_SERVER_ERROR = 500;
    private static final int BAD_GATEWAY = 502;
    private static final int SERVICE_UNAVAILABLE = 503;
    private static final int GATEWAY_TIMEOUT = 504;

    public BaseObserver(Context context) {
        this.context = context;
    }

    @Override
    public void onError(Throwable e) {
        e.printStackTrace();
        if (e instanceof CustomThrowable) {
            handleError((CustomThrowable) e);
        } else {
            handleError(tranlateError(e));
        }
    }

    private CustomThrowable tranlateError(Throwable e) {
        CustomThrowable ex;
        if (!NetworkMgr.isNetworkConnected(context)) {
            ex = new CustomThrowable(CustomError.NETWORK_DISCONNECT, "网络开小差啦，请检查下");
            return ex;
        } else if (e instanceof HttpException) {
            HttpException httpException = (HttpException) e;
            ex = new CustomThrowable(e, CustomError.HTTP_ERROR);
            switch (httpException.code()) {
                case TOKENINVALID:
                case UNAUTHORIZED:
                case FORBIDDEN:
                case NOT_FOUND:
                case REQUEST_TIMEOUT:
                case GATEWAY_TIMEOUT:
                case INTERNAL_SERVER_ERROR:
                case BAD_GATEWAY:
                case SERVICE_UNAVAILABLE:
                default:
                    ex.message = "网络开小差啦，请检查下";
                    break;
            }
            return ex;
        } else if (e instanceof JsonParseException
                || e instanceof JSONException
                || e instanceof ParseException) {
            ex = new CustomThrowable(e, CustomError.PARSE_ERROR);
            ex.message = "网络开小差啦，请检查下";
            return ex;
        } else if (e instanceof ConnectException) {
            ex = new CustomThrowable(e, CustomError.NETWORK_ERROR);
            ex.message = "网络开小差啦，请检查下";
            return ex;
        } else if (e instanceof javax.net.ssl.SSLHandshakeException) {
            ex = new CustomThrowable(e, CustomError.SSL_ERROR);
            ex.message = "证书验证失败";
            return ex;
        } else if (e instanceof ConnectTimeoutException) {
            ex = new CustomThrowable(e, CustomError.TIMEOUT_ERROR);
            ex.message = "网络开小差啦，请检查下";
            return ex;
        } else if (e instanceof java.net.SocketTimeoutException) {
            ex = new CustomThrowable(e, CustomError.TIMEOUT_ERROR);
            ex.message = "网络开小差啦，请检查下";
            return ex;
        } else {
            ex = new CustomThrowable(e, CustomError.UNKNOWN);
            ex.message = "网络开小差啦，请检查下";
            return ex;
        }
    }

    @Override
    public void onSubscribe(Disposable d) {
        if (!NetworkMgr.isNetworkConnected(context)) {
            onError(new CustomThrowable(CustomError.NETWORK_DISCONNECT, "网络开小差啦，请检查下"));
        }
    }

    @Override
    public void onNext(T t) {
        if (t instanceof HttpResponse) {
            HttpResponse httpResponse = (HttpResponse) t;
            if (httpResponse.isSuccessful()) {
                handleSuccess(t);
                return;
            }
            int errorCode = Integer.valueOf(httpResponse.Code);
            if (errorCode == 401) {
                // TODO: 2020-03-09 token err
            }
            handleError(new CustomThrowable(errorCode, httpResponse.Msg));
        } else {
            handleSuccess(t);
        }
    }

    @Override
    public void onComplete() {

    }

    public boolean needShowToast() {
        return true;
    }

    public void handleError(CustomThrowable e) {
        if ((e == null || e.code != 401)
                && needShowToast()
                && AppUtil.isScreenOn(context)
                && AppUtil.isAppForeground(context)) {
            if (!NetworkMgr.isNetworkConnected(context)) {
                if (lastToastNetwork > 0 &&
                        SystemClock.elapsedRealtime() - lastToastNetwork <= 2000L) {
                    return;
                }
                lastToastNetwork = SystemClock.elapsedRealtime();
            }
        }
    }

    public abstract void handleSuccess(T t);

}