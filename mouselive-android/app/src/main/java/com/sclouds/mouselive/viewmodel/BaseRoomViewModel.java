package com.sclouds.mouselive.viewmodel;

import android.annotation.SuppressLint;
import android.app.Application;
import android.os.Handler;
import android.text.TextUtils;

import com.google.gson.Gson;
import com.hummer.im.chatroom.ChatRoomInfo;
import com.hummer.im.model.chat.Content;
import com.hummer.im.model.chat.Message;
import com.hummer.im.model.id.ChatRoom;
import com.hummer.im.model.id.Identifiable;
import com.sclouds.basedroid.BaseViewModel;
import com.sclouds.basedroid.LogUtils;
import com.sclouds.basedroid.ToastUtil;
import com.sclouds.datasource.Callback;
import com.sclouds.datasource.TokenGetter;
import com.sclouds.datasource.bean.Room;
import com.sclouds.datasource.bean.RoomUser;
import com.sclouds.datasource.bean.User;
import com.sclouds.datasource.business.BusinessRepository;
import com.sclouds.datasource.business.pkg.BasePacket;
import com.sclouds.datasource.business.pkg.MicPacket;
import com.sclouds.datasource.business.pkg.RoomPacket;
import com.sclouds.datasource.database.DatabaseSvc;
import com.sclouds.datasource.flyservice.funws.FunWSClientHandler;
import com.sclouds.datasource.flyservice.funws.FunWSSvc;
import com.sclouds.datasource.flyservice.funws.listener.WSRoomListener;
import com.sclouds.datasource.flyservice.http.FlyHttpSvc;
import com.sclouds.datasource.flyservice.http.bean.GetChatIdBean;
import com.sclouds.datasource.flyservice.http.bean.GetRoomInfo;
import com.sclouds.datasource.flyservice.http.network.BaseObserver;
import com.sclouds.datasource.flyservice.http.network.CustomThrowable;
import com.sclouds.datasource.flyservice.http.network.model.HttpResponse;
import com.sclouds.datasource.hummer.HummerSvc;
import com.sclouds.datasource.hummer.SimpleChannelServiceListener;
import com.sclouds.datasource.thunder.SimpleThunderEventHandler;
import com.sclouds.datasource.thunder.ThunderSvc;
import com.sclouds.datasource.thunder.mode.ThunderConfig;
import com.sclouds.effect.EffectManager;
import com.sclouds.effect.consts.EffectConst;
import com.sclouds.mouselive.Consts;
import com.sclouds.mouselive.R;
import com.sclouds.mouselive.bean.FakeMessage;
import com.sclouds.mouselive.bean.PublicMessage;
import com.sclouds.mouselive.event.EventDeleteRoom;
import com.sclouds.mouselive.event.EventLeaveRoom;
import com.sclouds.mouselive.utils.RoomQueueAction;
import com.sclouds.mouselive.utils.SampleMaybeObserver;
import com.sclouds.mouselive.utils.SampleSingleObserver;
import com.sclouds.mouselive.view.IRoomView;
import com.sclouds.mouselive.views.SettingFragment;
import com.thunder.livesdk.ThunderEventHandler;
import com.thunder.livesdk.ThunderNotification;
import com.thunder.livesdk.ThunderRtcConstant;

import org.greenrobot.eventbus.EventBus;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

import androidx.annotation.CallSuper;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.UiThread;
import androidx.core.util.ObjectsCompat;
import androidx.lifecycle.LifecycleOwner;
import androidx.lifecycle.MutableLiveData;
import androidx.lifecycle.Observer;
import hugo.weaving.DebugLog;
import io.reactivex.Single;
import io.reactivex.android.schedulers.AndroidSchedulers;

/**
 * 封装了一些房间内的基本操作
 *
 * @author chenhengfei@yy.com
 * @since 2020/03/01
 */
public abstract class BaseRoomViewModel<V extends IRoomView> extends BaseViewModel<V>
        implements WSRoomListener {
    public static final String TAG = "[VM-Room]";

    private static final int ERROR_NO_LOGIN = 1;// 1
    private static final int ERROR_CREATE_HUMMER = ERROR_NO_LOGIN + 1;// 2
    private static final int ERROR_JOIN_HUMMER = ERROR_CREATE_HUMMER + 1;// 3
    private static final int ERROR_JOIN_THUNDER = ERROR_JOIN_HUMMER + 1;// 4
    private static final int ERROR_GET_CHAT_ID = ERROR_JOIN_THUNDER + 1;// 5
    private static final int ERROR_WS_JOIN = ERROR_GET_CHAT_ID + 1;// 6
    protected static final int ERROR_CDN = ERROR_WS_JOIN + 1;// 7
    private static final int ERROR_THUNDER = ERROR_CDN + 1;// 8

    /**
     * 成员缓存列表，因为sdk给出的只是一个uid，需要从服务器查询用户信息，然后缓存在内存里面。
     */
    protected Map<Long, RoomUser> memberCache = new ConcurrentHashMap<>();

    /**
     * 房间成员列表，同一个房间号才算。
     */
    protected ArrayList<RoomUser> members = new ArrayList<>();
    protected Set<Long> memberUserIds = new HashSet<>();

    /**
     * 房间信息
     */
    public MutableLiveData<Room> mLiveDataRoomInfo = new MutableLiveData<>();

    /**
     * 网络状态
     */
    public MutableLiveData<Integer> mLiveDataConnection = new MutableLiveData<>();

    /**
     * 错误信息
     */
    public MutableLiveData<Integer> mLiveDataError = new MutableLiveData<>();

    /**
     * 房间媒体RoomStats
     */
    public MutableLiveData<ThunderNotification.RoomStats> mLiveDataRoomStats =
            new MutableLiveData<>();

    /**
     * 正在执行窗口关闭操作
     */
    private boolean isClosing = false;

    @NonNull
    private Room mRoom;

    @NonNull
    private RoomUser mOwner;//当前房主

    @Nullable
    private RoomUser mMine;//当前手机用户

    protected Gson mGson = new Gson();

    protected BusinessRepository repository;

    private HMRChannelCallback mHMRChannelCallback;
    private ThunderCallback mThunderCallback;

    /**
     * 房间理管理员身份UserId集合
     */
    private HashSet<Long> admins = new HashSet<>();

    /**
     * 被禁言的成员UserId集合
     */
    private HashSet<Long> muteMemberUserIds = new HashSet<>();

    @Nullable
    private Handler mUIHandler = new Handler();

    //房间请求触发处理队列
    protected RoomQueueAction mRoomQueueAction = new RoomQueueAction();

    private boolean isJoinThunderCompleted = false;
    private boolean isJoinHummerCompleted = false;
    private boolean isSyncMembersCompleted = false;

    public BaseRoomViewModel(@NonNull Application application, @NonNull V mView,
                             @NonNull Room room) {
        super(application, mView);

        this.mRoom = room;
        mOwner = new RoomUser(room.getROwner(), room.getRoomId(), RoomUser.UserType.Remote);
        mOwner.setRoomRole(RoomUser.RoomRole.Owner);

        //当前账号
        User user = DatabaseSvc.getIntance().getUser();
        if (user == null) {
            mLiveDataError.postValue(ERROR_NO_LOGIN);
            return;
        }

        mMine = new RoomUser(user, room.getRoomId(), RoomUser.UserType.Local);
        if (ObjectsCompat.equals(mOwner, mMine)) {
            mMine.setRoomRole(RoomUser.RoomRole.Owner);
            mOwner = mMine;
        } else {
            mMine.setRoomRole(RoomUser.RoomRole.Spectator);
        }

        //初始化Thunder
        ThunderSvc.getInstance().create(getApplication(), Consts.APPID, Consts.APP_SECRET,
                SettingFragment.isChina(getApplication()), 0);
        ThunderSvc.getInstance().setThunderConfig(getThunderConfig());

        // 初始化 OrangeFilter sdk, serialNumber:of sdk鉴权序列号
        EffectManager.getIns().init(getApplication(), EffectConst.OF_SERIAL_NAMBER);
        mHMRChannelCallback = new HMRChannelCallback();
        mThunderCallback = new ThunderCallback();

        // 在需要是添加对应的事件监听器
        HummerSvc.getInstance().addRoomListener(mHMRChannelCallback);
        ThunderSvc.getInstance().addListener(mThunderCallback);
        FunWSSvc.getInstance().setListener(this);
    }

    @Override
    public void initData() {
        isClosing = false;

        if (getMine() != null) {
            joinRoom(mRoom);
        }
    }

    public void observeRequest(@NonNull LifecycleOwner owner,
                               @NonNull Observer<RoomQueueAction.Request> observer) {
        mRoomQueueAction.observe(owner, observer);
    }

    /**
     * 我是否正在连麦中，不包含房主。
     *
     * @return
     */
    public abstract boolean isInChating();

    /**
     * 当前用户是否在连麦中，不包含房主。
     *
     * @param user
     * @return
     */
    public abstract boolean isInChating(@NonNull RoomUser user);

    /**
     * 在连麦用户中，查找当前userId，如果有返回，如果没有返回null
     *
     * @param userId
     * @return
     */
    @Nullable
    public abstract RoomUser getChatingMember(long userId);

    @NonNull
    public Room getRoom() {
        return this.mRoom;
    }

    /**
     * 如果当前用户未登录，所以返回null
     *
     * @return
     */
    @Nullable
    public RoomUser getMine() {
        return mMine;
    }

    void doNextReuqest() {
        mRoomQueueAction.next();
    }

    void clearAllRequest() {
        mRoomQueueAction.clear();
    }

    @NonNull
    public RoomUser getOwnerUser() {
        return mOwner;
    }

    /**
     * 同步房间里的成员
     *
     * @param room
     */
    private synchronized void syncMembers(@NonNull Room room) {
        members.clear();
        memberUserIds.clear();

        RoomUser mine = getMine();
        if (mine == null) {
            mLiveDataError.postValue(ERROR_NO_LOGIN);
            return;
        }

        if (isRoomOwner()) {
            //房主
            mine.setRoomRole(RoomUser.RoomRole.Owner);
            if (members.contains(mine)) {
                members.set(members.indexOf(mine), mine);
            } else {
                members.add(mine);
                memberUserIds.add(mine.getUid());
            }
            memberCache.put(mine.getUid(), mine);
        } else {
            //房主
            if (members.contains(getOwnerUser())) {
                members.set(members.indexOf(getOwnerUser()), getOwnerUser());
            } else {
                members.add(getOwnerUser());
                memberUserIds.add(getOwnerUser().getUid());
            }
            memberCache.put(getOwnerUser().getUid(), getOwnerUser());

            //我
            if (admins.contains(mine.getUid())) {
                mine.setRoomRole(RoomUser.RoomRole.Admin);
            } else {
                mine.setRoomRole(RoomUser.RoomRole.Spectator);
            }

            if (members.contains(mine)) {
                members.set(members.indexOf(mine), mine);
            } else {
                members.add(mine);
                memberUserIds.add(mine.getUid());
            }
            memberCache.put(mine.getUid(), mine);
        }

        List<RoomUser> members = room.getMembers();
        if (members != null) {
            for (RoomUser member : members) {
                if (BaseRoomViewModel.this.members.contains(member)) {
                    //更新操作
                    int index = BaseRoomViewModel.this.members.indexOf(member);
                    RoomUser memberTemp = BaseRoomViewModel.this.members.get(index);
                    assert memberTemp != null;
                    memberTemp.setLinkRoomId(member.getLinkRoomId());
                    memberTemp.setLinkUid(member.getLinkUid());
                    memberTemp.setMicEnable(member.isMicEnable());
                    memberTemp.setSelfMicEnable(member.isSelfMicEnable());

                    memberTemp.setRoomId(room.getRoomId());
                    memberTemp.setNoTyping(room.isAllNoTyping());
                } else {
                    //增加操作
                    member.setRoomId(room.getRoomId());
                    member.setNoTyping(room.isAllNoTyping());

                    if (ObjectsCompat.equals(member, getOwnerUser())) {
                        member.setRoomRole(RoomUser.RoomRole.Owner);
                    } else if (admins.contains(member.getUid())) {
                        member.setRoomRole(RoomUser.RoomRole.Admin);
                    } else {
                        member.setRoomRole(RoomUser.RoomRole.Spectator);
                    }

                    if (ObjectsCompat.equals(member, mine)) {
                        member.setUserType(RoomUser.UserType.Local);
                    } else {
                        member.setUserType(RoomUser.UserType.Remote);
                    }

                    if (muteMemberUserIds.contains(member.getUid())) {
                        member.setNoTyping(true);
                    }

                    BaseRoomViewModel.this.members.add(member);
                    memberUserIds.add(member.getUid());
                    memberCache.put(member.getUid(), member);
                }
            }
        }

        room.setRCount(BaseRoomViewModel.this.members.size());
        onBasicInfoChanged(room);
        isSyncMembersCompleted = true;

        if (isJoinThunderCompleted && isJoinHummerCompleted && isSyncMembersCompleted) {
            onJoinRoomAllCompleted();
        }
    }

    /**
     * 加入房间所有的都执行完毕
     * 1：thunder 加入成功
     * 2：hummer 加入成功
     * 3：syncMember 同步成功
     */
    @UiThread
    @CallSuper
    protected void onJoinRoomAllCompleted() {
        //后进去房间的人，如果存在连麦，就加载连麦流程
        for (RoomUser member : members) {
            if (member.getLinkUid() != 0 && member.getLinkRoomId() != 0) {
                //有人正在连麦
                LogUtils.d(TAG, "onUserInChating() called with: member=" + member);
                onUserInChating(member);
            }
        }

        reJoinRoom = false;
    }

    private void getRoomInfo() {
        RoomUser mine = getMine();
        if (mine == null) {
            mLiveDataError.postValue(ERROR_NO_LOGIN);
            return;
        }

        FlyHttpSvc.getInstance()
                .getRoomInfo(mine.getUid(), getRoom().getRoomId(), getRoom().getRType())
                .observeOn(AndroidSchedulers.mainThread())
                .compose(bindToLifecycle())
                .subscribe(new BaseObserver<HttpResponse<GetRoomInfo>>(getApplication()) {
                    @Override
                    public void handleSuccess(HttpResponse<GetRoomInfo> response) {
                        if (response.Data == null) {
                            return;
                        }

                        Room room = response.Data.getRoomInfo();
                        room.setRMicEnable(getRoom().getRMicEnable());//这2个状态以hummer查询为准
                        room.setAllNoTyping(getRoom().isAllNoTyping());//这2个状态以hummer查询为准

                        if (room.getRType() != getRoom().getRType()) {
                            //主播已经离开了，已经结束了开播，就退出房间
                            mView.finish();
                            return;
                        }

                        if (reJoinRoom) {
                            //因为是重新进入房间的，所以需要重置所有信息
                            resetRoomInfo();
                        }

                        room.setMembers(response.Data.getUserList());
                        mRoom = room;
                        syncMembers(room);

                        if (reJoinRoom) {
                            //如果需要重新加入房间，就直接走加入房间流程
                            //进入聊天室和信令房间
                            if (getRoom().getRPublishMode() == Room.RTC || isRoomOwner()) {
                                joinThunder();
                            }

                            if (isRoomOwner()) {
                                //房主走加入逻辑
                                joinHummer(room.getRChatId(), 0);
                            } else {
                                //观众走加入逻辑
                                getChatRoomId(0);
                            }
                        }
                    }

                    @Override
                    public void handleError(CustomThrowable e) {
                        super.handleError(e);
                        if (e.code == 5042) {
                            //主播已经离开了，已经结束了开播，就退出房间
                            mView.finish();
                        }
                    }
                });
    }

    /**
     * 连麦对方的用户
     */
    protected abstract void onUserInChating(@NonNull RoomUser user);

    protected abstract ThunderConfig getThunderConfig();

    private void setChatID(long chatID) {
        RoomUser mine = getMine();
        if (mine == null) {
            mLiveDataError.postValue(ERROR_NO_LOGIN);
            return;
        }

        Room room = getRoom();
        FlyHttpSvc.getInstance()
                .setChatId(mine.getUid(), room.getRoomId(), room.getRType(), chatID)
                .compose(bindToLifecycle())
                .subscribe(new BaseObserver<HttpResponse<String>>(getApplication()) {
                    @Override
                    public void handleSuccess(HttpResponse<String> response) {

                    }

                    @Override
                    public void handleError(CustomThrowable e) {
                        super.handleError(e);
                        if (mUIHandler != null) {
                            mUIHandler.postDelayed(new Runnable() {
                                @Override
                                public void run() {
                                    setChatID(chatID);
                                }
                            }, 500L);
                        }
                    }
                });
    }

    /**
     * 加入房间
     *
     * @param room 房间信息
     */
    @DebugLog
    private void joinRoom(Room room) {
        LogUtils.d(TAG,
                "============================================joinRoom==============================================");
        LogUtils.d(TAG, "joinRoom() called with: room = [" + room + "] User = [" + mMine + "]");
        mLiveDataError.postValue(null);

        //先加入到thunder
        if (getRoom().getRPublishMode() == Room.RTC || isRoomOwner()) {
            joinThunder();
        }

        //进入聊天室和信令房间
        if (isRoomOwner()) {
            //房主走创建逻辑
            createChatRoomOnSDK();
        } else {
            //观众走加入逻辑
            getChatRoomId(0);
        }
    }

    public void cancelChat(long dstUid, long dstRid) {
        Room room = getRoom();
        FunWSSvc.getInstance()
                .cancelChat(dstUid, dstRid)
                .observeOn(AndroidSchedulers.mainThread())
                .compose(bindToLifecycle())
                .subscribe();
    }

    private void getChatRoomId(int retryCount) {
        RoomUser mine = getMine();
        if (mine == null) {
            mLiveDataError.postValue(ERROR_NO_LOGIN);
            return;
        }

        Room room = getRoom();
        FlyHttpSvc.getInstance().getChatId(mine.getUid(), room.getRoomId(), room.getRType())
                .compose(bindToLifecycle())
                .subscribe(new BaseObserver<HttpResponse<GetChatIdBean>>(getApplication()) {
                    @Override
                    public void handleSuccess(HttpResponse<GetChatIdBean> response) {
                        if (response.Data == null) {
                            if (retryCount <= 10) {
                                if (mUIHandler != null) {
                                    mUIHandler
                                            .postDelayed(() -> getChatRoomId(retryCount + 1), 500L);
                                }
                            } else {
                                mLiveDataError.postValue(ERROR_GET_CHAT_ID);
                            }
                        } else {
                            room.setRChatId(response.Data.getRChatId());
                            onBasicInfoChanged(room);

                            joinHummer(response.Data.getRChatId(), 0);
                        }
                    }
                });
    }

    private void joinHummer(Long chatRoomId, int retryCount) {
        RoomUser mine = getMine();
        if (mine == null) {
            mLiveDataError.postValue(ERROR_NO_LOGIN);
            return;
        }

        HummerSvc.getInstance().joinChannel(chatRoomId, mine.getUid())
                .observeOn(AndroidSchedulers.mainThread())
                .compose(bindToLifecycle())
                .subscribe(new SampleSingleObserver<Boolean>() {
                    @Override
                    public void onSuccess(Boolean aBoolean) {
                        if (aBoolean) {
                            HummerSvc.getInstance().addChatListener(mHMRChannelCallback);
                            fetchBasicInfo();

                            onJoinChatRoomSuccess();
                        } else {
                            if (retryCount <= 10) {
                                if (mUIHandler != null) {
                                    mUIHandler.postDelayed(
                                            () -> joinHummer(chatRoomId, retryCount + 1),
                                            500L);
                                }
                            } else {
                                mLiveDataError.postValue(ERROR_JOIN_HUMMER);
                            }
                        }
                    }
                });
    }

    private void fetchBasicInfo() {
        HummerSvc.getInstance().fetchBasicInfo()
                .observeOn(AndroidSchedulers.mainThread())
                .compose(bindToLifecycle())
                .subscribe(new SampleSingleObserver<ChatRoomInfo>() {
                    @Override
                    public void onSuccess(ChatRoomInfo chatRoomInfo) {
                        String AppExtra = chatRoomInfo.getAppExtra();
                        if (!TextUtils.isEmpty(AppExtra)) {
                            HummerSvc.RoomInfo roomInfo =
                                    mGson.fromJson(AppExtra, HummerSvc.RoomInfo.class);

                            Room room = getRoom();
                            room.setAllNoTyping(roomInfo.isAllMute());
                            room.setRMicEnable(!roomInfo.isAllMicOff());

                            for (RoomUser user : members) {
                                if (ObjectsCompat.equals(user, getOwnerUser())) {
                                    //房主不受房间全局属性影响
                                    continue;
                                }

                                user.setNoTyping(room.isAllNoTyping());
                                user.setMicEnable(room.getRMicEnable());
                            }

                            BaseRoomViewModel.this.onBasicInfoChanged(room);
                        }

                        fetchMutedMembers();
                        fetchRoleMembers();
                    }
                });
    }

    private void fetchMutedMembers() {
        HummerSvc.getInstance().fetchMutedMembers()
                .observeOn(AndroidSchedulers.mainThread())
                .compose(bindToLifecycle())
                .subscribe(new SampleMaybeObserver<Set<com.hummer.im.model.id.User>>() {
                    @Override
                    public void onSuccess(Set<com.hummer.im.model.id.User> users) {
                        muteMemberUserIds.clear();
                        for (com.hummer.im.model.id.User user : users) {
                            long ui = user.getId();
                            muteMemberUserIds.add(ui);
                        }

                        //同步到members中
                        for (RoomUser member : members) {
                            if (ObjectsCompat.equals(member, getOwnerUser())) {
                                continue;
                            }

                            boolean isNoTyping = false;
                            if (muteMemberUserIds.contains(member.getUid())) {
                                isNoTyping = true;
                            }

                            if (member.isNoTyping() != isNoTyping) {
                                member.setNoTyping(isNoTyping);
                            }
                        }
                    }
                });
    }

    private void fetchRoleMembers() {
        HummerSvc.getInstance().fetchRoleMembers()
                .observeOn(AndroidSchedulers.mainThread())
                .compose(bindToLifecycle())
                .subscribe(new SampleMaybeObserver<List<com.hummer.im.model.id.User>>() {
                    @Override
                    public void onSuccess(List<com.hummer.im.model.id.User> users) {
                        //管理员列表
                        admins.clear();
                        for (com.hummer.im.model.id.User user : users) {
                            long ui = user.getId();
                            admins.add(ui);
                        }

                        //同步到members中
                        for (RoomUser member : members) {
                            if (ObjectsCompat.equals(member, getOwnerUser())) {
                                continue;
                            }

                            if (admins.contains(member.getUid())) {
                                if (member.getRoomRole() != RoomUser.RoomRole.Admin) {
                                    member.setRoomRole(RoomUser.RoomRole.Admin);
                                }
                            }
                        }
                    }
                });
    }

    private void createChatRoomOnSDK() {
        Room room = getRoom();
        HummerSvc.getInstance().createRoom(room.getRName())
                .compose(bindToLifecycle())
                .subscribe(new SampleSingleObserver<Long>() {
                    @Override
                    public void onSuccess(Long chatRoomid) {
                        setChatID(chatRoomid);
                        room.setRChatId(chatRoomid);
                        onBasicInfoChanged(room);

                        joinHummer(chatRoomid, 0);
                    }

                    @Override
                    public void onError(Throwable e) {
                        super.onError(e);
                        mLiveDataError.postValue(ERROR_CREATE_HUMMER);
                    }
                });
    }

    /**
     * 加入thunder
     */
    private void joinThunder() {
        RoomUser mine = getMine();
        if (mine == null) {
            mLiveDataError.postValue(ERROR_NO_LOGIN);
            return;
        }

        Room room = getRoom();
        ThunderSvc.getInstance()
                .joinRoom(TokenGetter.getToken().getBytes(), room.getRoomId(), mine.getUid(),
                        new Callback() {
                            @Override
                            public void onSuccess() {
                                onJoinThunderSuccess();
                            }

                            @Override
                            public void onFailed(int error) {
                                if (error ==
                                        ThunderRtcConstant.ThunderRet.THUNDER_RET_ALREADY_JOIN_ROOM ||
                                        error ==
                                                ThunderRtcConstant.ThunderRet.THUNDER_RET_WRONG_JOIN_STATUS) {
                                    onJoinThunderSuccess();
                                } else {
                                    mLiveDataError.postValue(ERROR_JOIN_THUNDER);
                                }
                            }
                        });
    }

    /**
     * 加入Thunder成功
     */
    @UiThread
    @CallSuper
    protected void onJoinThunderSuccess() {
        isJoinThunderCompleted = true;
        if (isJoinThunderCompleted && isJoinHummerCompleted && isSyncMembersCompleted) {
            onJoinRoomAllCompleted();
        }
    }

    @Override
    protected void onCleared() {
        super.onCleared();
        isClosing = true;
        close();
    }

    @CallSuper
    protected void close() {
        resetRoomInfo();

        mUIHandler = null;
        FunWSSvc.getInstance().stop();
        HummerSvc.getInstance().leaveChannel(null);
        ThunderSvc.getInstance().leaveRoom(null);
        HummerSvc.getInstance().removeChatListener(mHMRChannelCallback);
        HummerSvc.getInstance().removeRoomListener(mHMRChannelCallback);
        ThunderSvc.getInstance().removeListener(mThunderCallback);
        FunWSSvc.getInstance().setListener(null);
        if (isRoomOwner()) {
            EventBus.getDefault().post(new EventDeleteRoom(getRoom()));
        }
        EventBus.getDefault().post(new EventLeaveRoom(getRoom()));
        LogUtils.d(TAG,
                "============================================leaveRoom==============================================");
    }

    /**
     * 初始化房间信息
     */
    @CallSuper
    protected void resetRoomInfo() {
        mLiveDataError.postValue(null);
        members.clear();
        memberUserIds.clear();
        admins.clear();
        muteMemberUserIds.clear();
    }

    /**
     * 禁言
     *
     * @return
     */
    public boolean isAllNoTyping() {
        Room room = getRoom();
        return room.isAllNoTyping();
    }

    /**
     * 全员闭麦
     *
     * @return
     */
    public boolean isAllMicEnable() {
        Room room = getRoom();
        return room.getRMicEnable();
    }

    /**
     * 判断我是不是房主
     *
     * @return
     */
    public boolean isRoomOwner() {
        return ObjectsCompat.equals(getOwnerUser(), getMine());
    }

    /**
     * 切换本地麦克风
     */
    @SuppressLint("CheckResult")
    public void toggleLocalMic() {
        RoomUser mine = getMine();
        if (mine == null) {
            mLiveDataError.postValue(ERROR_NO_LOGIN);
            return;
        }

        if (!mine.isMicEnable()) {
            //如果我被禁麦了，就不能操作
            return;
        }

        if (!isRoomOwner() && !isInChating()) {
            //如果观众不在连麦状态，就不能操作
            return;
        }

        if (mine.isSelfMicEnable()) {
            toggleThunderMic(false);
            mine.setSelfMicEnable(false);
            onAudioStop(mine);

            FunWSSvc.getInstance()
                    .enableRemoteMic(mine.getUid(), getRoom().getRType(), false)
                    .observeOn(AndroidSchedulers.mainThread())
                    .compose(bindToLifecycle())
                    .subscribe(aBoolean -> {
                        if (aBoolean) {

                        }
                    });
        } else {
            toggleThunderMic(true);
            mine.setSelfMicEnable(true);
            onAudioStart(mine);

            FunWSSvc.getInstance()
                    .enableRemoteMic(mine.getUid(), getRoom().getRType(), true)
                    .observeOn(AndroidSchedulers.mainThread())
                    .compose(bindToLifecycle())
                    .subscribe(aBoolean -> {
                        if (aBoolean) {

                        }
                    });
        }
    }

    /**
     * 禁麦操作，最终需要控制thunder去实现
     *
     * @param isEnable
     */
    protected void toggleThunderMic(boolean isEnable) {
        ThunderSvc.getInstance().toggleMicEnable(isEnable);
    }

    /**
     * 房主切换禁言
     */
    public void toggleAllNoTyping(boolean isAllNoTyping) {
        if (isRoomOwner()) {
            Room room = getRoom();
            room.setAllNoTyping(isAllNoTyping);
            onBasicInfoChanged(room);
        }
    }

    /**
     * 切换对方静音
     */
    @UiThread
    public void onMuteChanged(@NonNull RoomUser user, boolean isMute) {
        if (isRoomMember(user)) {
            members.get(members.indexOf(user)).setNoTyping(isMute);
        }
    }

    /**
     * 房主切换对方身份
     */
    @UiThread
    public void onUserRoleChanged(@NonNull RoomUser user) {
        if (isRoomMember(user)) {
            members.get(members.indexOf(user)).setRoomRole(user.getRoomRole());
        }
    }

    /**
     * 踢出
     */
    public void onKickout(User user) {

    }

    //callback
    public class HMRChannelCallback extends SimpleChannelServiceListener {

        @Override
        public void onRoleAdded(@NonNull ChatRoom chatRoom, @NonNull String role,
                                @NonNull com.hummer.im.model.id.User admin,
                                @NonNull com.hummer.im.model.id.User fellow) {
            super.onRoleAdded(chatRoom, role, admin, fellow);
            if (isClosing) {
                return;
            }

            RoomUser mine = getMine();
            if (mine == null) {
                return;
            }

            long uid = fellow.getId();
            if (uid == 0) {
                //自己
                uid = mine.getUid();
            }

            if (!isRoomMember(uid)) {
                //如果已经退出房间，就不进行下面操作
                return;
            }

            admins.add(uid);

            getUserSync(uid)
                    .observeOn(AndroidSchedulers.mainThread())
                    .compose(bindToLifecycle())
                    .subscribe(new SampleSingleObserver<RoomUser>() {
                        @Override
                        public void onSuccess(RoomUser user) {
                            //目前只支持"管理员"
                            admins.add(user.getUid());
                            user.setRoomRole(RoomUser.RoomRole.Admin);
                            onRoleChanged(user);
                        }
                    });
        }

        @Override
        public void onRoleRemoved(@NonNull ChatRoom chatRoom, @NonNull String role,
                                  @NonNull com.hummer.im.model.id.User admin,
                                  @NonNull com.hummer.im.model.id.User fellow) {
            super.onRoleRemoved(chatRoom, role, admin, fellow);
            if (isClosing) {
                return;
            }

            RoomUser mine = getMine();
            if (mine == null) {
                return;
            }

            long uid = fellow.getId();
            if (uid == 0) {
                //自己
                uid = mine.getUid();
            }

            if (!isRoomMember(uid)) {
                //如果已经退出房间，就不进行下面操作
                return;
            }

            admins.remove(uid);

            getUserSync(uid)
                    .observeOn(AndroidSchedulers.mainThread())
                    .compose(bindToLifecycle())
                    .subscribe(new SampleSingleObserver<RoomUser>() {
                        @Override
                        public void onSuccess(RoomUser user) {
                            admins.remove(user.getUid());
                            user.setRoomRole(RoomUser.RoomRole.Spectator);
                            onRoleChanged(user);
                        }
                    });
        }

        @Override
        public void onMemberMuted(@NonNull ChatRoom chatRoom,
                                  @NonNull com.hummer.im.model.id.User operator,
                                  @NonNull Set<com.hummer.im.model.id.User> members,
                                  @Nullable String reason) {
            super.onMemberMuted(chatRoom, operator, members, reason);
            if (isClosing) {
                return;
            }

            for (com.hummer.im.model.id.User user : members) {
                long uid = user.getId();
                if (!isRoomMember(uid)) {
                    //如果已经退出房间，就不进行下面操作
                    return;
                }

                getUserSync(uid)
                        .observeOn(AndroidSchedulers.mainThread())
                        .compose(bindToLifecycle())
                        .subscribe(new SampleSingleObserver<RoomUser>() {
                            @Override
                            public void onSuccess(RoomUser user) {
                                muteMemberUserIds.add(user.getUid());
                                user.setNoTyping(true);
                                onMuteChanged(user);
                            }
                        });
            }
        }

        @Override
        public void onMemberUnmuted(@NonNull ChatRoom chatRoom,
                                    @NonNull com.hummer.im.model.id.User operator,
                                    @NonNull Set<com.hummer.im.model.id.User> members,
                                    @Nullable String reason) {
            super.onMemberUnmuted(chatRoom, operator, members, reason);
            if (isClosing) {
                return;
            }

            for (com.hummer.im.model.id.User user : members) {
                long uid = user.getId();
                if (!isRoomMember(uid)) {
                    //如果已经退出房间，就不进行下面操作
                    return;
                }

                getUserSync(uid)
                        .observeOn(AndroidSchedulers.mainThread())
                        .compose(bindToLifecycle())
                        .subscribe(new SampleSingleObserver<RoomUser>() {
                            @Override
                            public void onSuccess(RoomUser user) {
                                muteMemberUserIds.remove(user.getUid());
                                user.setNoTyping(false);
                                onMuteChanged(user);
                            }
                        });
            }
        }

        @Override
        public void onMemberKicked(@NonNull ChatRoom chatRoom,
                                   @NonNull com.hummer.im.model.id.User admin,
                                   @NonNull List<com.hummer.im.model.id.User> member,
                                   @NonNull String reason) {
            super.onMemberKicked(chatRoom, admin, member, reason);
            if (isClosing) {
                return;
            }

            for (com.hummer.im.model.id.User user : member) {
                long uid = user.getId();
                if (!isRoomMember(uid)) {
                    //如果已经退出房间，就不进行下面操作
                    return;
                }

                getUserSync(uid)
                        .observeOn(AndroidSchedulers.mainThread())
                        .compose(bindToLifecycle())
                        .subscribe(new SampleSingleObserver<RoomUser>() {
                            @Override
                            public void onSuccess(RoomUser user) {
                                BaseRoomViewModel.this.onMemberKicked(user);
                            }
                        });
            }
        }

        @Override
        public void onMessageTxt(@NonNull Message message) {
            super.onMessageTxt(message);
            if (isClosing) {
                return;
            }

            Identifiable identifiable = message.getSender();
            long uid = identifiable.getId();

            if (!isRoomMember(uid)) {
                //如果已经退出房间，就不进行下面操作
                return;
            }

            String msg = Content.makeString(message.getContent());
            PublicMessage publicMessage = mGson.fromJson(msg, PublicMessage.class);
            LogUtils.d(TAG, "onMessageTxt() called with: publicMessage = [" + publicMessage + "]");

            getUserSync(uid)
                    .observeOn(AndroidSchedulers.mainThread())
                    .compose(bindToLifecycle())
                    .subscribe(new SampleSingleObserver<RoomUser>() {
                        @Override
                        public void onSuccess(RoomUser user) {
                            if (publicMessage.getType() == FakeMessage.MessageType.Notice) {
                                mView.onSendMessage(
                                        new FakeMessage(null, publicMessage.getMessage(),
                                                publicMessage.getType()));
                            } else {
                                mView.onSendMessage(
                                        new FakeMessage(user, publicMessage.getMessage(),
                                                publicMessage.getType()));
                            }
                        }
                    });
        }

        @Override
        public void onBasicInfoChanged(@NonNull ChatRoom chatRoom,
                                       @NonNull Map<ChatRoomInfo.BasicInfoType, String> propInfo) {
            super.onBasicInfoChanged(chatRoom, propInfo);
            if (isClosing) {
                return;
            }

            String AppExtra = propInfo.get(ChatRoomInfo.BasicInfoType.AppExtra);
            LogUtils.d(TAG, "onBasicInfoChanged() called with: AppExtra=" + AppExtra);
            if (!TextUtils.isEmpty(AppExtra)) {
                HummerSvc.RoomInfo roomInfo = mGson.fromJson(AppExtra, HummerSvc.RoomInfo.class);

                Room room = getRoom();
                room.setAllNoTyping(roomInfo.isAllMute());
                room.setRMicEnable(!roomInfo.isAllMicOff());

                for (RoomUser user : members) {
                    if (ObjectsCompat.equals(user, getOwnerUser())) {
                        //房主不受房间全局属性影响
                        continue;
                    }

                    user.setNoTyping(roomInfo.isAllMute());
                    user.setMicEnable(!roomInfo.isAllMicOff());
                }

                BaseRoomViewModel.this.onBasicInfoChanged(room);
            }
        }
    }

    @CallSuper
    protected void onBasicInfoChanged(Room room) {
        LogUtils.d(TAG, "onBasicInfoChanged() called with: room=" + room);
        this.mLiveDataRoomInfo.postValue(room);
    }

    public class ThunderCallback extends SimpleThunderEventHandler {
        @Override
        public void onError(int error) {
            super.onError(error);
            mLiveDataError.postValue(ERROR_THUNDER);
        }

        @Override
        public void onNetworkQuality(String uid, int txQuality, int rxQuality) {
            super.onNetworkQuality(uid, txQuality, rxQuality);
            if (isClosing) {
                return;
            }

            RoomUser mine = getMine();
            if (mine == null) {
                return;
            }

            long uidTemp = Long.parseLong(uid);
            if (uidTemp == 0) {
                //自己
                uidTemp = mine.getUid();
            }

            if (!memberCache.containsKey(uidTemp)) {
                //因为member存在房间的概念，但跨房间下面，网络无法提供房间号，所以需要等memberCache有了，才进行操作
                return;
            }

            getUserSync(uidTemp)
                    .observeOn(AndroidSchedulers.mainThread())
                    .compose(bindToLifecycle())
                    .subscribe(new SampleSingleObserver<RoomUser>() {
                        @Override
                        public void onSuccess(RoomUser user) {
                            user.setTxQuality(txQuality);
                            user.setRxQuality(rxQuality);
                            BaseRoomViewModel.this.onNetworkQuality(user);
                        }
                    });
        }

        @Override
        public void onRoomStats(ThunderNotification.RoomStats stats) {
            super.onRoomStats(stats);
            if (isClosing) {
                return;
            }

            RoomUser mine = getMine();
            if (mine == null) {
                return;
            }

            mine.setStats(stats);
            mLiveDataRoomStats.postValue(stats);
        }

        @Override
        public void onRemoteVideoStopped(String uid, boolean stop) {
            super.onRemoteVideoStopped(uid, stop);
            if (isClosing) {
                return;
            }

            RoomUser mine = getMine();
            if (mine == null) {
                return;
            }

            long uidTemp = Long.parseLong(uid);
            if (uidTemp == 0) {
                //自己
                uidTemp = mine.getUid();
            }

            if (stop) {
                //WS偶发收不到对方离开房间，所以只能靠thunder来弥补
                if (uidTemp == mine.getUid()) {

                } else if (uidTemp == getOwnerUser().getUid()) {

                } else {
                    RoomUser user = getChatingMember(uidTemp);
                    if (user != null) {
                        getUserSync(user.getRoomId(), user.getUid())
                                .observeOn(AndroidSchedulers.mainThread())
                                .compose(bindToLifecycle())
                                .subscribe(new SampleSingleObserver<RoomUser>() {
                                    @Override
                                    public void onSuccess(RoomUser user) {
                                        onMemberLeave(user);
                                    }
                                });
                    }
                }
            }
        }

        @Override
        public void onRemoteAudioStopped(String uid, boolean stop) {
            super.onRemoteAudioStopped(uid, stop);
            if (isClosing) {
                return;
            }

            RoomUser mine = getMine();
            if (mine == null) {
                return;
            }

            long uidTemp = Long.parseLong(uid);
            if (uidTemp == 0) {
                //自己
                uidTemp = mine.getUid();
            }
        }

        @Override
        public void onPlayVolumeIndication(ThunderEventHandler.AudioVolumeInfo[] speakers,
                                           int totalVolume) {
            super.onPlayVolumeIndication(speakers, totalVolume);
            if (isClosing) {
                return;
            }

            for (ThunderEventHandler.AudioVolumeInfo info : speakers) {
                long uidTemp = Long.parseLong(info.uid);
                if (!memberCache.containsKey(uidTemp)) {
                    //因为member存在房间的概念，但跨房间下面，网络无法提供房间号，所以需要等memberCache有了，才进行操作
                    continue;
                }

                getUserSync(uidTemp)
                        .observeOn(AndroidSchedulers.mainThread())
                        .compose(bindToLifecycle())
                        .subscribe(new SampleSingleObserver<RoomUser>() {
                            @Override
                            public void onSuccess(RoomUser user) {
                                if (info.volume == user.getVolume()) {
                                    return;
                                }

                                user.setVolume(info.volume);
                                BaseRoomViewModel.this.onPlayVolumeIndication(user);
                            }
                        });
            }
        }
    }

    @UiThread
    private void onMemberJoin(@NonNull RoomUser user) {
        LogUtils.d(TAG, "onMemberJoin() called with: user = [" + user + "]");
        Room room = getRoom();
        if (user.getRoomId() == room.getRoomId()) {
            //成员只计算同房间的
            if (!members.contains(user)) {
                members.add(user);
                memberUserIds.add(user.getUid());
                mView.onMemberJoin(user);

                room.setRCount(members.size());
                onBasicInfoChanged(room);
            }
        }
    }

    @UiThread
    private void onMemberLeave(@NonNull RoomUser user) {
        LogUtils.d(TAG, "onMemberLeave() called with: user = [" + user + "]");
        if (ObjectsCompat.equals(user, getOwnerUser())) {
            //如果是房主离开，就需要删除房间列表里面当前房间
            ToastUtil.showToast(getApplication(), R.string.room_owner_leave_tip);
            EventBus.getDefault().post(new EventDeleteRoom(getRoom()));
            mView.finish();
            return;
        }

        if (isInChating(user)) {
            //如果这个人正好正在连麦，还需要处理断开操作
            onMemberChatStop(user);
        }

        if (members.contains(user)) {
            members.remove(user);
            memberUserIds.remove(user.getUid());
            mView.onMemberLeave(user);

            Room room = getRoom();
            room.setRCount(members.size());
            onBasicInfoChanged(room);
        }
        memberCache.remove(user.getUid());
    }

    @UiThread
    protected void onVideoStart(@NonNull RoomUser user) {
        if (!isClosing) {
            mView.onVideoStart(user);
        }
    }

    @UiThread
    protected void onVideoStop(@NonNull RoomUser user) {
        if (!isClosing) {
            mView.onVideoStop(user);
        }
    }

    @UiThread
    protected void onAudioStart(@NonNull RoomUser user) {
        if (!isClosing) {
            mView.onAudioStart(user);
        }
    }

    @UiThread
    protected void onAudioStop(@NonNull RoomUser user) {
        if (!isClosing) {
            mView.onAudioStop(user);
        }
    }

    @UiThread
    protected void onPlayVolumeIndication(@NonNull RoomUser user) {
        if (!isClosing) {
            mView.onPlayVolumeIndication(user);
        }
    }

    @UiThread
    protected void onNetworkQuality(@NonNull RoomUser user) {
        if (!isClosing) {
            mView.onNetworkQuality(user);
        }
    }

    @UiThread
    protected void onMuteChanged(@NonNull RoomUser user) {
        if (!isClosing) {
            mView.onMuteChanged(user);
        }
    }

    @UiThread
    protected void onRoleChanged(@NonNull RoomUser user) {
        if (!isClosing) {
            mView.onRoleChanged(user);
        }
    }

    @UiThread
    protected void onMemberKicked(@NonNull RoomUser user) {
        if (!isClosing) {
            mView.onMemberKicked(user);
        }
    }

    /**
     * 开始连麦，当SW指令操作成功之后，触发这个回掉
     *
     * @param user 连麦的观众。如果我是观众，那就是自己
     */
    @UiThread
    @CallSuper
    public void onMemberChatStart(@NonNull RoomUser user) {
        LogUtils.d(TAG, "onMemberChatStart() called with: user = [" + user + "]");
        if (!isClosing) {
            mView.onMemberChatStart(user);
        }
    }

    /**
     * 结束连麦
     *
     * @param user 连麦的观众。如果我是观众，那就是自己
     */
    @UiThread
    @CallSuper
    public void onMemberChatStop(@NonNull RoomUser user) {
        LogUtils.d(TAG, "onMemberChatStop() called with: user=" + user);
        if (!isClosing) {
            mView.onMemberChatStop(user);
        }
    }

    @UiThread
    @CallSuper
    public void onJoinChatRoomSuccess() {
        RoomUser mine = getMine();
        if (mine != null) {
            if (!reJoinRoom) {
                //如果是重新加入方式，就不需要启动
                Room room = getRoom();
                FunWSSvc.getInstance().setNeedReconnect(!isRoomOwner());
                FunWSSvc.getInstance().start(Consts.APPID, mine.getUid(), room.getRoomId(),
                        Objects.requireNonNull(room.getRChatId()), room.getRType());
            }
        }

        isJoinHummerCompleted = true;
        if (isJoinThunderCompleted && isJoinHummerCompleted && isSyncMembersCompleted) {
            onJoinRoomAllCompleted();
        }
    }

    /**
     * 获取同房间用户信息
     *
     * @param uid
     * @return
     */
    public Single<RoomUser> getUserSync(Long uid) {
        Room room = getRoom();
        return getUserSync(room.getRoomId(), uid);
    }

    /**
     * 获取用户信息
     *
     * @param rid
     * @param uid
     * @return
     */
    public Single<RoomUser> getUserSync(long rid, long uid) {
        return Single.create(emitter -> {
            if (memberCache.containsKey(uid)) {
                emitter.onSuccess(memberCache.get(uid));
            } else {
                RoomUser mine = getMine();
                if (mine == null) {
                    emitter.onError(new Throwable("no login"));
                    return;
                }

                RoomUser.UserType userType = null;
                //设置用户类型
                if (uid == mine.getUid()) {
                    userType = RoomUser.UserType.Local;
                } else {
                    userType = RoomUser.UserType.Remote;
                }

                //设置用户角色
                RoomUser roomUser = new RoomUser(uid, rid, userType);
                if (ObjectsCompat.equals(roomUser, getOwnerUser())) {
                    roomUser.setRoomRole(RoomUser.RoomRole.Owner);
                } else if (admins.contains(uid)) {
                    roomUser.setRoomRole(RoomUser.RoomRole.Admin);
                } else {
                    roomUser.setRoomRole(RoomUser.RoomRole.Spectator);
                }

                //设置禁麦和禁言
                if (!ObjectsCompat.equals(roomUser, getOwnerUser())) {
                    //房间的设置最优先
                    roomUser.setNoTyping(getRoom().isAllNoTyping());
                    roomUser.setMicEnable(getRoom().getRMicEnable());
                }

                if (!roomUser.isNoTyping()) {
                    if (muteMemberUserIds.contains(roomUser.getUid())) {
                        roomUser.setNoTyping(true);
                    }
                }

                FlyHttpSvc.getInstance().getUserInfo(uid)
                        .compose(bindToLifecycle())
                        .subscribe(new BaseObserver<HttpResponse<User>>(getApplication()) {
                            @Override
                            public void handleSuccess(HttpResponse<User> response) {
                                User user = response.Data;
                                if (user == null) {
                                    emitter.onSuccess(roomUser);
                                    return;
                                }

                                roomUser.setNickName(user.getNickName());
                                roomUser.setCover(user.getCover());
                                memberCache.put(uid, roomUser);

                                emitter.onSuccess(roomUser);
                            }

                            @Override
                            public void onError(Throwable e) {
                                super.onError(e);
                                emitter.onSuccess(roomUser);
                            }
                        });
            }
        });
    }

    public ArrayList<RoomUser> getMembers() {
        return members;
    }

    @Override
    public void onUserEnterRoom(RoomPacket chatPkg) {
        LogUtils.d(TAG, "onUserEnterRoom() called with: chatPkg = [" + chatPkg + "]");
        if (isClosing) {
            return;
        }

        long uid = chatPkg.Body.getUid();
        long roomId = chatPkg.Body.getLiveRoomId();

        RoomUser mine = getMine();
        if (mine == null) {
            return;
        }

        if (mine.getUid() == uid) {
            //自己不需要处理下面逻辑
            //如果是自己，就代表WS已经连接上了，就需要同步房间信息
            if (mUIHandler != null) {
                mUIHandler.post(new Runnable() {
                    @Override
                    public void run() {
                        getRoomInfo();
                    }
                });
            }
            return;
        }

        getUserSync(roomId, uid)
                .observeOn(AndroidSchedulers.mainThread())
                .compose(bindToLifecycle())
                .subscribe(new SampleSingleObserver<RoomUser>() {
                    @Override
                    public void onSuccess(RoomUser user) {
                        //设置用户类型
                        if (ObjectsCompat.equals(user, getMine())) {
                            user.setUserType(RoomUser.UserType.Local);
                        } else {
                            user.setUserType(RoomUser.UserType.Remote);
                        }

                        //设置用户角色
                        if (ObjectsCompat.equals(user, getOwnerUser())) {
                            user.setRoomRole(RoomUser.RoomRole.Owner);
                        } else if (admins.contains(uid)) {
                            user.setRoomRole(RoomUser.RoomRole.Admin);
                        } else {
                            user.setRoomRole(RoomUser.RoomRole.Spectator);
                        }

                        //设置禁麦和禁言
                        if (!ObjectsCompat.equals(user, getOwnerUser())) {
                            //房间的设置最优先
                            user.setNoTyping(getRoom().isAllNoTyping());
                            user.setMicEnable(getRoom().getRMicEnable());
                        }

                        if (!user.isNoTyping()) {
                            if (muteMemberUserIds.contains(user.getUid())) {
                                user.setNoTyping(true);
                            }
                        }

                        onMemberJoin(user);
                    }
                });
    }

    @Override
    public void onUserLeaveRoom(RoomPacket roomPkg) {
        LogUtils.d(TAG, "onUserLeaveRoom() called with: chatPkg = [" + roomPkg + "]");
        if (isClosing) {
            return;
        }

        long uid = roomPkg.Body.getUid();
        long rid = roomPkg.Body.getLiveRoomId();

        RoomUser mine = getMine();
        if (mine == null) {
            return;
        }

        if (mine.getUid() == uid) {
            //如果自己离开，不需要处理下面逻辑，因为直接退出房间了，退出界面了
            return;
        }

        getUserSync(rid, uid)
                .observeOn(AndroidSchedulers.mainThread())
                .compose(bindToLifecycle())
                .subscribe(new SampleSingleObserver<RoomUser>() {
                    @Override
                    public void onSuccess(RoomUser user) {
                        onMemberLeave(user);
                    }
                });
    }

    @Override
    public void onUserMicEnable(MicPacket micPkg) {
        LogUtils.d(TAG, "onUserMicEnable() called with: micPkg = [" + micPkg + "]");
        if (isClosing) {
            return;
        }

        long fromUID = micPkg.Body.SrcUid;
        long uid = micPkg.Body.DestUid;

        getUserSync(uid)
                .observeOn(AndroidSchedulers.mainThread())
                .compose(bindToLifecycle())
                .subscribe(new SampleSingleObserver<RoomUser>() {
                    @Override
                    public void onSuccess(RoomUser user) {
                        if (fromUID == uid) {
                            //这个用户，自己对自己本地操作
                            user.setSelfMicEnable(micPkg.Body.MicEnable);
                        } else {
                            //房主操作了这个用户
                            user.setMicEnable(micPkg.Body.MicEnable);
                        }

                        if (fromUID != uid && ObjectsCompat.equals(getMine(), user)) {
                            //如果不是本地操作，并且是我被操作了，需要对thunder做相应控制
                            if (user.isSelfMicEnable()) {
                                //如果本地是打开状态，才需要开启或者关闭thunder
                                toggleThunderMic(micPkg.Body.MicEnable);
                            }
                        }

                        if (micPkg.Body.MicEnable) {
                            onAudioStart(user);
                        } else {
                            onAudioStop(user);
                        }
                    }
                });
    }

    /**
     * 网络情况下，当重新连接网络后，需要处理重新加入房间操作
     */
    protected boolean reJoinRoom = false;

    @Override
    public void onConnectStateChanged(int state) {
        LogUtils.d(TAG, "onConnectStateChanged() called with: state = [" + state + "]");
        if (isClosing) {
            return;
        }

        if (mUIHandler != null) {
            mUIHandler.post(new Runnable() {
                @Override
                public void run() {
                    if (state == FunWSClientHandler.ConnectState.CONNECT_STATE_RECONNECTING) {
                        reJoinRoom = true;
                    } else if (state == FunWSClientHandler.ConnectState.CONNECT_STATE_CONNECTED) {

                    } else if (state == FunWSClientHandler.ConnectState.CONNECT_STATE_LOST) {
                        reJoinRoom = true;
                    }
                }
            });
        }
        mLiveDataConnection.postValue(state);
    }

    @Override
    public void onSeverErr(int msgId, String code) {
        LogUtils.d(TAG, "onSeverErr() called with: msgId = [" + msgId + "], code = [" + code + "]");
        if (isClosing) {
            return;
        }

        if (msgId == BasePacket.EV_CS_ENTER_ROOM_NTY + BasePacket.EV_SC_ERRNO_BGN) {
            //ws加入房间失败
            mLiveDataError.postValue(ERROR_WS_JOIN);
        }
    }

    /**
     * 是否是房间成员
     *
     * @param uid
     * @return
     */
    private boolean isRoomMember(long uid) {
        return memberUserIds.contains(uid);
    }

    /**
     * 是否是房间成员
     *
     * @param user
     * @return
     */
    private boolean isRoomMember(RoomUser user) {
        return members.contains(user);
    }
}
