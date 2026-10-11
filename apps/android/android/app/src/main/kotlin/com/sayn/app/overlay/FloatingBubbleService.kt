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
import android.view.HapticFeedbackConstants
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
    private var dismissTargetView: View? = null
    private lateinit var dismissBg: GradientDrawable
    private var panelView: FloatingPanelView? = null
    private var isPanelOpen = false

    private var isKeyboardVisible = false
    private var isDismissedByUser = false

    companion object {
        var isRunning = false
            private set
        var instance: FloatingBubbleService? = null
            private set
        var isKeyboardActiveState = false
            private set

        private const val CHANNEL_ID = "sayn_overlay_channel"
        private const val NOTIFICATION_ID = 1001
        private const val PREFS_KEY_X = "bubble_pos_x"
        private const val PREFS_KEY_Y = "bubble_pos_y"

        fun setKeyboardActive(active: Boolean) {
            isKeyboardActiveState = active
            instance?.updateVisibility(active)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        instance = this
        isRunning = true
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        prefs = getSharedPreferences("com.sayn.app.PREFS", Context.MODE_PRIVATE)
        startForegroundServiceNotification()
        createDismissTargetView()
        createFloatingBubble()
        updateVisibility(isKeyboardActiveState)
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
            .setContentText("Voice assistant ready when keyboard opens.")
            .setSmallIcon(android.R.drawable.ic_btn_speak_now)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()

        startForeground(NOTIFICATION_ID, notification)
    }

    private fun createDismissTargetView() {
        val layoutType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }

        val targetParams = WindowManager.LayoutParams(
            dpToPx(62),
            dpToPx(62),
            layoutType,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.BOTTOM or Gravity.CENTER_HORIZONTAL
            y = dpToPx(55)
        }

        dismissBg = GradientDrawable().apply {
            shape = GradientDrawable.OVAL
            setColor(Color.parseColor("#991C1C20"))
            setStroke(dpToPx(1.5f), Color.parseColor("#66FFFFFF"))
        }

        val container = FrameLayout(this).apply {
            background = dismissBg
            visibility = View.GONE
        }

        val crossIcon = ImageView(this).apply {
            setImageResource(android.R.drawable.ic_menu_close_clear_cancel)
            setColorFilter(Color.WHITE)
            layoutParams = FrameLayout.LayoutParams(
                dpToPx(26),
                dpToPx(26),
                Gravity.CENTER
            )
        }
        container.addView(crossIcon)

        dismissTargetView = container
        windowManager.addView(container, targetParams)
    }

    private fun createFloatingBubble() {
        val layoutType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }

        val savedX = prefs.getInt(PREFS_KEY_X, 20)
        val savedY = prefs.getInt(PREFS_KEY_Y, 260)

        val bubbleParams = WindowManager.LayoutParams(
            dpToPx(52),
            dpToPx(52),
            layoutType,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = savedX
            y = savedY
        }

        // Translucent squircle (rounded square with glassmorphism border)
        val container = FrameLayout(this).apply {
            val bg = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = dpToPx(16f).toFloat() // Squircle
                setColor(Color.parseColor("#A61E1E22")) // Translucent dark frosted glass
                setStroke(dpToPx(1.2f), Color.parseColor("#44FFFFFF")) // Subtle frosted border
            }
            background = bg
            elevation = dpToPx(8).toFloat()
            // Initially hidden: Only appears when keyboard comes up!
            visibility = View.GONE
        }

        val micIcon = ImageView(this).apply {
            setImageResource(android.R.drawable.ic_btn_speak_now)
            setColorFilter(Color.parseColor("#5DE4FF")) // Audio cyan
            layoutParams = FrameLayout.LayoutParams(
                dpToPx(26),
                dpToPx(26),
                Gravity.CENTER
            )
        }
        container.addView(micIcon)

        // Dragging & Bottom-Center Dismiss Cross Gesture
        container.setOnTouchListener(object : View.OnTouchListener {
            private var initialX = 0
            private var initialY = 0
            private var touchX = 0f
            private var touchY = 0f
            private var isDragging = false
            private var isOverDismiss = false

            override fun onTouch(v: View, event: MotionEvent): Boolean {
                when (event.action) {
                    MotionEvent.ACTION_DOWN -> {
                        initialX = bubbleParams.x
                        initialY = bubbleParams.y
                        touchX = event.rawX
                        touchY = event.rawY
                        isDragging = false
                        isOverDismiss = false
                        return true
                    }
                    MotionEvent.ACTION_MOVE -> {
                        val dx = (event.rawX - touchX).toInt()
                        val dy = (event.rawY - touchY).toInt()
                        if (Math.abs(dx) > 8 || Math.abs(dy) > 8) {
                            isDragging = true
                            bubbleParams.x = initialX + dx
                            bubbleParams.y = initialY + dy
                            windowManager.updateViewLayout(container, bubbleParams)

                            // Show dismiss cross at bottom center
                            dismissTargetView?.visibility = View.VISIBLE

                            // Check distance to dismiss target
                            val screenWidth = resources.displayMetrics.widthPixels
                            val screenHeight = resources.displayMetrics.heightPixels
                            val dismissCenterX = screenWidth / 2
                            val dismissCenterY = screenHeight - dpToPx(65)
                            val bubbleCenterX = bubbleParams.x + dpToPx(26)
                            val bubbleCenterY = bubbleParams.y + dpToPx(26)

                            val dist = Math.hypot(
                                (bubbleCenterX - dismissCenterX).toDouble(),
                                (bubbleCenterY - dismissCenterY).toDouble()
                            )
                            isOverDismiss = dist < dpToPx(85)

                            if (isOverDismiss) {
                                dismissTargetView?.scaleX = 1.25f
                                dismissTargetView?.scaleY = 1.25f
                                dismissBg.setColor(Color.parseColor("#E0FF3B30")) // Active red
                            } else {
                                dismissTargetView?.scaleX = 1.0f
                                dismissTargetView?.scaleY = 1.0f
                                dismissBg.setColor(Color.parseColor("#991C1C20"))
                            }
                        }
                        return true
                    }
                    MotionEvent.ACTION_UP -> {
                        dismissTargetView?.visibility = View.GONE

                        if (isOverDismiss) {
                            // Dragged to cross -> dismiss
                            container.performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP)
                            isDismissedByUser = true
                            container.visibility = View.GONE
                        } else if (!isDragging) {
                            container.performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP)
                            // When typing with keyboard, tapping bubble starts Wispr voice dictation in keyboard!
                            if (isKeyboardVisible && com.sayn.app.keyboard.SaynInputMethodService.instance != null) {
                                com.sayn.app.keyboard.SaynInputMethodService.instance?.triggerVoiceDictation()
                            } else {
                                toggleAssistantPanel(bubbleParams.x, bubbleParams.y)
                            }
                        } else {
                            // Snap to nearest side edge
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

    fun updateVisibility(keyboardActive: Boolean) {
        isKeyboardVisible = keyboardActive
        if (keyboardActive) {
            isDismissedByUser = false // Reset when keyboard opens in a new chat
        }
        bubbleView?.post {
            bubbleView?.visibility = if (keyboardActive && !isDismissedByUser) View.VISIBLE else View.GONE
        }
        if (!keyboardActive) {
            closeAssistantPanel()
        }
    }

    private fun snapToNearestEdge(view: View, params: WindowManager.LayoutParams) {
        val screenWidth = resources.displayMetrics.widthPixels
        val targetX = if (params.x + dpToPx(26) < screenWidth / 2) dpToPx(12) else screenWidth - dpToPx(64)

        val animator = ValueAnimator.ofInt(params.x, targetX).apply {
            duration = 200
            interpolator = DecelerateInterpolator()
            addUpdateListener { anim ->
                params.x = anim.animatedValue as Int
                windowManager.updateViewLayout(view, params)
            }
        }
        animator.start()

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

        val screenWidth = resources.displayMetrics.widthPixels
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
            y = bubbleY + dpToPx(60)
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
        instance = null
        closeAssistantPanel()
        dismissTargetView?.let {
            windowManager.removeView(it)
            dismissTargetView = null
        }
        bubbleView?.let {
            windowManager.removeView(it)
            bubbleView = null
        }
    }

    private fun dpToPx(dp: Float): Int = (dp * resources.displayMetrics.density).toInt()
    private fun dpToPx(dp: Int): Int = (dp * resources.displayMetrics.density).toInt()
}
