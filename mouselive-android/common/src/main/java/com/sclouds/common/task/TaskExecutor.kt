package com.sclouds.common.task

import android.os.Handler
import android.os.Looper
import java.util.concurrent.*
import java.util.concurrent.atomic.AtomicInteger

/**
 *Created by zhouwen on 2020-02-02.
 */
object TaskExecutor {
    //    companion object {
    val CPU_COUNT = Runtime.getRuntime().availableProcessors()

    val CORE_POOL_SIZE = CPU_COUNT + 1

    val MAXIMUM_POOL_SIZE = CPU_COUNT * 2 + 1

    val KEEP_ALIVE: Long = 1

    val CAPACITY = 128

    val sThreadFactory: ThreadFactory =
        object : ThreadFactory {
            val mCount =
                AtomicInteger(1)

            override fun newThread(r: Runnable): Thread {
                return Thread(r, "TaskExecutor #" + mCount.getAndIncrement())
            }
        }

    val sPoolWorkQueue: BlockingQueue<Runnable> = LinkedBlockingQueue(CAPACITY)

    lateinit var sScheduledThreadPoolExecutor: ScheduledThreadPoolExecutor
    var mMainHandler: Handler =  Handler(Looper.getMainLooper())

    val sThreadPoolExecutor: ThreadPoolExecutor =
        ThreadPoolExecutor(
            CORE_POOL_SIZE,
            MAXIMUM_POOL_SIZE,
            KEEP_ALIVE,
            TimeUnit.SECONDS,
            sPoolWorkQueue,
            sThreadFactory
        )

    /**
     * 线程池任务
     * @param r Runnable
     */
    fun execute(r: Runnable?) {
        sThreadPoolExecutor.execute(r)
    }

    /**
     * shutdown threadPool-->now
     * see java.util.concurrent.ScheduledThreadPoolExecutor#shutdownNow()
     */
    fun shutdownNow() {
        if (sScheduledThreadPoolExecutor != null) {
            sScheduledThreadPoolExecutor.shutdownNow()
        }
    }

    @Synchronized
    fun checkHandler() {
        if (mMainHandler == null)
            mMainHandler = Handler(Looper.getMainLooper())
    }

    fun checkScheduledThreadPoolExecutor() {
        if (sScheduledThreadPoolExecutor == null)
            sScheduledThreadPoolExecutor = ScheduledThreadPoolExecutor(1);
    }

    /**
     * schedule execute 任务
     * @param r Runnable
     * @param delayMillis delay 时间 单位：毫秒
     * @return
     */
    fun scheduleExecuteTask(
        r: Runnable?,
        delayMillis: Long
    ): ScheduledFuture<*>? {
        checkScheduledThreadPoolExecutor()
        return sScheduledThreadPoolExecutor.schedule(
            r,
            delayMillis,
            TimeUnit.MILLISECONDS
        )
    }

    /**
     * 按频率执行
     * @param r Runnable
     * @param initialDelay 初始 delay
     * @param delayMillis delay 时间 单位：毫秒
     * @return ScheduledFuture
     */
    fun scheduleAtFixedRate(
        r: Runnable?,
        initialDelay: Long,
        delayMillis: Long
    ): ScheduledFuture<*>? {
        checkScheduledThreadPoolExecutor()
        return sScheduledThreadPoolExecutor.scheduleAtFixedRate(
            r, initialDelay,
            delayMillis, TimeUnit.MILLISECONDS
        )
    }

    /**
     * 在UI线程执行
     * @param r Runnable
     * @return see android.os.Handler#post(java.lang.Runnable)
     */
    fun executeRunOnUIExecutorTask(r: Runnable?): Boolean {
        checkHandler()
        return mMainHandler.post(r)
    }

    /**
     * 在UI线程按设置delay时间执行
     * @param r Runnable
     * @param delayMillis delay 时间  单位：毫秒
     * @return see android.os.Handler#postDelayed(java.lang.Runnable, long)
     */
    fun executeScheduleRunOnUIExecutorTask(
        r: Runnable?,
        delayMillis: Long
    ): Boolean {
        checkHandler()
        return mMainHandler.postDelayed(r, delayMillis)
    }

    /**
     * remove task
     * @param r Runnable
     */
    fun removeUITask(r: Runnable?) {
        checkHandler()
        mMainHandler.removeCallbacks(r)
    }

    /**
     * 获取线程池实例
     * @return thread pool
     */
    fun getTaskExecutor(): Executor? {
        return sThreadPoolExecutor
    }

    /**
     * shutdown threadPool
     */
    fun shutdown() {
        if (sScheduledThreadPoolExecutor != null) sScheduledThreadPoolExecutor.shutdown()
    }
}