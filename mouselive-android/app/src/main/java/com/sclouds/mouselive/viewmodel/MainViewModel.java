package com.sclouds.mouselive.viewmodel;

import android.app.Application;
import android.os.Build;

import com.sclouds.basedroid.BaseViewModel;
import com.sclouds.basedroid.IBaseView;
import com.sclouds.basedroid.Tools;
import com.sclouds.datasource.TokenGetter;
import com.sclouds.datasource.bean.User;
import com.sclouds.datasource.database.DatabaseSvc;
import com.sclouds.datasource.flyservice.http.FlyHttpSvc;
import com.sclouds.datasource.flyservice.http.network.BaseObserver;
import com.sclouds.datasource.flyservice.http.network.CustomThrowable;
import com.sclouds.datasource.flyservice.http.network.model.HttpResponse;
import com.sclouds.datasource.hummer.HummerSvc;
import com.sclouds.mouselive.Consts;
import com.sclouds.mouselive.utils.SampleSingleObserver;
import com.sclouds.mouselive.views.SettingFragment;

import java.util.UUID;

import androidx.annotation.NonNull;
import androidx.lifecycle.MutableLiveData;
import androidx.preference.PreferenceManager;
import io.reactivex.android.schedulers.AndroidSchedulers;

public class MainViewModel extends BaseViewModel {

    public static final int ERROR_NET = 1;
    public static final int ERROR_LOGIN_USER = ERROR_NET + 1;
    public static final int ERROR_LOGIN_HUMMER = ERROR_LOGIN_USER + 1;
    public MutableLiveData<Integer> mLiveDataError = new MutableLiveData<>();

    public MainViewModel(@NonNull Application application, @NonNull IBaseView mView) {
        super(application, mView);
    }

    @Override
    public void initData() {
        checkNetwork();
    }

    private void initSDK() {
        // 初始化聊天室功能模块
        HummerSvc.getInstance().ini(getApplication(), Consts.APPID, Consts.APP_SECRET);
    }

    /**
     * 检查网络状态，如果网络连接成功则进行登陆操作，否则弹框提示
     */
    public void checkNetwork() {
        if (Tools.networkConnected()) {
            initSDK();
            login();
        } else {
            mLiveDataError.postValue(ERROR_NET);
        }
    }

    /**
     * 获取用户业务信息并登陆 Hummer，仅供第三方参考，由第三方自己实现
     */
    public void login() {
        showLoading();

        User user = DatabaseSvc.getIntance().getLocalUser();
        String DevName =
                Build.BRAND + " " + Build.DEVICE + " " + Build.MODEL + " " + Build.VERSION.SDK_INT;
        String DevUUID =
                PreferenceManager.getDefaultSharedPreferences(getApplication()).getString("UUID",
                        UUID.randomUUID().toString());
        PreferenceManager.getDefaultSharedPreferences(getApplication()).edit()
                .putString("UUID", DevUUID)
                .apply();
        FlyHttpSvc.getInstance()
                .login(user == null ? 0 : user.getUid(), DevName, DevUUID, Consts.APPID,
                        Consts.APP_SECRET)
                .observeOn(AndroidSchedulers.mainThread())
                .compose(bindToLifecycle())
                .subscribe(new BaseObserver<HttpResponse<User>>(getApplication()) {
                    @Override
                    public void handleSuccess(HttpResponse<User> response) {
                        if (response.Data == null) {
                            hideLoading();
                            mLiveDataError.postValue(ERROR_LOGIN_USER);
                            return;
                        }

                        // 本地缓存用户信息
                        User user = response.Data;
                        DatabaseSvc.getIntance().insertUser(user);
                        TokenGetter.updateToken(user.getToken());

                        loginHummer(user);
                    }

                    public void handleError(CustomThrowable e) {
                        super.handleError(e);
                        hideLoading();
                        mLiveDataError.postValue(ERROR_LOGIN_USER);
                    }
                });
    }

    /**
     * 通过用户信息登陆 Hummer，仅供第三方参考，由第三方自己实现
     *
     * @param user 登陆用户
     */
    private void loginHummer(@NonNull User user) {
        HummerSvc.getInstance()
                .login(user.getUid(), SettingFragment.isChina(getApplication()),
                        user.getToken())
                .observeOn(AndroidSchedulers.mainThread())
                .compose(bindToLifecycle())
                .subscribe(new SampleSingleObserver<Integer>() {
                    @Override
                    public void onSuccess(Integer integer) {
                        hideLoading();
                        if (integer == 0) {
                            mLiveDataError.postValue(ERROR_LOGIN_HUMMER);
                        } else {
                            mLiveDataError.postValue(null);
                        }
                    }
                });
    }
}
