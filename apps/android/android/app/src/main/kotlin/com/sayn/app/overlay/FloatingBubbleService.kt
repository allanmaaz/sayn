package com.sayn.app.overlay

import android.animation.ValueAnimator
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.IBinder
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.view.animation.DecelerateInterpolator
import android.widget.FrameLayout
import android.widget.ImageView
import androidx.core.app.NotificationCompat

class FloatingBubbleService : Service() {

    private lateinit var windowManager: WindowManager
    private lateinit var prefs: SharedPreferences
    private var bubbleView: View? = null
    private var panelView: FloatingPanelView? = null
    private var isPanelOpen = false

    companion object {
        var isRunning = false
            private set
        private const val CHANNEL_ID = "sayn_overlay_channel"
        private const val NOTIFICATION_ID = 1001
        private const val PREFS_KEY_X = "bubble_pos_x"
        private const val PREFS_KEY_Y = "bubble_pos_y"
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        isRunning = true
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        prefs = getSharedPreferences("com.sayn.app.PREFS", Context.MODE_PRIVATE)
        startForegroundServiceNotification()
        createFloatingBubble()
    }

    private fun startForegroundServiceNotification() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "SAYN Floating Assistant",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }

        val notification: Notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("SAYN Floating Assistant")
            .setContentText("Tap the floating bubble to dictate or refine text.")
            .setSmallIcon(android.R.drawable.ic_btn_speak_now)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()

        startForeground(NOTIFICATION_ID, notification)
    }

    private fun createFloatingBubble() {
        val layoutType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }

        // Restore saved position or default to near right edge
        val savedX = prefs.getInt(PREFS_KEY_X, 20)
        val savedY = prefs.getInt(PREFS_KEY_Y, 240)

        val bubbleParams = WindowManager.LayoutParams(
            dpToPx(56),
            dpToPx(56),
            layoutType,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = savedX
            y = savedY
        }

        val container = FrameLayout(this).apply {
            val bg = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(Color.parseColor("#151518"))
                setStroke(dpToPx(1.5f), Color.parseColor("#303036"))
            }
            background = bg
            elevation = dpToPx(8).toFloat()
        }

        val micIcon = ImageView(this).apply {
            setImageResource(android.R.drawable.ic_btn_speak_now)
            setColorFilter(Color.parseColor("#5DE4FF")) // Restrained cyan strictly for audio mic
            layoutParams = FrameLayout.LayoutParams(
                dpToPx(28),
                dpToPx(28),
                Gravity.CENTER
            )
        }
        container.addView(micIcon)

        // Dragging & Smooth Edge-Snapping Touch Listener
        container.setOnTouchListener(object : View.OnTouchListener {
            private var initialX = 0
            private var initialY = 0
            private var touchX = 0f
            private var touchY = 0f
            private var isDragging = false

            override fun onTouch(v: View, event: MotionEvent): Boolean {
                when (event.action) {
                    MotionEvent.ACTION_DOWN -> {
                        initialX = bubbleParams.x
                        initialY = bubbleParams.y
                        touchX = event.rawX
                        touchY = event.rawY
                        isDragging = false
                        return true
                    }
                    MotionEvent.ACTION_MOVE -> {
                        val dx = (event.rawX - touchX).toInt()
                        val dy = (event.rawY - touchY).toInt()
                        if (Math.abs(dx) > 12 || Math.abs(dy) > 12) {
                            isDragging = true
                            bubbleParams.x = initialX + dx
                            bubbleParams.y = initialY + dy
                            windowManager.updateViewLayout(container, bubbleParams)
                        }
                        return true
                    }
                    MotionEvent.ACTION_UP -> {
                        if (!isDragging) {
                            toggleAssistantPanel(bubbleParams.x, bubbleParams.y)
                        } else {
                            // Snap to nearest edge (left or right)
                            snapToNearestEdge(container, bubbleParams)
                        }
                        return true
                    }
                }
                return false
            }
        })

        bubbleView = container
        windowManager.addView(container, bubbleParams)
    }

    private fun snapToNearestEdge(view: View, params: WindowManager.LayoutParams) {
        val screenWidth = resources.displayMetrics.widthWidth()
        val targetX = if (params.x + dpToPx(28) < screenWidth / 2) dpToPx(12) else screenWidth - dpToPx(68)

        val animator = ValueAnimator.ofInt(params.x, targetX).apply {
            duration = 200
            interpolator = DecelerateInterpolator()
            addUpdateListener { anim ->
                params.x = anim.animatedValue as Int
                windowManager.updateViewLayout(view, params)
            }
        }
        animator.start()

        // Persist position
        prefs.edit()
            .putInt(PREFS_KEY_X, targetX)
            .putInt(PREFS_KEY_Y, params.y)
            .apply()
    }

    private fun toggleAssistantPanel(bubbleX: Int, bubbleY: Int) {
        if (isPanelOpen) {
            closeAssistantPanel()
        } else {
            openAssistantPanel(bubbleX, bubbleY)
        }
    }

    private fun openAssistantPanel(bubbleX: Int, bubbleY: Int) {
        if (panelView != null) return

        val panel = FloatingPanelView(this, onClose = { closeAssistantPanel() })
        val layoutType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }

        val screenWidth = resources.displayMetrics.widthWidth()
        val panelWidth = dpToPx(320)
        val clampedX = Math.max(dpToPx(16), Math.min(bubbleX - dpToPx(130), screenWidth - panelWidth - dpToPx(16)))

        val panelParams = WindowManager.LayoutParams(
            panelWidth,
            WindowManager.LayoutParams.WRAP_CONTENT,
            layoutType,
            WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = clampedX
            y = bubbleY + dpToPx(65)
        }

        windowManager.addView(panel, panelParams)
        panelView = panel
        isPanelOpen = true
    }

    private fun closeAssistantPanel() {
        panelView?.let {
            windowManager.removeView(it)
            panelView = null
        }
        isPanelOpen = false
    }

    override fun onDestroy() {
        super.onDestroy()
        isRunning = false
        closeAssistantPanel()
        bubbleView?.let {
            windowManager.removeView(it)
            bubbleView = null
        }
    }

    private fun android.util.DisplayMetrics.widthWidth(): Int = widthPixels
    private fun dpToPx(dp: Float): Int = (dp * resources.displayMetrics.density).toInt()
    private fun dpToPx(dp: Int): Int = (dp * resources.displayMetrics.density).toInt()
}
