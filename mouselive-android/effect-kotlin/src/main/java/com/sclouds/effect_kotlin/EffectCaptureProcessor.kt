package com.sclouds.effect_kotlin

import android.opengl.GLES11Ext
import android.opengl.GLES20
import com.orangefilter.OrangeFilter
import com.orangefilter.OrangeFilter.OF_FrameData
import com.orangefilter.OrangeFilter.OF_Texture
import com.sclouds.common.utils.Accelerometer
import com.sclouds.effect_kotlin.utils.BeautyHelper
import com.sclouds.effect_kotlin.utils.CameraUtil
import com.sclouds.effect_kotlin.utils.FilterHelper
import com.thunder.livesdk.video.IVideoCaptureObserver
import com.yy.mediaframework.CameraInterface
import com.yy.mediaframework.gles.Drawable2d
import com.yy.mediaframework.gpuimage.custom.IGPUProcess
import com.yy.mediaframework.gpuimage.util.GLShaderProgram
import com.yy.mediaframework.gpuimage.util.GLTexture
import java.io.File
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.FloatBuffer
import java.nio.IntBuffer
import java.util.*
import java.util.logging.Logger

/**
 * Created by zhouwen on 2020/4/22.
 * OF特效具体实现类
 */
class EffectCaptureProcessor(venusModelPath: String?) : IGPUProcess {
    private val mVertexBuffer = ByteBuffer.allocateDirect(CUBE.size * 4)
            .order(ByteOrder.nativeOrder())
            .asFloatBuffer()
    private var mNoEffectShader: GLShaderProgram? = null
    private var mPassthroughShader: GLShaderProgram? = null
    private lateinit var mInputTexture: GLTexture
    private lateinit var mOutputTexture: GLTexture
    private var mFramebuffer: IntBuffer? = null
    private var mOldFramebuffer: IntBuffer? = null
    private val mRectDrawable = Drawable2d(Drawable2d.Prefab.FULL_RECTANGLE)
    private var mTextureTarget = 0
    private var mOutputWidth = 0
    private var mOutputHeight = 0
    private var mHasInit = false
    private var mOfContextId = 0
    private var mVenusModelPath: String? = null

    /**
     * 美颜
     */
    private var mBeautyEffect = Effect()

    /**
     * 滤镜
     */
    private var mFilterEffect = Effect()

    /**
     * 贴纸
     */
    private var mStickerEffect = Effect()

    /**
     * 一类手势
     */
    private var mGestureEffect = Effect()

    /**
     * 手势子类型:点赞，单手比心，双手比心，666，手掌，比V，OK
     */
    private var mGestureGoodEffect = Effect()
    private var mGestureSingleLoveEffect = Effect()
    private var mGestureDoubleLoveEffect = Effect()
    private var mGestureSixEffect = Effect()
    private var mGestureHandEffect = Effect()
    private var mGestureVEffect = Effect()
    private var mGestureOkEffect = Effect()
    private var mBeautyHelper: BeautyHelper? = null
    private var mFilterHelper: FilterHelper? = null
    private var mFrameData: OF_FrameData? = null
    private lateinit var mInputs: Array<OF_Texture?>
    private lateinit var mOutputs: Array<OF_Texture?>
    private val mStartTime: Long = 0
    private var mFrameCount = 0
    private var mFrameTime: Long = 0
    private lateinit var mImageData: ByteArray
    private var mImgHeight = 0
    private var mImgWidth = 0
    private val mHandleLock = Any()
    fun setEffectHelper(beautyHelper: BeautyHelper?, filterHelper: FilterHelper?) {
        mBeautyHelper = beautyHelper
        mFilterHelper = filterHelper
    }

    /**
     * 视频openGl渲染线程初始化回调
     * 详见md文档介绍
     */
    override fun onInit(textureTarget: Int, outputWidth: Int, outputHeight: Int) {
        sLogger.info("chowen#GPUImageBeautyOrangeFilter onInit OF")
        mOfContextId = OrangeFilter.createContext(mVenusModelPath)
        if (mOfContextId == 0) {
            sLogger.info("OrangeFilter SDK初始化失败，请检查授权是否过期。")
        } else {
            sLogger.info("onInit#mOfContextId=$mOfContextId")
        }

        // Init temp textures.
        if (mInputTexture == null || mOutputTexture == null) {
            mInputTexture = GLTexture(GLES20.GL_TEXTURE_2D)
            mOutputTexture = GLTexture(GLES20.GL_TEXTURE_2D)
        }
        mTextureTarget = textureTarget
        mOutputWidth = outputWidth
        mOutputHeight = outputHeight
        if (textureTarget == GLES11Ext.GL_TEXTURE_EXTERNAL_OES) {
            noeffect_fs = mOESFragmentShader
        }
        mVertexBuffer.put(CUBE).position(0)
        mFramebuffer = IntBuffer.allocate(1)
        GLES20.glGenFramebuffers(1, mFramebuffer)
        mNoEffectShader = GLShaderProgram()
        mNoEffectShader?.setProgram(noeffect_vs, noeffect_fs)
        mPassthroughShader = GLShaderProgram()
        mPassthroughShader?.setProgram(passthrouth_vs, passthrouth_fs)
        mOldFramebuffer = IntBuffer.allocate(1)
        mHasInit = true

        //init渲染数据
        mFrameData = OF_FrameData()
        mInputs = arrayOfNulls(1)
        mOutputs = arrayOfNulls(1)
        mInputs[0] = OF_Texture()
        mOutputs[0] = OF_Texture()
        mBeautyEffect.effect = 0
        mFilterEffect.effect = 0
        mStickerEffect.effect = 0
        mGestureEffect.effect = 0
        mGestureGoodEffect.effect = 0
        mGestureSingleLoveEffect.effect = 0
        mGestureDoubleLoveEffect.effect = 0
        mGestureSixEffect.effect = 0
        mGestureHandEffect.effect = 0
        mGestureVEffect.effect = 0
        mGestureOkEffect.effect = 0
    }

    /**
     * 视频openGl渲染线程销毁回调
     * 详见md文档介绍
     */
    override fun onDestroy() {
        sLogger.info("onDestroy OF Render")
        // Destory all opengl objects.
        mHasInit = false
        GLES20.glDeleteFramebuffers(1, mFramebuffer)
        if (mInputTexture != null) {
            mInputTexture?.destory()
            mOutputTexture?.destory()
        }

        //销毁Shader
        mNoEffectShader?.destory()
        mPassthroughShader?.destory()

        // 销毁 orangeFilter
        destroyOFEffect()
    }

    /**
     * destroy Effect
     *
     * @param effect 特效
     */
    private fun destroyEffect(effect: Effect?) {
        if (effect != null && effect.effect != 0) {
            OrangeFilter.destroyEffect(mOfContextId, effect.effect)
            effect.effect = 0
            effect.currentPath = null
        }
    }

    /**
     * 销毁 OrangeFilter Context 资源
     */
    private fun destroyOFEffect() {
        destroyEffect(mBeautyEffect)
        destroyEffect(mFilterEffect)
        destroyEffect(mStickerEffect)
        destroyEffect(mGestureEffect)
        destroyEffect(mGestureGoodEffect)
        destroyEffect(mGestureSingleLoveEffect)
        destroyEffect(mGestureDoubleLoveEffect)
        destroyEffect(mGestureSixEffect)
        destroyEffect(mGestureHandEffect)
        destroyEffect(mGestureVEffect)
        destroyEffect(mGestureOkEffect)
        if (mOfContextId != 0) {
            OrangeFilter.destroyContext(mOfContextId)
            mOfContextId = 0
        }
        mBeautyHelper?.clearEffect()
        mFilterHelper?.clearEffect()
    }

    /**
     * openGl渲染，内部工具函数，业务不用关心
     */
    private fun drawQuad(shader: GLShaderProgram?, cubeBuffer: FloatBuffer, textureBuffer: FloatBuffer) {
        cubeBuffer.position(0)
        shader?.setVertexAttribPointer("aPosition", 2, GLES20.GL_FLOAT, false, 0, cubeBuffer)
        textureBuffer.position(0)
        shader?.setVertexAttribPointer("aTextureCoord", 2, GLES20.GL_FLOAT, false, 0, textureBuffer)
        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4)
        shader?.disableVertexAttribPointer("aPosition")
        shader?.disableVertexAttribPointer("aTextureCoord")
    }

    /**
     * 从素材包文件创建特效
     *
     * @param effect 特效
     * @return
     */
    private fun updateEffect(effect: Effect): Boolean {
        var updated = false
        if (effect.targetPath != null &&
                (effect.currentPath == null || effect.currentPath != effect.targetPath)) {
            effect.currentPath = effect.targetPath
            if (effect.effect != 0) {
                // 销毁 Effect
                OrangeFilter.destroyEffect(mOfContextId, effect.effect)
                effect.effect = 0
                updated = true
            }
            if (effect.currentPath?.length!! > 0) {
                if (File(effect.currentPath).exists()) {
                    // 从素材包文件创建特效
                    effect.effect = OrangeFilter.createEffectFromPackage(mOfContextId, effect.currentPath)
                    if (effect.effect != 0) {
                        updated = true
                    }
                } else {
                    sLogger.severe("effect file not exist: " + effect.currentPath)
                }
            }
        }
        return updated
    }

    /**
     * 视频openGl渲染线程每一帧渲染回调
     * 详见md文档介绍
     */
    override fun onDraw(textureId: Int, textureBuffer: FloatBuffer) {
        onDraw(textureId, mVertexBuffer, textureBuffer)
    }

    private fun onDraw(textureId: Int, cubeBuffer: FloatBuffer, textureBuffer: FloatBuffer) {
        if (!mHasInit || mOfContextId == 0) {
            sLogger.info("onDraw not ready")
            return
        }
        // Record old fbo.
        GLES20.glGetIntegerv(GLES20.GL_FRAMEBUFFER_BINDING, mOldFramebuffer)
        if (mInputTexture?.width != mOutputWidth || mInputTexture?.height != mOutputHeight) {
            mInputTexture?.create(mOutputWidth, mOutputHeight, GLES20.GL_RGBA)
            mOutputTexture?.create(mOutputWidth, mOutputHeight, GLES20.GL_RGBA)
            sLogger.info("[sjc] mOutputWidth: " + mOutputWidth + " ,mOutputHeight: " +
                    mOutputHeight)
        }

        // update effects if need
        val beautyUpdated = updateEffect(mBeautyEffect)
        sLogger.info("chowen#beautyUpdated=" + beautyUpdated + ">>effect>>" + mBeautyEffect.effect)
        if (beautyUpdated) {
            mBeautyHelper?.setEffect(mOfContextId, mBeautyEffect.effect)
        }
        val filterUpdated = updateEffect(mFilterEffect)
        if (filterUpdated) {
            mFilterHelper?.setEffect(mOfContextId, mFilterEffect.effect)
        }
        updateEffect(mStickerEffect)
        // 一组手势（手势特效包集）
        updateEffect(mGestureEffect)
        // 分类手势 （细分特效类:点赞，单手比心，双手比心，666，手掌，比V，OK）
        updateEffect(mGestureGoodEffect)
        updateEffect(mGestureSingleLoveEffect)
        updateEffect(mGestureDoubleLoveEffect)
        updateEffect(mGestureSixEffect)
        updateEffect(mGestureHandEffect)
        updateEffect(mGestureVEffect)
        updateEffect(mGestureOkEffect)

        // textureIn 是摄像头采集的图像，textureOut 是叠加特效后最终渲染到屏幕的图像。
        mInputs[0]?.width = mInputTexture?.width
        mInputs[0]?.height = mInputTexture?.height
        mInputs[0]?.format = GLES20.GL_RGBA
        mInputs[0]?.target = mInputTexture?.target
        mInputs[0]?.textureID = mInputTexture?.textureId
        mOutputs[0]?.width = mOutputTexture?.width
        mOutputs[0]?.height = mOutputTexture?.height
        mOutputs[0]?.format = GLES20.GL_RGBA
        mOutputs[0]?.target = mOutputTexture?.target
        mOutputs[0]?.textureID = mOutputTexture?.textureId

        // yuv帧数据
        mFrameData?.imageData = mImageData
        mFrameData?.width = mImgWidth
        mFrameData?.height = mImgHeight
        mFrameData?.widthStep = mFrameData?.width
        mFrameData?.format = OrangeFilter.OF_PixelFormat_NV21
        mFrameData?.timestamp = (System.currentTimeMillis() - mStartTime) / 1000.0f
        mFrameData?.isUseCustomHarsLib = false
        mFrameData?.trackOn = false
        mFrameData?.curNode = 0
        mFrameData?.pickOn = false
        mFrameData?.pickResult = false
        mFrameData?.imageDir = Accelerometer.getDirection()
        mFrameData?.orientation = CameraUtil.getCameraRotation()
        mFrameData?.frontCamera = CameraUtil.isFrontCamera()

        if (mBeautyEffect.effect != 0 || mFilterEffect.effect != 0 || mStickerEffect.effect != 0 || mGestureEffect.effect != 0 || mGestureGoodEffect.effect != 0 || mGestureSingleLoveEffect.effect != 0 || mGestureDoubleLoveEffect.effect != 0 || mGestureSixEffect.effect != 0 || mGestureHandEffect.effect != 0 || mGestureVEffect.effect != 0 || mGestureOkEffect.effect != 0) {

            //  数据预处理，如人脸跟踪点的姿态估计
            OrangeFilter.prepareFrameData(mOfContextId, mFrameData)
            val effects = Vector<Int>()

            //  是否设置美颜，滤镜，贴纸
            if (mBeautyEffect.effect != 0 && mBeautyEffect.enable) {
                effects.add(mBeautyEffect.effect)
            }
            if (mFilterEffect.effect != 0 && mFilterEffect.enable) {
                effects.add(mFilterEffect.effect)
            }
            if (mStickerEffect.effect != 0 && mStickerEffect.enable) {
                effects.add(mStickerEffect.effect)
            }
            // 是否设置手势
            if (mGestureEffect.effect != 0 && mGestureEffect.enable) {
                effects.add(mGestureEffect.effect)
            }
            // 是否设置手势特效子类型:点赞，单手比心，双手比心，666，手掌，比V，OK
            if (mGestureGoodEffect.effect != 0 && mGestureGoodEffect.enable) {
                effects.add(mGestureGoodEffect.effect)
            }
            if (mGestureSingleLoveEffect.effect != 0 && mGestureSingleLoveEffect.enable) {
                effects.add(mGestureSingleLoveEffect.effect)
            }
            if (mGestureDoubleLoveEffect.effect != 0 && mGestureDoubleLoveEffect.enable) {
                effects.add(mGestureDoubleLoveEffect.effect)
            }
            if (mGestureSixEffect.effect != 0 && mGestureSixEffect.enable) {
                effects.add(mGestureSixEffect.effect)
            }
            if (mGestureHandEffect.effect != 0 && mGestureHandEffect.enable) {
                effects.add(mGestureHandEffect.effect)
            }
            if (mGestureVEffect.effect != 0 && mGestureVEffect.enable) {
                effects.add(mGestureVEffect.effect)
            }
            if (mGestureOkEffect.effect != 0 && mGestureOkEffect.enable) {
                effects.add(mGestureOkEffect.effect)
            }
            if (effects.size > 0) {
                // Camera 出来的OES纹理转成2D纹理，OrangeFilter输入需要2D纹理
                mInputTexture?.bindFBO(mFramebuffer!![0])
                GLES20.glClearColor(0f, 0f, 0f, 1f)
                GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT)
                mNoEffectShader?.useProgram()
                mNoEffectShader?.setUniformTexture("uTexture0", 0, textureId, mTextureTarget)
                drawQuad(mNoEffectShader, cubeBuffer, textureBuffer)
                val effectArray = IntArray(effects.size)
                val resultArray = IntArray(effects.size)
                for (i in effects.indices) {
                    effectArray[i] = effects[i]
                }

                // 渲染帧特效
                val a = OrangeFilter.applyFrameBatch(mOfContextId, effectArray, mInputs, mOutputs, resultArray)
                swap(mInputTexture, mOutputTexture)

                // Draw output texture.
                GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, mOldFramebuffer!![0])
                mPassthroughShader?.useProgram()
                mPassthroughShader
                        ?.setUniformTexture("uTexture0", 0, mInputTexture!!.textureId, mInputTexture!!.target)
                drawQuad(mPassthroughShader, mRectDrawable.vertexArray, mRectDrawable.texCoordArray)
                // Restore OpenGL states.
                GLES20.glBindTexture(mTextureTarget, 0)
            } else {
                if (mTextureTarget == GLES11Ext.GL_TEXTURE_EXTERNAL_OES) {
                    // Draw original texture
                    mNoEffectShader?.useProgram()
                    mNoEffectShader?.setUniformTexture("uTexture0", 0, textureId, mTextureTarget)
                    drawQuad(mNoEffectShader, cubeBuffer, textureBuffer)
                    // Restore OpenGL states.
                    GLES20.glBindTexture(mTextureTarget, 0)
                }
            }
        } else {
            if (mTextureTarget == GLES11Ext.GL_TEXTURE_EXTERNAL_OES) {
                // Draw original texture
                mNoEffectShader?.useProgram()
                mNoEffectShader?.setUniformTexture("uTexture0", 0, textureId, mTextureTarget)
                drawQuad(mNoEffectShader, cubeBuffer, textureBuffer)
                // Restore OpenGL states.
                GLES20.glBindTexture(mTextureTarget, 0)
            }
        }
        mFrameCount++
        val now = System.currentTimeMillis()
        if (now - mFrameTime > 1000) {
            val fps = mFrameCount
            mFrameCount = 0
            mFrameTime = now
            sLogger.severe("fps: $fps")
        }
    }

    private fun swap(glIn: GLTexture, glOut: GLTexture) {
        val inId = glIn.textureId
        val outId = glOut.textureId
        glIn.textureId = outId
        glOut.textureId = inId
    }

    /**
     * 视频帧纹理大小回调
     * 详见md文档介绍
     */
    override fun onOutputSizeChanged(width: Int, height: Int) {
        sLogger.info("onOutputSizeChanged OF width: $width ,height: $height")
        mOutputWidth = width
        mOutputHeight = height
    }

    /**
     * 根据特效类型设置对应特效path
     *
     * @param effectPath 特效包路径
     */
    fun setBeautyEffectPath(effectPath: String?) {
        mBeautyEffect.targetPath = effectPath
    }

    /**
     * 是否启用特效
     *
     * @param enable 是否启用特效
     */
    fun setBeautyEffectEnable(enable: Boolean) {
        mBeautyEffect.enable = enable
    }

    fun setFilterEffectPath(effectPath: String?) {
        mFilterEffect.targetPath = effectPath
    }

    fun setFilterEffectEnable(enable: Boolean) {
        mFilterEffect.enable = enable
    }

    fun setStickerEffectPath(effectPath: String?) {
        mStickerEffect.targetPath = effectPath
    }

    fun setStickerEffectEnable(enable: Boolean) {
        mStickerEffect.enable = enable
    }

    fun setGestureEffectPath(effectPath: String?) {
        mGestureEffect.targetPath = effectPath
    }

    fun setGestureEffectEnable(enable: Boolean) {
        mGestureEffect.enable = enable
    }

    fun setGestureGoodEffect(effectPath: String?) {
        mGestureGoodEffect.targetPath = effectPath
    }

    fun setGestureGoodEnable(enable: Boolean) {
        mGestureGoodEffect.enable = enable
    }

    fun setGestureSingleLovePath(effectPath: String?) {
        mGestureSingleLoveEffect.targetPath = effectPath
    }

    fun setGestureSingleLoveEnable(enable: Boolean) {
        mGestureSingleLoveEffect.enable = enable
    }

    fun setGestureDoubleLovePath(effectPath: String?) {
        mGestureDoubleLoveEffect.targetPath = effectPath
    }

    fun setGestureDoubleLoveEnable(enable: Boolean) {
        mGestureDoubleLoveEffect.enable = enable
    }

    fun setGestureSixPath(effectPath: String?) {
        mGestureSixEffect.targetPath = effectPath
    }

    fun setGestureSixEnable(enable: Boolean) {
        mGestureSixEffect.enable = enable
    }

    fun setGestureVPath(effectPath: String?) {
        mGestureVEffect.targetPath = effectPath
    }

    fun setGestureVEnable(enable: Boolean) {
        mGestureVEffect.enable = enable
    }

    fun setGestureOkPath(effectPath: String?) {
        mGestureOkEffect.targetPath = effectPath
    }

    fun setGestureOkEnable(enable: Boolean) {
        mGestureOkEffect.enable = enable
    }

    fun setGestureHandPath(effectPath: String?) {
        mGestureHandEffect.targetPath = effectPath
    }

    fun setGestureHandEnable(enable: Boolean) {
        mGestureHandEffect.enable = enable
    }

    /**
     * 关闭所有手势
     */
    fun closeAllGestureEffect() {
        mGestureGoodEffect.enable = false
        mGestureGoodEffect.targetPath = null
        mGestureSingleLoveEffect.enable = false
        mGestureSingleLoveEffect.targetPath = null
        mGestureDoubleLoveEffect.enable = false
        mGestureDoubleLoveEffect.targetPath = null
        mGestureSixEffect.enable = false
        mGestureSixEffect.targetPath = null
        mGestureHandEffect.enable = false
        mGestureHandEffect.targetPath = null
        mGestureVEffect.enable = false
        mGestureVEffect.targetPath = null
        mGestureOkEffect.enable = false
        mGestureOkEffect.targetPath = null
    }

    /**
     * 负责回调camera采集的原始YUV(NV21)给客户
     * onCaptureVideoFrame
     *
     * @param width  视频数据宽
     * @param height 视频数据高
     * @param data   视频NV21数据
     * @param length 视频数据长度
     */
    inner class VideoCaptureWrapper : IVideoCaptureObserver {
        override fun onCaptureVideoFrame(width: Int, height: Int, data: ByteArray, length: Int, imageFormat: Int) {
            sLogger.severe("GPUImageBeautyOrangeFilter.onCaptureVideoFrame# mImageData$data>>mImgWidth=$width>>mImgHeight=$height")
            synchronized(mHandleLock) {
                mImageData = data
                mImgHeight = height
                mImgWidth = width
            }
        }
    }

    internal inner class Effect {
        var targetPath: String? = null
        var currentPath: String? = null
        var effect = 0
        var enable = true
    }

    companion object {
        private val sLogger = Logger.getLogger("EffectCaptureProcessor")
        private const val noeffect_vs = "attribute vec4 aPosition;\n" +
                "attribute vec4 aTextureCoord;\n" +
                "varying vec2 vTexCoord;\n" +
                "\n" +
                "void main()\n" +
                "{\n" +
                "    gl_Position = aPosition;\n" +
                "    vTexCoord = aTextureCoord.xy;\n" +
                "}"
        private var noeffect_fs = """precision mediump float;
varying vec2 vTexCoord;
uniform sampler2D uTexture0;

void main()
{
    vec4 color = texture2D(uTexture0, vTexCoord);
    gl_FragColor = color; //vec4(color.y, color.y, color.y, 1.0);
}"""
        private const val passthrouth_vs = "attribute vec4 aPosition;\n" +
                "attribute vec4 aTextureCoord;\n" +
                "varying vec2 vTexCoord;\n" +
                "\n" +
                "void main()\n" +
                "{\n" +
                "    gl_Position = aPosition;\n" +
                "    vTexCoord = aTextureCoord.xy;\n" +
                "}"
        private const val passthrouth_fs = "precision mediump float;\n" +
                "varying vec2 vTexCoord;\n" +
                "uniform sampler2D uTexture0;\n" +
                "\n" +
                "void main()\n" +
                "{\n" +
                "    vec4 color = texture2D(uTexture0, vTexCoord);\n" +
                "    gl_FragColor = color; //vec4(color.y, color.y, color.y, 1.0);\n" +
                "}"
        private val mOESFragmentShader = "#extension GL_OES_EGL_image_external : require\n" +
                noeffect_fs.replace("uniform sampler2D uTexture0;",
                        "uniform samplerExternalOES uTexture0;")
        private val CUBE = floatArrayOf(
                -1.0f, -1.0f,
                1.0f, -1.0f,
                -1.0f, 1.0f,
                1.0f, 1.0f)
    }

    init {
        sLogger.info("GPUImageBeautyOrangeFilter construct venusModelPath=$venusModelPath")
        mVenusModelPath = venusModelPath
    }
}