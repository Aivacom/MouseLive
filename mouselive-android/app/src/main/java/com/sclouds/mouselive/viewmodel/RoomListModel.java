package com.sclouds.mouselive.viewmodel;

import android.app.Application;

import com.sclouds.basedroid.BaseViewModel;
import com.sclouds.basedroid.IBaseView;
import com.sclouds.datasource.bean.Room;
import com.sclouds.datasource.bean.User;
import com.sclouds.datasource.database.DatabaseSvc;
import com.sclouds.datasource.flyservice.http.FlyHttpSvc;
import com.sclouds.datasource.flyservice.http.bean.RoomListBean;
import com.sclouds.datasource.flyservice.http.network.BaseObserver;
import com.sclouds.datasource.flyservice.http.network.CustomThrowable;
import com.sclouds.datasource.flyservice.http.network.model.HttpResponse;

import java.util.List;

import androidx.annotation.NonNull;
import androidx.lifecycle.LifecycleOwner;
import androidx.lifecycle.MutableLiveData;
import androidx.lifecycle.Observer;
import io.reactivex.android.schedulers.AndroidSchedulers;

/**
 * 房间列表
 */
public class RoomListModel extends BaseViewModel {

    private MutableLiveData<List<Room>> mRooms = new MutableLiveData<>();
    private int mRoomType = Room.ROOM_TYPE_LIVE;

    public RoomListModel(@NonNull Application application, @NonNull IBaseView mView,
                         int mRoomType) {
        super(application, mView);
        this.mRoomType = mRoomType;
    }

    public void observeRoomList(LifecycleOwner owner, Observer<List<Room>> observer) {
        mRooms.observe(owner, observer);
    }

    @Override
    public void initData() {

    }

    /**
     * 获取房间列表
     */
    public void getRoomList() {
        User user = DatabaseSvc.getIntance().getUser();
        if (user == null) {
            mRooms.postValue(null);
            return;
        }

        FlyHttpSvc.getInstance().getRoomList(user.getUid(), mRoomType, 0)
                .observeOn(AndroidSchedulers.mainThread())
                .compose(bindToLifecycle())
                .subscribe(new BaseObserver<HttpResponse<RoomListBean>>(getApplication()) {
                    @Override
                    public void handleSuccess(
                            HttpResponse<RoomListBean> roomListBeanHttpResponse) {
                        List<Room> list = roomListBeanHttpResponse.Data.getRoomList();
                        if (list == null) {
                            mRooms.setValue(null);
                            return;
                        }

                        mRooms.setValue(list);
                    }

                    @Override
                    public void handleError(CustomThrowable e) {
                        super.handleError(e);
                        mRooms.setValue(null);
                    }
                });
    }
}
