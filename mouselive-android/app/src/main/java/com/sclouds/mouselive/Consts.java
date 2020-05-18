package com.sclouds.mouselive;

/**
 * @author xipeitao
 * @description: 配置参数
 * @date : 2020-03-18 14:12
 */
public class Consts {

    /**
     * 尚云官网申请的appid，请关注https://www.sunclouds.com/#/
     */
    public static long APPID = 请填写appid
    /**
     * 尚云官网申请的appid所对应的apseret，token的使用和生成请关注https://www.sunclouds.com/#/
     * <p>
     * 三种模式：
     * appid模式：hummer和thunder会跳过token验证？？？
     * token验证模式：适用于安全性要求较高的场景，hummer和thunder会验证token，验证过期或者不ton过测无法使用服务
     * token和业务服务器模式：适用于安全性要求很高的场景，hummer和thunder会验证token，验证通过后还会请求业务服务器进行token效验，验证过期或者不ton过测无法使用服务
     */
    public static String APP_SECRET = "";
}
