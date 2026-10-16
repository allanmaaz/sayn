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
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.view.Gravity
import android.view.HapticFeedbackConstants
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.view.animation.DecelerateInterpolator
import android.widget.FrameLayout
import android.widget.ImageView
import android.provider.Settings
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import androidx.core.app.NotificationCompat
import com.sayn.app.MainActivity
import com.sayn.app.R
import com.sayn.app.keyboard.SaynInputMethodService
import com.sayn.app.service.SaynAccessibilityService
import com.sayn.app.service.SaynCloudVoiceClient
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.util.Locale

class FloatingBubbleService : Service() {

    private lateinit var windowManager: WindowManager
    private lateinit var prefs: SharedPreferences

    // Main Floating View Containers
    private var rootContainer: FrameLayout? = null
    private var squircleView: FrameLayout? = null
    private var wisprPillView: LinearLayout? = null
    private lateinit var floatingParams: WindowManager.LayoutParams

    // Dismiss Cross Target at Bottom Center
    private var dismissTargetView: View? = null
    private lateinit var dismissBg: GradientDrawable

    // Wispr Pill Elements
    private lateinit var waveformContainer: LinearLayout
    private lateinit var transcriptText: TextView

    // Speech Recognition
    private var speechRecognizer: SpeechRecognizer? = null
    private var isListening = false
    private var currentSpokenText = ""

    private var isInputActive = false
    private var isDismissedByUser = false
    private var isPillExpanded = false

    private val mainHandler = Handler(Looper.getMainLooper())

    companion object {
        var isRunning = false
            private set
        var instance: FloatingBubbleService? = null
            private set
        var isUniversalInputActiveState = false
            private set

        private const val CHANNEL_ID = "sayn_overlay_channel"
        private const val NOTIFICATION_ID = 1001
        private const val PREFS_KEY_X = "bubble_pos_x"
        private const val PREFS_KEY_Y = "bubble_pos_y"

        fun setKeyboardActive(active: Boolean) {
            setUniversalInputActive(active)
        }

        fun setUniversalInputActive(active: Boolean) {
            isUniversalInputActiveState = active
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
        createFloatingViews()
        updateVisibility(isUniversalInputActiveState)
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
            .setContentTitle("SAYN Voice Assistant")
            .setContentText("Universal Voice Assistant ready across all keyboards.")
            .setSmallIcon(R.drawable.ic_sayn_mic)
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

    private fun createFloatingViews() {
        val layoutType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }

        val savedX = prefs.getInt(PREFS_KEY_X, dpToPx(16))
        val savedY = prefs.getInt(PREFS_KEY_Y, dpToPx(240))

        floatingParams = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            layoutType,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = savedX
            y = savedY
        }

        rootContainer = FrameLayout(this).apply {
            visibility = View.GONE
        }

        // ─────────────────────────────────────────────────────────────────────
        // 1. Idle Squircle View (50dp x 50dp translucent dark glass)
        // ─────────────────────────────────────────────────────────────────────
        squircleView = FrameLayout(this).apply {
            val bg = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = dpToPx(16f).toFloat()
                setColor(Color.parseColor("#E6180B0F")) // Translucent dark obsidian glass
                setStroke(dpToPx(1.2f), Color.parseColor("#4DA83249"))
            }
            background = bg
            elevation = dpToPx(8).toFloat()
            layoutParams = FrameLayout.LayoutParams(dpToPx(50), dpToPx(50))

            val micIcon = ImageView(this@FloatingBubbleService).apply {
                setImageResource(R.drawable.ic_sayn_mic)
                setColorFilter(Color.parseColor("#F5EBDD")) // Warm Cream
                layoutParams = FrameLayout.LayoutParams(dpToPx(24), dpToPx(24), Gravity.CENTER)
            }
            addView(micIcon)
        }

        // ─────────────────────────────────────────────────────────────────────
        // 2. The Wispr 3-Piece Pill View ([ Close ] [ ılıll Capsule ] [ Confirm ])
        // ─────────────────────────────────────────────────────────────────────
        wisprPillView = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            visibility = View.GONE
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.WRAP_CONTENT,
                dpToPx(50)
            )

            // A. Cancel / Wrong Circle [ Close ]
            val cancelCircle = FrameLayout(this@FloatingBubbleService).apply {
                val bg = GradientDrawable().apply {
                    shape = GradientDrawable.OVAL
                    setColor(Color.parseColor("#E6240F16"))
                    setStroke(dpToPx(1f), Color.parseColor("#4DA83249"))
                }
                background = bg
                isClickable = true
                layoutParams = LinearLayout.LayoutParams(dpToPx(44), dpToPx(44))

                val cancelIcon = ImageView(this@FloatingBubbleService).apply {
                    setImageResource(R.drawable.ic_sayn_close)
                    setColorFilter(Color.parseColor("#F5EBDD"))
                    layoutParams = FrameLayout.LayoutParams(
                        dpToPx(18),
                        dpToPx(18),
                        Gravity.CENTER
                    )
                }
                addView(cancelIcon)

                setOnClickListener {
                    performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP)
                    cancelVoiceDictation()
                }
            }
            addView(cancelCircle)

            // B. Center Capsule with Wavy Equalizer & Live Transcript
            val centerCapsule = LinearLayout(this@FloatingBubbleService).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER_VERTICAL
                val bg = GradientDrawable().apply {
                    shape = GradientDrawable.RECTANGLE
                    cornerRadius = dpToPx(23f).toFloat()
                    setColor(Color.parseColor("#E6180B0F")) // Rich frosted obsidian glass
                    setStroke(dpToPx(1.2f), Color.parseColor("#4DA83249"))
                }
                background = bg
                setPadding(dpToPx(12), 0, dpToPx(14), 0)
                layoutParams = LinearLayout.LayoutParams(dpToPx(220), dpToPx(44)).apply {
                    marginStart = dpToPx(8)
                    marginEnd = dpToPx(8)
                }

                // Waveform Equalizer Container ("The Wavy Thing")
                waveformContainer = LinearLayout(this@FloatingBubbleService).apply {
                    orientation = LinearLayout.HORIZONTAL
                    gravity = Gravity.CENTER_VERTICAL
                    layoutParams = LinearLayout.LayoutParams(
                        LinearLayout.LayoutParams.WRAP_CONTENT,
                        LinearLayout.LayoutParams.MATCH_PARENT
                    )
                }
                buildWaveformBars()
                addView(waveformContainer)

                // Live Transcript Streaming Text (No placeholder wording!)
                transcriptText = TextView(this@FloatingBubbleService).apply {
                    text = ""
                    textSize = 13.5f
                    setTextColor(Color.parseColor("#F5EBDD"))
                    gravity = Gravity.CENTER_VERTICAL
                    isSingleLine = true
                    ellipsize = android.text.TextUtils.TruncateAt.END
                    setPadding(dpToPx(10), 0, 0, 0)
                    layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.MATCH_PARENT, 1f)
                }
                addView(transcriptText)
            }
            addView(centerCapsule)

            // C. Confirm / Correct Warm Cream Circle [ Confirm ]
            val confirmCircle = FrameLayout(this@FloatingBubbleService).apply {
                val bg = GradientDrawable().apply {
                    shape = GradientDrawable.OVAL
                    setColor(Color.parseColor("#F5EBDD")) // Official Warm Cream
                    setStroke(dpToPx(1f), Color.parseColor("#6F1025"))
                }
                background = bg
                isClickable = true
                layoutParams = LinearLayout.LayoutParams(dpToPx(44), dpToPx(44))

                val confirmIcon = ImageView(this@FloatingBubbleService).apply {
                    setImageResource(R.drawable.ic_sayn_check)
                    setColorFilter(Color.parseColor("#100709")) // Contrast dark checkmark
                    layoutParams = FrameLayout.LayoutParams(
                        dpToPx(20),
                        dpToPx(20),
                        Gravity.CENTER
                    )
                }
                addView(confirmIcon)

                setOnClickListener {
                    performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP)
                    commitVoiceDictation()
                }
            }
            addView(confirmCircle)
        }

        rootContainer?.addView(squircleView)
        rootContainer?.addView(wisprPillView)

        // Setup Drag & Tap Listeners
        setupTouchListener(rootContainer!!)

        windowManager.addView(rootContainer, floatingParams)
    }

    private fun buildWaveformBars() {
        waveformContainer.removeAllViews()
        for (i in 0..6) {
            val bar = View(this).apply {
                val bg = GradientDrawable().apply {
                    cornerRadius = dpToPx(2).toFloat()
                    setColor(Color.parseColor("#A83249")) // Rose-Maroon soundwave
                }
                background = bg
                layoutParams = LinearLayout.LayoutParams(dpToPx(3), dpToPx(10 + (i % 3) * 4)).apply {
                    marginStart = dpToPx(2)
                    marginEnd = dpToPx(2)
                }
            }
            waveformContainer.addView(bar)
        }
    }

    private fun updateWaveformBars(rmsdB: Float) {
        val boost = Math.max(8, (rmsdB * 2.8f).toInt())
        for (i in 0 until waveformContainer.childCount) {
            val bar = waveformContainer.getChildAt(i)
            bar.layoutParams.height = dpToPx(Math.min(30, boost + (i % 3) * 4))
            bar.requestLayout()
        }
    }

    private fun setupTouchListener(view: View) {
        view.setOnTouchListener(object : View.OnTouchListener {
            private var initialX = 0
            private var initialY = 0
            private var touchX = 0f
            private var touchY = 0f
            private var isDragging = false
            private var isOverDismiss = false

            override fun onTouch(v: View, event: MotionEvent): Boolean {
                when (event.action) {
                    MotionEvent.ACTION_DOWN -> {
                        initialX = floatingParams.x
                        initialY = floatingParams.y
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
                            floatingParams.x = initialX + dx
                            floatingParams.y = initialY + dy
                            windowManager.updateViewLayout(rootContainer, floatingParams)

                            // Show dismiss cross target
                            dismissTargetView?.visibility = View.VISIBLE

                            val screenWidth = resources.displayMetrics.widthPixels
                            val screenHeight = resources.displayMetrics.heightPixels
                            val dismissCenterX = screenWidth / 2
                            val dismissCenterY = screenHeight - dpToPx(65)
                            val currentCenterX = floatingParams.x + (v.width / 2)
                            val currentCenterY = floatingParams.y + (v.height / 2)

                            val dist = Math.hypot(
                                (currentCenterX - dismissCenterX).toDouble(),
                                (currentCenterY - dismissCenterY).toDouble()
                            )
                            isOverDismiss = dist < dpToPx(85)

                            if (isOverDismiss) {
                                dismissTargetView?.scaleX = 1.25f
                                dismissTargetView?.scaleY = 1.25f
                                dismissBg.setColor(Color.parseColor("#E0FF3B30"))
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
                            view.performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP)
                            isDismissedByUser = true
                            cancelVoiceDictation()
                            rootContainer?.visibility = View.GONE
                        } else if (!isDragging) {
                            // Tap on squircle -> Expand into Wispr 3-Piece Pill and start listening!
                            view.performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP)
                            if (!isPillExpanded) {
                                expandToWisprPill()
                            }
                        } else {
                            // Snap smoothly to nearest screen side edge
                            snapToNearestEdge(view, floatingParams)
                        }
                        return true
                    }
                }
                return false
            }
        })
    }

    private fun expandToWisprPill() {
        isPillExpanded = true
        squircleView?.visibility = View.GONE
        wisprPillView?.visibility = View.VISIBLE
        windowManager.updateViewLayout(rootContainer, floatingParams)
        startVoiceDictation()
    }

    private fun collapseToSquircle() {
        isPillExpanded = false
        stopSpeechRecognizer()
        wisprPillView?.visibility = View.GONE
        squircleView?.visibility = View.VISIBLE
        windowManager.updateViewLayout(rootContainer, floatingParams)
    }

    private fun startVoiceDictation() {
        stopSpeechRecognizer()

        currentSpokenText = ""
        transcriptText.text = ""
        transcriptText.setTextColor(Color.WHITE)

        val recognizer = createSpeechRecognizerSafe(applicationContext)
        if (recognizer == null) {
            transcriptText.text = "Voice unavailable on device"
            return
        }

        speechRecognizer = recognizer
        speechRecognizer?.setRecognitionListener(object : RecognitionListener {
            override fun onReadyForSpeech(params: Bundle?) {
                // Keep clean without pre-text wording
            }

            override fun onBeginningOfSpeech() {
                // Keep clean without pre-text wording
            }

            override fun onRmsChanged(rmsdB: Float) {
                mainHandler.post {
                    updateWaveformBars(rmsdB)
                }
            }

            override fun onBufferReceived(buffer: ByteArray?) {}

            override fun onEndOfSpeech() {
                transcriptText.text = "SAYN Polishing..."
                transcriptText.setTextColor(Color.parseColor("#F5EBDD"))
            }

            override fun onError(error: Int) {
                isListening = false
                stopSpeechRecognizer()

                when (error) {
                    9 -> { // Permissions
                        Toast.makeText(applicationContext, "Microphone permission required", Toast.LENGTH_SHORT).show()
                        val intent = Intent(applicationContext, MainActivity::class.java).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                            putExtra("request_mic_permission", true)
                        }
                        startActivity(intent)
                        collapseToSquircle()
                    }
                    5 -> {
                        transcriptText.text = "Tap to retry"
                    }
                    SpeechRecognizer.ERROR_NO_MATCH, SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> {
                        if (currentSpokenText.isEmpty()) {
                            transcriptText.text = ""
                        }
                    }
                    else -> {
                        transcriptText.text = "Paused ($error)"
                    }
                }
            }

            override fun onResults(results: Bundle?) {
                val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                if (!matches.isNullOrEmpty()) {
                    currentSpokenText = matches[0]
                }
                isListening = false
            }

            override fun onPartialResults(partialResults: Bundle?) {
                val matches = partialResults?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                if (!matches.isNullOrEmpty()) {
                    currentSpokenText = matches[0]
                    // Do not display live text while speaking - keep overlay silent and clean
                }
            }

            override fun onEvent(eventType: Int, params: Bundle?) {}
        })

        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, Locale.getDefault())
            putExtra(RecognizerIntent.EXTRA_CALLING_PACKAGE, applicationContext.packageName)
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
            putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 3)
        }

        try {
            speechRecognizer?.startListening(intent)
            isListening = true
        } catch (e: Exception) {
            transcriptText.text = "Mic busy. Try again."
        }
    }

    private fun commitVoiceDictation() {
        val textToInsert = currentSpokenText.trim()
        stopSpeechRecognizer()

        if (textToInsert.isNotEmpty()) {
            transcriptText.text = "SAYN Polishing..."
            transcriptText.setTextColor(Color.parseColor("#F5EBDD"))

            CoroutineScope(Dispatchers.Main).launch {
                val hostPackage = SaynAccessibilityService.instance?.findEditableTargetNode()?.packageName?.toString()
                val refined = SaynCloudVoiceClient.refineText(textToInsert, hostPackage)

                // 1. Inject directly into currently focused field across ANY app (WhatsApp, Slack, Gmail, etc.)
                val injected = SaynAccessibilityService.instance?.insertTextIntoFocusedField(refined) ?: false

                if (!injected) {
                    // Fallback to clipboard if accessibility service is pending user toggle
                    val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as android.content.ClipboardManager
                    clipboard.setPrimaryClip(android.content.ClipData.newPlainText("SAYN Voice", refined))
                    Toast.makeText(this@FloatingBubbleService, "Copied to clipboard. Enable SAYN in Accessibility for 1-tap typing!", Toast.LENGTH_SHORT).show()
                }

                collapseToSquircle()
            }
        } else {
            collapseToSquircle()
        }
    }

    private fun cancelVoiceDictation() {
        stopSpeechRecognizer()
        currentSpokenText = ""
        collapseToSquircle()
    }

    private fun stopSpeechRecognizer() {
        try {
            speechRecognizer?.stopListening()
            speechRecognizer?.destroy()
        } catch (_: Exception) {}
        speechRecognizer = null
        isListening = false
    }

    fun updateVisibility(inputActive: Boolean) {
        isInputActive = inputActive
        if (inputActive) {
            isDismissedByUser = false
        } else {
            cancelVoiceDictation()
        }
        rootContainer?.post {
            rootContainer?.visibility = if (inputActive && !isDismissedByUser) View.VISIBLE else View.GONE
        }
    }

    private fun snapToNearestEdge(view: View, params: WindowManager.LayoutParams) {
        val screenWidth = resources.displayMetrics.widthPixels
        val targetX = if (params.x + (view.width / 2) < screenWidth / 2) dpToPx(12) else screenWidth - view.width - dpToPx(12)

        val animator = ValueAnimator.ofInt(params.x, targetX).apply {
            duration = 200
            interpolator = DecelerateInterpolator()
            addUpdateListener { anim ->
                params.x = anim.animatedValue as Int
                windowManager.updateViewLayout(rootContainer, params)
            }
        }
        animator.start()

        prefs.edit()
            .putInt(PREFS_KEY_X, targetX)
            .putInt(PREFS_KEY_Y, params.y)
            .apply()
    }

    private fun createSpeechRecognizerSafe(ctx: Context): SpeechRecognizer? {
        val appContext = ctx.applicationContext
        return try {
            val pm = appContext.packageManager
            val intent = Intent("android.speech.RecognitionService")
            val services = pm.queryIntentServices(intent, 0)

            val googleService = services.firstOrNull {
                it.serviceInfo.packageName.contains("google", ignoreCase = true)
            }
            if (googleService != null) {
                val comp = android.content.ComponentName(
                    googleService.serviceInfo.packageName,
                    googleService.serviceInfo.name
                )
                return SpeechRecognizer.createSpeechRecognizer(appContext, comp)
            }

            if (services.isNotEmpty()) {
                val first = services[0]
                val comp = android.content.ComponentName(
                    first.serviceInfo.packageName,
                    first.serviceInfo.name
                )
                return SpeechRecognizer.createSpeechRecognizer(appContext, comp)
            }

            SpeechRecognizer.createSpeechRecognizer(appContext)
        } catch (e: Exception) {
            try {
                SpeechRecognizer.createSpeechRecognizer(appContext)
            } catch (e2: Exception) {
                null
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        isRunning = false
        instance = null
        stopSpeechRecognizer()
        dismissTargetView?.let {
            windowManager.removeView(it)
            dismissTargetView = null
        }
        rootContainer?.let {
            windowManager.removeView(it)
            rootContainer = null
        }
    }

    private fun dpToPx(dp: Float): Int = (dp * resources.displayMetrics.density).toInt()
    private fun dpToPx(dp: Int): Int = (dp * resources.displayMetrics.density).toInt()
}
