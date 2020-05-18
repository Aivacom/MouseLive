package com.sclouds.effect;

import android.opengl.GLES11Ext;
import android.opengl.GLES20;
import android.os.Handler;
import android.os.Looper;

import com.orangefilter.OrangeFilter;
import com.sclouds.basedroid.LogUtils;
import com.sclouds.common.utils.Accelerometer;
import com.sclouds.effect.utils.BeautyHelper;
import com.sclouds.effect.utils.CameraUtil;
import com.sclouds.effect.utils.FilterHelper;
import com.thunder.livesdk.video.IVideoCaptureObserver;
import com.yy.mediaframework.gles.Drawable2d;
import com.yy.mediaframework.gpuimage.custom.IGPUProcess;
import com.yy.mediaframework.gpuimage.util.GLShaderProgram;
import com.yy.mediaframework.gpuimage.util.GLTexture;

import java.io.File;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.FloatBuffer;
import java.nio.IntBuffer;
import java.util.Vector;

/**
 * Created by zhouwen on 2020/4/8.
 * OF特效具体实现类
 */
public class EffectCaptureProcessor implements IGPUProcess {
    private final static String TAG = EffectCaptureProcessor.class.getSimpleName();
    private final static String noeffect_vs =
            "attribute vec4 aPosition;\n" +
                    "attribute vec4 aTextureCoord;\n" +
                    "varying vec2 vTexCoord;\n" +
                    "\n" +
                    "void main()\n" +
                    "{\n" +
                    "    gl_Position = aPosition;\n" +
                    "    vTexCoord = aTextureCoord.xy;\n" +
                    "}";

    private static String noeffect_fs =
            "precision mediump float;\n" +
                    "varying vec2 vTexCoord;\n" +
                    "uniform sampler2D uTexture0;\n" +
                    "\n" +
                    "void main()\n" +
                    "{\n" +
                    "    vec4 color = texture2D(uTexture0, vTexCoord);\n" +
                    "    gl_FragColor = color; //vec4(color.y, color.y, color.y, 1.0);\n" +
                    "}";

    private final static String passthrouth_vs =
            "attribute vec4 aPosition;\n" +
                    "attribute vec4 aTextureCoord;\n" +
                    "varying vec2 vTexCoord;\n" +
                    "\n" +
                    "void main()\n" +
                    "{\n" +
                    "    gl_Position = aPosition;\n" +
                    "    vTexCoord = aTextureCoord.xy;\n" +
                    "}";

    private final static String passthrouth_fs =
            "precision mediump float;\n" +
                    "varying vec2 vTexCoord;\n" +
                    "uniform sampler2D uTexture0;\n" +
                    "\n" +
                    "void main()\n" +
                    "{\n" +
                    "    vec4 color = texture2D(uTexture0, vTexCoord);\n" +
                    "    gl_FragColor = color; //vec4(color.y, color.y, color.y, 1.0);\n" +
                    "}";

    private final static String mOESFragmentShader = "#extension GL_OES_EGL_image_external : require\n" +
            noeffect_fs.replace("uniform sampler2D uTexture0;",
                    "uniform samplerExternalOES uTexture0;");

    private static final float CUBE[] = {
            -1.0f, -1.0f,
            1.0f, -1.0f,
            -1.0f, 1.0f,
            1.0f, 1.0f,
    };

    private final FloatBuffer mVertexBuffer = ByteBuffer.allocateDirect(CUBE.length * 4)
            .order(ByteOrder.nativeOrder())
            .asFloatBuffer();

    private GLShaderProgram mNoEffectShader = null;
    private GLShaderProgram mPassthroughShader = null;

    private GLTexture mInputTexture = null;
    private GLTexture mOutputTexture = null;
    private IntBuffer mFramebuffer = null;
    private IntBuffer mOldFramebuffer = null;
    private Drawable2d mRectDrawable = new Drawable2d(Drawable2d.Prefab.FULL_RECTANGLE);

    private Handler mHandler;

    private int mTextureTarget;
    private int mOutputWidth = 0;
    private int mOutputHeight = 0;
    private boolean mHasInit = false;
    private int mOfContextId;
    private String mVenusModelPath;

    /**
     * 美颜
     */
    private Effect mBeautyEffect = new Effect();
    /**
     * 滤镜
     */
    private Effect mFilterEffect = new Effect();
    /**
     * 贴纸
     */
    private Effect mStickerEffect = new Effect();
    /**
     * 一类手势
     */
    private Effect mGestureEffect = new Effect();
    /**
     * 手势子类型:点赞，单手比心，双手比心，666，手掌，比V，OK
     */
    private Effect mGestureGoodEffect = new Effect();
    private Effect mGestureSingleLoveEffect = new Effect();
    private Effect mGestureDoubleLoveEffect = new Effect();
    private Effect mGestureSixEffect = new Effect();
    private Effect mGestureHandEffect = new Effect();
    private Effect mGestureVEffect = new Effect();
    private Effect mGestureOkEffect = new Effect();

    private BeautyHelper mBeautyHelper = null;
    private FilterHelper mFilterHelper = null;

    private OrangeFilter.OF_FrameData mFrameData;
    private OrangeFilter.OF_Texture[] mInputs;
    private OrangeFilter.OF_Texture[] mOutputs;

    private long mStartTime = 0;
    private int mFrameCount = 0;
    private long mFrameTime = 0;

    private byte[] mImageData;
    private int mImgHeight;
    private int mImgWidth;
    private final Object mHandleLock = new Object();

    public EffectCaptureProcessor(String venusModelPath) {
        mVenusModelPath = venusModelPath;
    }

    public void setEffectHelper(BeautyHelper beautyHelper, FilterHelper filterHelper) {
        mBeautyHelper = beautyHelper;
        mFilterHelper = filterHelper;
    }

    private void checkHandler() {
        Looper looper = Looper.myLooper();
        if (mHandler == null &&  looper != null) {
            mHandler = new Handler(looper);
        }
    }


    /**
     * 视频openGl渲染线程初始化回调
     * 详见md文档介绍
     */
    @Override
    public void onInit(int textureTarget, int outputWidth, int outputHeight) {
        checkHandler();

        mOfContextId = OrangeFilter.createContext(mVenusModelPath);
        if (mOfContextId == 0) {
            LogUtils.e(TAG, "OrangeFilter SDK初始化失败，请检查授权是否过期。");
        } else {
            LogUtils.d(TAG, "onInit#mOfContextId=" + mOfContextId);
        }

        // Init temp textures.
        if (mInputTexture == null || mOutputTexture == null) {
            mInputTexture = new GLTexture(GLES20.GL_TEXTURE_2D);
            mOutputTexture = new GLTexture(GLES20.GL_TEXTURE_2D);
        }

        mTextureTarget = textureTarget;
        mOutputWidth = outputWidth;
        mOutputHeight = outputHeight;

        if (textureTarget == GLES11Ext.GL_TEXTURE_EXTERNAL_OES) {
            noeffect_fs = mOESFragmentShader;
        }

        mVertexBuffer.put(CUBE).position(0);

        mFramebuffer = IntBuffer.allocate(1);
        GLES20.glGenFramebuffers(1, mFramebuffer);

        mNoEffectShader = new GLShaderProgram();
        mNoEffectShader.setProgram(noeffect_vs, noeffect_fs);

        mPassthroughShader = new GLShaderProgram();
        mPassthroughShader.setProgram(passthrouth_vs, passthrouth_fs);

        mOldFramebuffer = IntBuffer.allocate(1);

        mHasInit = true;

        //init渲染数据
        initEffect();
    }

    private void initEffect() {
        mFrameData = new OrangeFilter.OF_FrameData();
        mInputs = new OrangeFilter.OF_Texture[1];
        mOutputs = new OrangeFilter.OF_Texture[1];
        mInputs[0] = new OrangeFilter.OF_Texture();
        mOutputs[0] = new OrangeFilter.OF_Texture();
        mBeautyEffect.effect = 0;
        mFilterEffect.effect = 0;
        mStickerEffect.effect = 0;
        mGestureEffect.effect = 0;

        mGestureGoodEffect.effect = 0;
        mGestureSingleLoveEffect.effect = 0;
        mGestureDoubleLoveEffect.effect = 0;
        mGestureSixEffect.effect = 0;
        mGestureHandEffect.effect = 0;
        mGestureVEffect.effect = 0;
        mGestureOkEffect.effect = 0;
    }

    /**
     * 视频openGl渲染线程销毁回调
     * 详见md文档介绍
     */
    @Override
    public void onDestroy() {
        LogUtils.d(TAG, "onDestroy OF Render");
        // Destory all opengl objects.
        mHasInit = false;

        GLES20.glDeleteFramebuffers(1, mFramebuffer);
        if (mInputTexture != null) {
            mInputTexture.destory();
            mOutputTexture.destory();
        }

        //销毁Shader
        mNoEffectShader.destory();
        mPassthroughShader.destory();

        // 销毁 orangeFilter
        destroyOFEffect();
    }

    /**
     * destroy Effect
     *
     * @param effect 特效
     */
    private void destroyEffect(Effect effect) {
        if (effect != null && effect.effect != 0) {
            OrangeFilter.destroyEffect(mOfContextId, effect.effect);
            effect.effect = 0;
            effect.currentPath = null;
        }
    }

    /**
     * 销毁 OrangeFilter Context 资源
     */
    private void destroyOFEffect() {
        destroyEffect(mBeautyEffect);
        destroyEffect(mFilterEffect);
        destroyEffect(mStickerEffect);
        destroyEffect(mGestureEffect);
        destroyEffect(mGestureGoodEffect);
        destroyEffect(mGestureSingleLoveEffect);
        destroyEffect(mGestureDoubleLoveEffect);
        destroyEffect(mGestureSixEffect);
        destroyEffect(mGestureHandEffect);
        destroyEffect(mGestureVEffect);
        destroyEffect(mGestureOkEffect);

        if (mOfContextId != 0) {
            OrangeFilter.destroyContext(mOfContextId);
            mOfContextId = 0;
        }

        mBeautyHelper.clearEffect();
        mFilterHelper.clearEffect();
    }

    /**
     * openGl渲染，内部工具函数，业务不用关心
     */
    private void drawQuad(GLShaderProgram shader, FloatBuffer cubeBuffer, FloatBuffer textureBuffer) {
        cubeBuffer.position(0);
        shader.setVertexAttribPointer("aPosition", 2, GLES20.GL_FLOAT, false, 0, cubeBuffer);

        textureBuffer.position(0);
        shader.setVertexAttribPointer("aTextureCoord", 2, GLES20.GL_FLOAT, false, 0, textureBuffer);

        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4);

        shader.disableVertexAttribPointer("aPosition");
        shader.disableVertexAttribPointer("aTextureCoord");
    }

    /**
     * 从素材包文件创建特效
     *
     * @param effect 特效
     * @return
     */
    private boolean updateEffect(Effect effect) {
        boolean updated = false;

        if (effect.targetPath != null &&
                (effect.currentPath == null || !effect.currentPath.equals(effect.targetPath))) {
            effect.currentPath = effect.targetPath;

            if (effect.effect != 0) {
                // 销毁 Effect
                OrangeFilter.destroyEffect(mOfContextId, effect.effect);
                effect.effect = 0;
                updated = true;
            }

            if (effect.currentPath.length() > 0) {
                if (new File(effect.currentPath).exists()) {
                    // 从素材包文件创建特效
                    effect.effect = OrangeFilter.createEffectFromPackage(mOfContextId, effect.currentPath);
                    if (effect.effect != 0) {
                        updated = true;
                    }
                } else {
                    LogUtils.w(TAG, "effect file not exist: " + effect.currentPath);
                }
            }
        }

        return updated;
    }

    /**
     * 视频openGl渲染线程每一帧渲染回调
     * 详见md文档介绍
     */
    @Override
    public void onDraw(int textureId, final FloatBuffer textureBuffer) {
        onDraw(textureId, mVertexBuffer, textureBuffer);
    }

    private void onDraw(int textureId, FloatBuffer cubeBuffer, FloatBuffer textureBuffer) {
        if (!mHasInit || mOfContextId == 0) {
            LogUtils.d(TAG, "onDraw not ready");
            return;
        }
        // Record old fbo.
        GLES20.glGetIntegerv(GLES20.GL_FRAMEBUFFER_BINDING, mOldFramebuffer);

        if (mInputTexture.getWidth() != mOutputWidth || mInputTexture.getHeight() != mOutputHeight) {
            mInputTexture.create(mOutputWidth, mOutputHeight, GLES20.GL_RGBA);
            mOutputTexture.create(mOutputWidth, mOutputHeight, GLES20.GL_RGBA);
            LogUtils.d(TAG, "[sjc] mOutputWidth: " + mOutputWidth + " ,mOutputHeight: " +
                    mOutputHeight);
        }

        updateEffects();

        // textureIn 是摄像头采集的图像，textureOut 是叠加特效后最终渲染到屏幕的图像。
        mInputs[0].width = mInputTexture.getWidth();
        mInputs[0].height = mInputTexture.getHeight();
        mInputs[0].format = GLES20.GL_RGBA;
        mInputs[0].target = mInputTexture.getTarget();
        mInputs[0].textureID = mInputTexture.getTextureId();

        mOutputs[0].width = mOutputTexture.getWidth();
        mOutputs[0].height = mOutputTexture.getHeight();
        mOutputs[0].format = GLES20.GL_RGBA;
        mOutputs[0].target = mOutputTexture.getTarget();
        mOutputs[0].textureID = mOutputTexture.getTextureId();

        prepareWithApplyFrameData(textureId, cubeBuffer, textureBuffer);

        drawFps();
    }

    private void drawFps() {
        mFrameCount++;
        long now = System.currentTimeMillis();
        if (now - mFrameTime > 1000) {
            int fps = mFrameCount;
            mFrameCount = 0;
            mFrameTime = now;
            LogUtils.v(TAG, "fps: " + fps);
        }
    }

    private void prepareWithApplyFrameData(int textureId, FloatBuffer cubeBuffer, FloatBuffer textureBuffer) {
        // yuv帧数据
        mFrameData.imageData = mImageData;
        mFrameData.width = mImgWidth;
        mFrameData.height = mImgHeight;

        mFrameData.widthStep = mFrameData.width;
        mFrameData.format = OrangeFilter.OF_PixelFormat_NV21;
        mFrameData.timestamp = (System.currentTimeMillis() - mStartTime) / 1000.0f;
        mFrameData.isUseCustomHarsLib = false;
        mFrameData.trackOn = false;
        mFrameData.curNode = 0;
        mFrameData.pickOn = false;
        mFrameData.pickResult = false;
        mFrameData.imageDir = Accelerometer.getDirection(); // 传感器即陀螺仪方向(0表示0度，1表示90度，2表示180度，3表示270度)
        mFrameData.orientation = CameraUtil.getCameraRotation(); // 相机图像的方向
        mFrameData.frontCamera = CameraUtil.isFrontCamera(); // 是否是前置摄像头

        if (mBeautyEffect.effect != 0 || mFilterEffect.effect != 0 || mStickerEffect.effect != 0
                || mGestureEffect.effect != 0 || mGestureGoodEffect.effect != 0 || mGestureSingleLoveEffect.effect != 0
                || mGestureDoubleLoveEffect.effect != 0 || mGestureSixEffect.effect != 0 || mGestureHandEffect.effect != 0
                || mGestureVEffect.effect != 0 || mGestureOkEffect.effect != 0) {

            //  数据预处理，如人脸跟踪点的姿态估计
            OrangeFilter.prepareFrameData(mOfContextId, mFrameData);

            Vector<Integer> effects = new Vector<>();

            //  是否设置美颜，滤镜，贴纸
            if (mBeautyEffect.effect != 0 && mBeautyEffect.enable) {
                effects.add(mBeautyEffect.effect);
            }
            if (mFilterEffect.effect != 0 && mFilterEffect.enable) {
                effects.add(mFilterEffect.effect);
            }
            if (mStickerEffect.effect != 0 && mStickerEffect.enable) {
                effects.add(mStickerEffect.effect);
            }
            // 是否设置手势
            if (mGestureEffect.effect != 0 && mGestureEffect.enable) {
                effects.add(mGestureEffect.effect);
            }
            // 是否设置手势特效子类型:点赞，单手比心，双手比心，666，手掌，比V，OK
            if (mGestureGoodEffect.effect != 0 && mGestureGoodEffect.enable) {
                effects.add(mGestureGoodEffect.effect);
            }
            if (mGestureSingleLoveEffect.effect != 0 && mGestureSingleLoveEffect.enable) {
                effects.add(mGestureSingleLoveEffect.effect);
            }
            if (mGestureDoubleLoveEffect.effect != 0 && mGestureDoubleLoveEffect.enable) {
                effects.add(mGestureDoubleLoveEffect.effect);
            }
            if (mGestureSixEffect.effect != 0 && mGestureSixEffect.enable) {
                effects.add(mGestureSixEffect.effect);
            }
            if (mGestureHandEffect.effect != 0 && mGestureHandEffect.enable) {
                effects.add(mGestureHandEffect.effect);
            }
            if (mGestureVEffect.effect != 0 && mGestureVEffect.enable) {
                effects.add(mGestureVEffect.effect);
            }
            if (mGestureOkEffect.effect != 0 && mGestureOkEffect.enable) {
                effects.add(mGestureOkEffect.effect);
            }

            if (effects.size() > 0) {
                // Camera 出来的OES纹理转成2D纹理，OrangeFilter输入需要2D纹理
                mInputTexture.bindFBO(mFramebuffer.get(0));
                GLES20.glClearColor(0, 0, 0, 1);
                GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT);
                mNoEffectShader.useProgram();
                mNoEffectShader.setUniformTexture("uTexture0", 0, textureId, mTextureTarget);
                drawQuad(mNoEffectShader, cubeBuffer, textureBuffer);

                int[] effectArray = new int[effects.size()];
                int[] resultArray = new int[effects.size()];
                for (int i = 0; i < effects.size(); ++i) {
                    effectArray[i] = effects.get(i);
                }

                // 渲染帧特效
                int a = OrangeFilter.applyFrameBatch(mOfContextId, effectArray, mInputs, mOutputs, resultArray);

                swap(mInputTexture, mOutputTexture);

                // Draw output texture.
                GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, mOldFramebuffer.get(0));
                mPassthroughShader.useProgram();
                mPassthroughShader
                        .setUniformTexture("uTexture0", 0, mInputTexture.getTextureId(), mInputTexture.getTarget());
                drawQuad(mPassthroughShader, mRectDrawable.getVertexArray(), mRectDrawable.getTexCoordArray());
                // Restore OpenGL states.
                GLES20.glBindTexture(mTextureTarget, 0);
            } else {
                drawTexture(textureId, cubeBuffer, textureBuffer);
            }
        } else {
            drawTexture(textureId, cubeBuffer, textureBuffer);
        }
    }

    private void drawTexture(int textureId, FloatBuffer cubeBuffer, FloatBuffer textureBuffer) {
        if (mTextureTarget == GLES11Ext.GL_TEXTURE_EXTERNAL_OES) {
            // Draw original texture
            mNoEffectShader.useProgram();
            mNoEffectShader.setUniformTexture("uTexture0", 0, textureId, mTextureTarget);
            drawQuad(mNoEffectShader, cubeBuffer, textureBuffer);
            // Restore OpenGL states.
            GLES20.glBindTexture(mTextureTarget, 0);
        }
    }

    private void updateEffects() {
        // update effects if need
        boolean beautyUpdated = updateEffect(mBeautyEffect);
        if (beautyUpdated) {
            mBeautyHelper.setEffect(mOfContextId, mBeautyEffect.effect);
        }
        boolean filterUpdated = updateEffect(mFilterEffect);
        if (filterUpdated) {
            mFilterHelper.setEffect(mOfContextId, mFilterEffect.effect);
        }
        updateEffect(mStickerEffect);
        // 一组手势（手势特效包集）
        updateEffect(mGestureEffect);
        // 分类手势 （细分特效类:点赞，单手比心，双手比心，666，手掌，比V，OK）
        updateEffect(mGestureGoodEffect);
        updateEffect(mGestureSingleLoveEffect);
        updateEffect(mGestureDoubleLoveEffect);
        updateEffect(mGestureSixEffect);
        updateEffect(mGestureHandEffect);
        updateEffect(mGestureVEffect);
        updateEffect(mGestureOkEffect);
    }

    private void swap(GLTexture in, GLTexture out) {
        int inId = in.getTextureId();
        int outId = out.getTextureId();
        in.setTextureId(outId);
        out.setTextureId(inId);
    }

    /**
     * 视频帧纹理大小回调
     * 详见md文档介绍
     */
    @Override
    public void onOutputSizeChanged(final int width, final int height) {
        LogUtils.v(TAG, "onOutputSizeChanged OF width: " + width + " ,height: " + height);
        mOutputWidth = width;
        mOutputHeight = height;
    }

    /**
     * 根据特效类型设置对应特效path
     *
     * @param effectPath 特效包路径
     */
    public void setBeautyEffectPath(final String effectPath) {
        checkHandler();
        if (mHandler != null) {
            mHandler.post(new Runnable() {
                @Override
                public void run() {
                    mBeautyEffect.targetPath = effectPath;
                }
            });
        }
    }

    /**
     * 是否启用特效
     *
     * @param enable 是否启用特效
     */
    public void setBeautyEffectEnable(final boolean enable) {
        checkHandler();
        if (mHandler != null) {
            mHandler.post(new Runnable() {
                @Override
                public void run() {
                    mBeautyEffect.enable = enable;
                }
            });
        }
    }

    public void setFilterEffectPath(final String effectPath) {
        if (mHandler != null) {
            mHandler.post(new Runnable() {
                @Override
                public void run() {
                    mFilterEffect.targetPath = effectPath;
                }
            });
        }
    }

    public void setFilterEffectEnable(final boolean enable) {
        if (mHandler != null) {
            mHandler.post(new Runnable() {
                @Override
                public void run() {
                    mFilterEffect.enable = enable;
                }
            });
        }
    }

    public void setStickerEffectPath(final String effectPath) {
        if (mHandler != null) {
            mHandler.post(new Runnable() {
                @Override
                public void run() {
                    mStickerEffect.targetPath = effectPath;
                }
            });
        }
    }

    public void setStickerEffectEnable(final boolean enable) {
        if (mHandler != null) {
            mHandler.post(new Runnable() {
                @Override
                public void run() {
                    mStickerEffect.enable = enable;
                }
            });
        }
    }

    public void setGestureEffectPath(final String effectPath) {
        if (mHandler != null) {
            mHandler.post(new Runnable() {
                @Override
                public void run() {
                    mGestureEffect.targetPath = effectPath;
                }
            });
        }

    }

    public void setGestureEffectEnable(final boolean enable) {
        if (mHandler != null) {
            mHandler.post(new Runnable() {
                @Override
                public void run() {
                    mGestureEffect.enable = enable;
                }
            });
        }
    }

    public void setGestureGoodEffect(final String effectPath) {
        if (mHandler != null) {
            mHandler.post(new Runnable() {
                @Override
                public void run() {
                    mGestureGoodEffect.targetPath = effectPath;
                }
            });
        }
    }

    public void setGestureGoodEnable(final boolean enable) {
        if (mHandler != null) {
            mHandler.post(new Runnable() {
                @Override
                public void run() {
                    mGestureGoodEffect.enable = enable;
                }
            });
        }
    }


    public void setGestureSingleLovePath(final String effectPath) {
        if (mHandler != null) {
            mHandler.post(new Runnable() {
                @Override
                public void run() {
                    mGestureSingleLoveEffect.targetPath = effectPath;
                }
            });
        }
    }

    public void setGestureSingleLoveEnable(final boolean enable) {
        if (mHandler != null) {
            mHandler.post(new Runnable() {
                @Override
                public void run() {
                    mGestureSingleLoveEffect.enable = enable;
                }
            });
        }
    }

    public void setGestureDoubleLovePath(final String effectPath) {
        if (mHandler != null) {
            mHandler.post(new Runnable() {
                @Override
                public void run() {
                    mGestureDoubleLoveEffect.targetPath = effectPath;
                }
            });
        }
    }

    public void setGestureDoubleLoveEnable(final boolean enable) {
        if (mHandler != null) {
            mHandler.post(new Runnable() {
                @Override
                public void run() {
                    mGestureDoubleLoveEffect.enable = enable;
                }
            });
        }
    }

    public void setGestureSixPath(final String effectPath) {
        if (mHandler != null) {
            mHandler.post(new Runnable() {
                @Override
                public void run() {
                    mGestureSixEffect.targetPath = effectPath;
                }
            });
        }
    }

    public void setGestureSixEnable(final boolean enable) {
        if (mHandler != null) {
            mHandler.post(new Runnable() {
                @Override
                public void run() {
                    mGestureSixEffect.enable = enable;
                }
            });
        }
    }

    public void setGestureVPath(final String effectPath) {
        if (mHandler != null) {
            mHandler.post(new Runnable() {
                @Override
                public void run() {
                    mGestureVEffect.targetPath = effectPath;
                }
            });
        }
    }

    public void setGestureVEnable(final boolean enable) {
        if (mHandler != null){
            mHandler.post(new Runnable() {
                @Override
                public void run() {
                    mGestureVEffect.enable = enable;
                }
            });
        }
    }

    public void setGestureOkPath(final String effectPath) {
        if (mHandler != null) {
            mHandler.post(new Runnable() {
                @Override
                public void run() {
                    mGestureOkEffect.targetPath = effectPath;
                }
            });
        }
    }

    public void setGestureOkEnable(final boolean enable) {
        if (mHandler != null) {
            mHandler.post(new Runnable() {
                @Override
                public void run() {
                    mGestureOkEffect.enable = enable;
                }
            });
        }
    }

    public void setGestureHandPath(final String effectPath) {
        if (mHandler != null) {
            mHandler.post(new Runnable() {
                @Override
                public void run() {
                    mGestureHandEffect.targetPath = effectPath;
                }
            });
        }
    }

    public void setGestureHandEnable(final boolean enable) {
        if (mHandler != null) {
            mHandler.post(new Runnable() {
                @Override
                public void run() {
                    mGestureHandEffect.enable = enable;
                }
            });
        }
    }

    /**
     * 关闭所有手势
     */
    public void closeAllGestureEffect() {
        if (mHandler != null) {
            mHandler.post(new Runnable() {
                @Override
                public void run() {
                    resetEffect();
                }
            });
        }
    }

    private void resetEffect() {
        mGestureGoodEffect.enable = false;
        mGestureGoodEffect.targetPath = null;
        mGestureSingleLoveEffect.enable = false;
        mGestureSingleLoveEffect.targetPath = null;
        mGestureDoubleLoveEffect.enable = false;
        mGestureDoubleLoveEffect.targetPath = null;
        mGestureSixEffect.enable = false;
        mGestureSixEffect.targetPath = null;
        mGestureHandEffect.enable = false;
        mGestureHandEffect.targetPath = null;
        mGestureVEffect.enable = false;
        mGestureVEffect.targetPath = null;
        mGestureOkEffect.enable = false;
        mGestureOkEffect.targetPath = null;
    }


    public class VideoCaptureWrapper implements IVideoCaptureObserver {

        /**
         * 负责回调camera采集的原始YUV(NV21)给客户
         * onCaptureVideoFrame
         *
         * @param width  视频数据宽
         * @param height 视频数据高
         * @param data   视频NV21数据
         * @param length 视频数据长度
         */
        @Override
        public void onCaptureVideoFrame(int width, int height, byte[] data, int length, int imageFormat) {
            synchronized (mHandleLock) {
                mImageData = data;
                mImgHeight = height;
                mImgWidth = width;

            }
        }
    }

    class Effect {
        private String targetPath;
        private String currentPath;
        private int effect;
        private boolean enable = true;
    }
}