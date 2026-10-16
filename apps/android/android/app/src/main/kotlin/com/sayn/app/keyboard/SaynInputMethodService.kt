package com.sayn.app.keyboard

import android.Manifest
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.graphics.drawable.LayerDrawable
import android.graphics.drawable.StateListDrawable
import android.inputmethodservice.InputMethodService
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.view.Gravity
import android.view.HapticFeedbackConstants
import android.view.MotionEvent
import android.view.View
import android.view.inputmethod.EditorInfo
import android.view.inputmethod.InputMethodManager
import android.widget.*
import androidx.core.content.ContextCompat
import android.graphics.PorterDuff
import android.media.AudioManager
import android.os.Vibrator
import android.os.VibratorManager
import android.os.VibrationEffect
import com.sayn.app.R
import com.sayn.app.MainActivity
import com.sayn.app.service.SaynCloudVoiceClient
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.util.Locale

class SaynInputMethodService : InputMethodService() {

    private lateinit var rootLayout: LinearLayout
    private lateinit var aiToolbar: LinearLayout
    private lateinit var voiceLiveBar: LinearLayout
    private lateinit var suggestionArea: LinearLayout
    private lateinit var keysContainer: LinearLayout

    // Wispr Voice Live Bar Views (3-piece Wispr pill)
    private lateinit var voiceStatusDot: TextView
    private lateinit var voiceTranscriptText: TextView
    private lateinit var btnCorrectAndInsert: TextView

    // Suggestion Area Views
    private lateinit var suggestionBadge: TextView
    private lateinit var suggestionText: TextView
    private lateinit var btnReplace: TextView
    private lateinit var btnInsert: TextView
    private lateinit var btnCopy: TextView
    private lateinit var btnDismiss: TextView

    // Full AI Assistant Panel (Matching Screenshot 2)
    private lateinit var fullAiPanelContainer: LinearLayout
    private lateinit var aiPanelModesRow: LinearLayout
    private lateinit var aiCardTitle: TextView
    private lateinit var aiCardDiffWord: TextView
    private lateinit var aiCardDiffBadge: TextView
    private lateinit var aiCardPreview: TextView
    private lateinit var btnAiAccept: TextView
    private lateinit var btnAiDismiss: TextView
    private lateinit var btnAiBackToKeyboard: FrameLayout
    private lateinit var aiPagerIndicator: TextView
    private lateinit var btnAiAcceptAll: TextView

    // State Variables
    private var isSensitiveField = false
    private var symbolLayoutMode = 0 // 0 = Letters, 1 = 123, 2 = #+=
    private var isShifted = false
    private var isCapsLock = false
    private var lastShiftPressTime = 0L
    private var isRefining = false
    private var activeMode = "grammar"
    private var lastSuggestion = ""
    private var lastOriginalText = ""

    // Speech Recognizer for In-Keyboard Dictation (Wispr flow)
    private var speechRecognizer: SpeechRecognizer? = null
    private var isListening = false
    private var currentSpokenText = ""

    // Delete repeat handler
    private val deleteHandler = Handler(Looper.getMainLooper())
    private var deleteRunnable: Runnable? = null

    // Writing Modes (QuillBot, Grammarly & Wispr Flow style)
    private val modes = listOf(
        "grammar" to "Grammar",
        "rewrite" to "Rewrite",
        "humanize" to "Humanize",
        "flow" to "Flow",
        "professional" to "Professional",
        "casual" to "Casual",
        "shorten" to "Shorten"
    )
 
    companion object {
        var instance: SaynInputMethodService? = null
            private set
    }

    /**
     * Directly commits text into whichever text box the SAYN keyboard is connected to.
     */
    fun commitTextFromExternal(text: String): Boolean {
        val ic = currentInputConnection ?: return false
        val toCommit = if (text.endsWith(" ")) text else "$text "
        ic.commitText(toCommit, 1)
        return true
    }

    // Typing sound and haptic feedback settings
    private var isSoundEnabled = true
    private var isVibrationEnabled = true
    private var vibrationIntensity = "medium"

    private val audioManager by lazy { getSystemService(Context.AUDIO_SERVICE) as? AudioManager }
    private val vibrator by lazy {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val vibratorManager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
            vibratorManager?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        }
    }

    override fun onCreate() {
        super.onCreate()
        instance = this
        reloadFeedbackSettings()
    }

    // Auto-Correct settings & dictionary (Enabled strictly inside the keyboard)
    private var isAutoCorrectEnabled = true

    private val autoCorrectMap = mapOf(
        "teh" to "the",
        "adn" to "and",
        "taht" to "that",
        "thsi" to "this",
        "waht" to "what",
        "whcih" to "which",
        "woudl" to "would",
        "coudl" to "could",
        "shoudl" to "should",
        "becuase" to "because",
        "beacuse" to "because",
        "definately" to "definitely",
        "definatly" to "definitely",
        "definitly" to "definitely",
        "seperate" to "separate",
        "seperated" to "separated",
        "seperation" to "separation",
        "recieve" to "receive",
        "recieved" to "received",
        "recieving" to "receiving",
        "acheive" to "achieve",
        "acheived" to "achieved",
        "beleive" to "believe",
        "beleived" to "believed",
        "untill" to "until",
        "wierd" to "weird",
        "tommorrow" to "tomorrow",
        "tomorow" to "tomorrow",
        "goverment" to "government",
        "accomodate" to "accommodate",
        "neccessary" to "necessary",
        "necesary" to "necessary",
        "occured" to "occurred",
        "occuring" to "occurring",
        "occurence" to "occurrence",
        "embarass" to "embarrass",
        "embarassed" to "embarrassed",
        "alot" to "a lot",
        "noone" to "no one",
        "everytime" to "every time",
        "truely" to "truly",
        "realy" to "really",
        "freind" to "friend",
        "freinds" to "friends",
        "peice" to "piece",
        "peices" to "pieces",
        "grammer" to "grammar",
        "langauge" to "language",
        "calender" to "calendar",
        "apparantly" to "apparently",
        "succesful" to "successful",
        "unfortunatly" to "unfortunately",
        "dissapoint" to "disappoint",
        "dissappointed" to "disappointed",
        "privilege" to "privilege",
        "privelege" to "privilege",
        // Common Contractions without apostrophe
        "dont" to "don't",
        "cant" to "can't",
        "wont" to "won't",
        "didnt" to "didn't",
        "doesnt" to "doesn't",
        "isnt" to "isn't",
        "arent" to "aren't",
        "wasnt" to "wasn't",
        "werent" to "weren't",
        "hasnt" to "hasn't",
        "havent" to "haven't",
        "hadnt" to "hadn't",
        "couldnt" to "couldn't",
        "shouldnt" to "shouldn't",
        "wouldnt" to "wouldn't",
        "im" to "I'm",
        "ive" to "I've",
        "id" to "I'd",
        "ill" to "I'll",
        "youre" to "you're",
        "youve" to "you've",
        "youd" to "you'd",
        "youll" to "you'll",
        "theyre" to "they're",
        "theyve" to "they've",
        "theyd" to "they'd",
        "theyll" to "they'll",
        "weve" to "we've",
        "thats" to "that's",
        "whats" to "what's",
        "wheres" to "where's",
        "whens" to "when's",
        "whys" to "why's",
        "hows" to "how's",
        "hes" to "he's",
        "shes" to "she's",
        "theres" to "there's",
        "heres" to "here's",
        "lets" to "let's"
    )

    fun reloadFeedbackSettings() {
        val prefs = getSharedPreferences("com.sayn.app.PREFS", Context.MODE_PRIVATE)
        activeMode = prefs.getString("default_mode", "standard") ?: "standard"
        isSoundEnabled = prefs.getBoolean("key_sound_enabled", true)
        isVibrationEnabled = prefs.getBoolean("key_vibration_enabled", true)
        vibrationIntensity = prefs.getString("key_vibration_intensity", "medium") ?: "medium"
        isAutoCorrectEnabled = prefs.getBoolean("keyboard_autocorrect_enabled", true)
    }

    fun triggerVoiceDictation() {
        android.os.Handler(android.os.Looper.getMainLooper()).post {
            showVoiceLiveBar()
            startInKeyboardVoice()
        }
    }

    override fun onCreateInputView(): View {
        rootLayout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.parseColor("#1C1C1E")) // Authentic iOS Dark Gray
            // Elevated keyboard: 26dp bottom padding elevates keyboard away from the phone's bottom bezel & gesture bar
            setPadding(dpToPx(4), dpToPx(6), dpToPx(4), dpToPx(26))
        }

        buildVoiceLiveBar()
        buildSuggestionArea()
        buildAiToolbar()
        buildFullAiPanel()
        buildKeysLayout()

        return rootLayout
    }

    override fun onStartInputView(info: EditorInfo?, restarting: Boolean) {
        super.onStartInputView(info, restarting)
        reloadFeedbackSettings()
        isSensitiveField = SensitiveFieldGuard.isSensitiveField(info)

        // Only show floating assistant when chat/input is open with keyboard!
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && android.provider.Settings.canDrawOverlays(this)) {
            if (!com.sayn.app.overlay.FloatingBubbleService.isRunning) {
                val intent = Intent(this, com.sayn.app.overlay.FloatingBubbleService::class.java)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    startForegroundService(intent)
                } else {
                    startService(intent)
                }
            } else {
                com.sayn.app.overlay.FloatingBubbleService.setKeyboardActive(true)
            }
        } else {
            com.sayn.app.overlay.FloatingBubbleService.setKeyboardActive(true)
        }

        hideVoiceLiveBar()
        hideSuggestionArea()
        if (::fullAiPanelContainer.isInitialized) {
            fullAiPanelContainer.visibility = View.GONE
        }
        if (::keysContainer.isInitialized) {
            keysContainer.visibility = View.VISIBLE
        }

        if (isSensitiveField) {
            aiToolbar.visibility = View.GONE
        } else {
            aiToolbar.visibility = View.VISIBLE
        }

        symbolLayoutMode = 0
        isShifted = false
        isCapsLock = false
        renderKeys()
    }

    override fun onFinishInputView(finishingInput: Boolean) {
        super.onFinishInputView(finishingInput)
        // Hide floating assistant as soon as keyboard closes
        com.sayn.app.overlay.FloatingBubbleService.setKeyboardActive(false)
        stopInKeyboardVoice()
        hideVoiceLiveBar()
        if (::fullAiPanelContainer.isInitialized) {
            fullAiPanelContainer.visibility = View.GONE
        }
        if (::keysContainer.isInitialized) {
            keysContainer.visibility = View.VISIBLE
        }
    }

    override fun onWindowHidden() {
        super.onWindowHidden()
        // Ensure floating assistant is hidden whenever keyboard window is hidden
        com.sayn.app.overlay.FloatingBubbleService.setKeyboardActive(false)
        stopInKeyboardVoice()
        hideVoiceLiveBar()
    }

    // ─────────────────────────────────────────────────────────────────────────────
    // 1. Wispr Flow 3-Piece Floating Speech Pill ([ ✕ ] [ ••• text ••• ] [ ✓ (purple) ])
    // ─────────────────────────────────────────────────────────────────────────────

    private fun buildVoiceLiveBar() {
        voiceLiveBar = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            visibility = View.GONE
            setPadding(dpToPx(8), dpToPx(3), dpToPx(8), dpToPx(5))
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                dpToPx(52)
            ).apply { bottomMargin = dpToPx(2) }
        }

        // 1. Left Circle: Frosted Glass Cancel Button [ ✕ ]
        val cancelCircle = FrameLayout(this).apply {
            val bg = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(Color.parseColor("#CCD8D8DE")) // Frosted translucent glass
                setStroke(dpToPx(1f), Color.parseColor("#44FFFFFF"))
            }
            background = bg
            isClickable = true
            isFocusable = false
            layoutParams = LinearLayout.LayoutParams(dpToPx(44), dpToPx(44))
        }

        val cancelText = TextView(this).apply {
            text = "✕"
            textSize = 15f
            setTextColor(Color.parseColor("#1C1C1E"))
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        }
        cancelCircle.addView(cancelText)
        cancelCircle.setOnClickListener {
            triggerKeyFeedback("DEL")
            stopInKeyboardVoice()
            hideVoiceLiveBar()
        }
        voiceLiveBar.addView(cancelCircle)

        // 2. Center Capsule: Translucent Speech Pill with Live Transcription & Dots ( ••• )
        val centerCapsule = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            val bg = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = dpToPx(23f).toFloat()
                setColor(Color.parseColor("#A6222226")) // Frosted dark glass
                setStroke(dpToPx(1f), Color.parseColor("#33FFFFFF"))
            }
            background = bg
            setPadding(dpToPx(14), 0, dpToPx(14), 0)
            layoutParams = LinearLayout.LayoutParams(0, dpToPx(44), 1f).apply {
                marginStart = dpToPx(8)
                marginEnd = dpToPx(8)
            }
        }

        voiceTranscriptText = TextView(this).apply {
            text = "Listening..."
            textSize = 13.5f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER_VERTICAL
            isSingleLine = true
            ellipsize = android.text.TextUtils.TruncateAt.END
            layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.MATCH_PARENT, 1f)
        }

        voiceStatusDot = TextView(this).apply {
            text = "• • • • •"
            textSize = 15f
            setTextColor(Color.parseColor("#CBFE00")) // Wispr Volt Neon Green
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dpToPx(6), 0, 0, 0)
        }

        centerCapsule.addView(voiceTranscriptText)
        centerCapsule.addView(voiceStatusDot)
        voiceLiveBar.addView(centerCapsule)

        // 3. Right Circle: Wispr Volt Neon Green Confirm Button [ ✓ ]
        val confirmCircle = FrameLayout(this).apply {
            val bg = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(Color.parseColor("#CBFE00")) // Wispr Volt Neon Green
                setStroke(dpToPx(1f), Color.parseColor("#44FFFFFF"))
            }
            background = bg
            isClickable = true
            isFocusable = false
            layoutParams = LinearLayout.LayoutParams(dpToPx(44), dpToPx(44))
        }

        btnCorrectAndInsert = TextView(this).apply {
            text = "✓"
            textSize = 19f
            setTextColor(Color.parseColor("#111115")) // Contrast black checkmark on volt green
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        }
        confirmCircle.addView(btnCorrectAndInsert)
        confirmCircle.setOnClickListener {
            triggerKeyFeedback("ENTER")
            stopInKeyboardVoice()
            refineAndCommitSpokenText()
        }
        voiceLiveBar.addView(confirmCircle)

        rootLayout.addView(voiceLiveBar)
    }

    private fun showVoiceLiveBar() {
        voiceLiveBar.visibility = View.VISIBLE
        suggestionArea.visibility = View.GONE
        voiceTranscriptText.text = "Listening..."
        voiceStatusDot.setTextColor(Color.parseColor("#CBFE00"))
    }

    private fun hideVoiceLiveBar() {
        voiceLiveBar.visibility = View.GONE
    }

    private fun commitSpokenTextToInput() {
        val ic = currentInputConnection ?: return
        val textToCommit = currentSpokenText.trim()
        if (textToCommit.isNotEmpty()) {
            ic.commitText(textToCommit + " ", 1)
        }
        currentSpokenText = ""
        hideVoiceLiveBar()
    }

    private fun refineAndCommitSpokenText() {
        val textToRefine = currentSpokenText.trim()
        if (textToRefine.isEmpty()) {
            hideVoiceLiveBar()
            return
        }

        voiceTranscriptText.text = "Polishing (${activeMode})..."

        CoroutineScope(Dispatchers.IO).launch {
            try {
                val refined = SaynCloudVoiceClient.refineText(
                    textToRefine,
                    currentInputEditorInfo?.packageName,
                    activeMode
                )
                withContext(Dispatchers.Main) {
                    val ic = currentInputConnection
                    if (ic != null && refined.isNotBlank()) {
                        ic.commitText(refined.trim() + " ", 1)
                    }
                    currentSpokenText = ""
                    hideVoiceLiveBar()
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    currentInputConnection?.commitText(textToRefine + " ", 1)
                    currentSpokenText = ""
                    hideVoiceLiveBar()
                }
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────────
    // 2. AI Suggestion Card Area (For Typed Text Refinement)
    // ─────────────────────────────────────────────────────────────────────────────

    private fun buildSuggestionArea() {
        suggestionArea = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            visibility = View.GONE
            val bg = GradientDrawable().apply {
                cornerRadius = dpToPx(10).toFloat()
                setColor(Color.parseColor("#252528"))
                setStroke(dpToPx(1.2f), Color.parseColor("#CBFE00"))
            }
            background = bg
            setPadding(dpToPx(10), dpToPx(8), dpToPx(10), dpToPx(8))
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply { bottomMargin = dpToPx(4) }
        }

        val topRow = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }

        suggestionBadge = TextView(this).apply {
            text = "✨ REFINEMENT SUGGESTION"
            textSize = 10f
            setTextColor(Color.parseColor("#CBFE00"))
            typeface = Typeface.DEFAULT_BOLD
            layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
        }

        btnDismiss = TextView(this).apply {
            text = "✕"
            textSize = 14f
            setTextColor(Color.parseColor("#8E8E93"))
            gravity = Gravity.CENTER
            setPadding(dpToPx(8), 0, dpToPx(4), 0)
            setOnClickListener { hideSuggestionArea() }
        }

        topRow.addView(suggestionBadge)
        topRow.addView(btnDismiss)
        suggestionArea.addView(topRow)

        suggestionText = TextView(this).apply {
            text = ""
            textSize = 13.5f
            setTextColor(Color.parseColor("#F5F5F7"))
            setPadding(0, dpToPx(4), 0, dpToPx(6))
            maxLines = 4
        }
        suggestionArea.addView(suggestionText)

        val actionsRow = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }

        btnReplace = TextView(this).apply {
            text = "✓ Replace"
            textSize = 12f
            setTextColor(Color.parseColor("#111115"))
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            background = createIosKeyDrawable(
                normalColor = Color.parseColor("#CBFE00"),
                pressedColor = Color.parseColor("#A6CF00"),
                shadowColor = Color.parseColor("#80A000"),
                cornerRadiusDp = 7f
            )
            setOnClickListener { handleReplace() }
            layoutParams = LinearLayout.LayoutParams(0, dpToPx(32), 1.2f).apply {
                marginEnd = dpToPx(6)
            }
        }

        btnInsert = TextView(this).apply {
            text = "Insert"
            textSize = 11.5f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            background = createIosKeyDrawable(
                normalColor = Color.parseColor("#343438"),
                pressedColor = Color.parseColor("#4A4A4E"),
                shadowColor = Color.parseColor("#1C1C1E"),
                cornerRadiusDp = 7f
            )
            setOnClickListener { handleInsert() }
            layoutParams = LinearLayout.LayoutParams(0, dpToPx(32), 1f).apply {
                marginEnd = dpToPx(6)
            }
        }

        btnCopy = TextView(this).apply {
            text = "Copy"
            textSize = 11.5f
            setTextColor(Color.parseColor("#D1D1D6"))
            gravity = Gravity.CENTER
            background = createIosKeyDrawable(
                normalColor = Color.parseColor("#2C2C2E"),
                pressedColor = Color.parseColor("#3A3A3E"),
                shadowColor = Color.parseColor("#18181A"),
                cornerRadiusDp = 7f
            )
            setOnClickListener { handleCopy() }
            layoutParams = LinearLayout.LayoutParams(0, dpToPx(32), 0.9f)
        }

        actionsRow.addView(btnReplace)
        actionsRow.addView(btnInsert)
        actionsRow.addView(btnCopy)
        suggestionArea.addView(actionsRow)

        rootLayout.addView(suggestionArea)
    }

    private fun showSuggestion(refined: String, mode: String) {
        lastSuggestion = refined
        suggestionBadge.text = "✨ ${mode.uppercase()} REFINEMENT"
        suggestionText.text = refined
        suggestionArea.visibility = View.VISIBLE
        hideVoiceLiveBar()
    }

    private fun hideSuggestionArea() {
        suggestionArea.visibility = View.GONE
    }

    private fun handleReplace() {
        val ic = currentInputConnection ?: return
        if (lastSuggestion.isEmpty()) return

        val selected = ic.getSelectedText(0)?.toString()
        if (!selected.isNullOrBlank()) {
            ic.commitText(lastSuggestion, 1)
        } else {
            val textBefore = ic.getTextBeforeCursor(lastOriginalText.length, 0)?.toString() ?: ""
            if (textBefore.isNotEmpty()) {
                ic.deleteSurroundingText(textBefore.length, 0)
            }
            ic.commitText(lastSuggestion, 1)
        }

        hideSuggestionArea()
        Toast.makeText(this, "Replaced with refined text", Toast.LENGTH_SHORT).show()
    }

    private fun handleInsert() {
        val ic = currentInputConnection ?: return
        if (lastSuggestion.isEmpty()) return

        ic.commitText(lastSuggestion, 1)
        hideSuggestionArea()
        Toast.makeText(this, "Inserted at cursor", Toast.LENGTH_SHORT).show()
    }

    private fun handleCopy() {
        if (lastSuggestion.isEmpty()) return
        val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        clipboard.setPrimaryClip(ClipData.newPlainText("SAYN Refinement", lastSuggestion))
        Toast.makeText(this, "Copied", Toast.LENGTH_SHORT).show()
    }

    // ─────────────────────────────────────────────────────────────────────────────
    // 3. SAYN AI Toolbar (With Purple Sparkle Button [✨] & Mic [🎤])
    // ─────────────────────────────────────────────────────────────────────────────

    private fun buildAiToolbar() {
        aiToolbar = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            val bg = GradientDrawable().apply {
                cornerRadius = dpToPx(8).toFloat()
                setColor(Color.parseColor("#222225"))
            }
            background = bg
            setPadding(dpToPx(6), dpToPx(2), dpToPx(6), dpToPx(2))
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                dpToPx(40)
            ).apply { bottomMargin = dpToPx(4) }
        }

        // Left: Writing-Style Horizontal Pills ScrollView
        val pillsScroll = HorizontalScrollView(this).apply {
            isHorizontalScrollBarEnabled = false
            layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
        }

        val pillsRow = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }

        for ((modeId, label) in modes) {
            val pill = TextView(this).apply {
                text = label
                textSize = 11.5f
                gravity = Gravity.CENTER
                val isSelected = modeId == activeMode
                setTextColor(if (isSelected) Color.parseColor("#111115") else Color.parseColor("#9CA3AF"))
                val pillBg = GradientDrawable().apply {
                    cornerRadius = dpToPx(13).toFloat()
                    setColor(if (isSelected) Color.parseColor("#CBFE00") else Color.parseColor("#2C2C2E"))
                }
                background = pillBg
                setPadding(dpToPx(12), 0, dpToPx(12), 0)
                setOnClickListener {
                    triggerKeyFeedback("SPACE")
                    activeMode = modeId
                    getSharedPreferences("com.sayn.app.PREFS", Context.MODE_PRIVATE)
                        .edit().putString("default_mode", modeId).apply()
                    updateToolbarPills(pillsRow)
                    openFullAiPanel(modeId)
                }
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.WRAP_CONTENT,
                    dpToPx(28)
                ).apply {
                    marginStart = dpToPx(2)
                    marginEnd = dpToPx(2)
                }
            }
            pillsRow.addView(pill)
        }

        pillsScroll.addView(pillsRow)
        aiToolbar.addView(pillsScroll)

        // Right 1: The Purple Sparkle Circle Button [ ✨ ] (Screenshot 1)
        val btnSparkle = FrameLayout(this).apply {
            val sBg = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(Color.parseColor("#A855F7")) // Vibrant Purple
            }
            background = sBg
            isClickable = true
            isFocusable = false
            layoutParams = LinearLayout.LayoutParams(dpToPx(34), dpToPx(34)).apply {
                marginStart = dpToPx(6)
            }

            val sIcon = ImageView(this@SaynInputMethodService).apply {
                setImageResource(R.drawable.ic_sayn_sparkles)
                setColorFilter(Color.WHITE)
                layoutParams = FrameLayout.LayoutParams(dpToPx(18), dpToPx(18), Gravity.CENTER)
            }
            addView(sIcon)

            setOnClickListener {
                triggerKeyFeedback("ENTER")
                openFullAiPanel(activeMode)
            }
        }
        aiToolbar.addView(btnSparkle)

        // Right 2: The Voice Dictation Mic Circle Button [ 🎤 ] (Screenshot 1)
        val btnVoice = FrameLayout(this).apply {
            val vBg = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(Color.parseColor("#2C2C2E"))
                setStroke(dpToPx(1f), Color.parseColor("#44FFFFFF"))
            }
            background = vBg
            isClickable = true
            isFocusable = false
            layoutParams = LinearLayout.LayoutParams(dpToPx(34), dpToPx(34)).apply {
                marginStart = dpToPx(5)
            }

            val vIcon = ImageView(this@SaynInputMethodService).apply {
                setImageResource(R.drawable.ic_sayn_mic)
                setColorFilter(Color.parseColor("#E5E7EB"))
                layoutParams = FrameLayout.LayoutParams(dpToPx(17), dpToPx(17), Gravity.CENTER)
            }
            addView(vIcon)

            setOnClickListener {
                triggerKeyFeedback("SPACE")
                toggleInKeyboardVoice()
            }
        }
        aiToolbar.addView(btnVoice)

        rootLayout.addView(aiToolbar)
    }

    private fun updateToolbarPills(pillsRow: LinearLayout) {
        for (i in 0 until pillsRow.childCount) {
            val pill = pillsRow.getChildAt(i) as? TextView ?: continue
            val modeId = modes[i].first
            val isSelected = modeId == activeMode
            pill.setTextColor(if (isSelected) Color.parseColor("#111115") else Color.parseColor("#8E8E93"))
            val pillBg = GradientDrawable().apply {
                cornerRadius = dpToPx(13).toFloat()
                setColor(if (isSelected) Color.parseColor("#CBFE00") else Color.parseColor("#2C2C2E"))
            }
            pill.background = pillBg
        }
    }

    // ─────────────────────────────────────────────────────────────────────────────
    // 4. Full AI Assistant Panel (Matching Screenshot 2)
    // ─────────────────────────────────────────────────────────────────────────────

    private fun buildFullAiPanel() {
        fullAiPanelContainer = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            visibility = View.GONE
            val bg = GradientDrawable().apply {
                setColor(Color.parseColor("#151A17"))
                cornerRadius = dpToPx(12).toFloat()
            }
            background = bg
            setPadding(dpToPx(8), dpToPx(6), dpToPx(8), dpToPx(8))
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                dpToPx(270) // Matches keyboard height perfectly!
            )
        }

        // 1. Top Strip: Mode Pills (Grammar, Rewrite, Humanize, Flow, Professional, etc.)
        val modesScroll = HorizontalScrollView(this).apply {
            isHorizontalScrollBarEnabled = false
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply { bottomMargin = dpToPx(8) }
        }

        aiPanelModesRow = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }

        for ((mId, mLabel) in modes) {
            val pill = TextView(this).apply {
                text = if (mId == "grammar") "② $mLabel" else mLabel
                textSize = 12f
                typeface = Typeface.DEFAULT_BOLD
                gravity = Gravity.CENTER
                setPadding(dpToPx(13), 0, dpToPx(13), 0)
                val isSelected = mId == activeMode
                setTextColor(if (isSelected) Color.parseColor("#22C55E") else Color.parseColor("#9CA3AF"))
                val pBg = GradientDrawable().apply {
                    cornerRadius = dpToPx(15).toFloat()
                    setColor(if (isSelected) Color.parseColor("#223829") else Color.parseColor("#202522"))
                    if (isSelected) setStroke(dpToPx(1.2f), Color.parseColor("#22C55E"))
                }
                background = pBg
                setOnClickListener {
                    triggerKeyFeedback("SPACE")
                    activeMode = mId
                    updateAiPanelModesHighlight()
                    runFullAiRefinement(mId)
                }
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.WRAP_CONTENT,
                    dpToPx(30)
                ).apply {
                    marginEnd = dpToPx(6)
                }
            }
            aiPanelModesRow.addView(pill)
        }
        modesScroll.addView(aiPanelModesRow)
        fullAiPanelContainer.addView(modesScroll)

        // 2. Center: Suggestion Card (Matching Screenshot 2)
        val card = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            val cardBg = GradientDrawable().apply {
                cornerRadius = dpToPx(14).toFloat()
                setColor(Color.parseColor("#1D2420"))
                setStroke(dpToPx(1f), Color.parseColor("#2C3A30"))
            }
            background = cardBg
            setPadding(dpToPx(14), dpToPx(12), dpToPx(14), dpToPx(10))
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                0,
                1f
            )
        }

        aiCardTitle = TextView(this).apply {
            text = "• Refinement"
            textSize = 12f
            setTextColor(Color.parseColor("#A1A1AA"))
            setPadding(0, 0, 0, dpToPx(4))
        }
        card.addView(aiCardTitle)

        val diffRow = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(0, dpToPx(2), 0, dpToPx(6))
        }
        aiCardDiffWord = TextView(this).apply {
            text = ""
            textSize = 17f
            setTextColor(Color.WHITE)
            typeface = Typeface.DEFAULT_BOLD
        }
        aiCardDiffBadge = TextView(this).apply {
            text = ""
            textSize = 15f
            setTextColor(Color.parseColor("#4ADE80"))
            typeface = Typeface.DEFAULT_BOLD
            val badgeBg = GradientDrawable().apply {
                cornerRadius = dpToPx(4).toFloat()
                setColor(Color.parseColor("#143521"))
                setStroke(dpToPx(1f), Color.parseColor("#22C55E"))
            }
            background = badgeBg
            setPadding(dpToPx(5), dpToPx(1), dpToPx(5), dpToPx(1))
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply { marginStart = dpToPx(4) }
        }
        diffRow.addView(aiCardDiffWord)
        diffRow.addView(aiCardDiffBadge)
        card.addView(diffRow)

        aiCardPreview = TextView(this).apply {
            text = "Type text to inspect refinement..."
            textSize = 13.5f
            setTextColor(Color.parseColor("#D1D5DB"))
            maxLines = 3
            ellipsize = android.text.TextUtils.TruncateAt.END
        }
        card.addView(aiCardPreview)

        val cardActionsRow = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(0, dpToPx(8), 0, 0)
        }

        btnAiAccept = TextView(this).apply {
            text = "Accept"
            textSize = 12.5f
            setTextColor(Color.parseColor("#F3F4F6"))
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            val aBg = GradientDrawable().apply {
                cornerRadius = dpToPx(14).toFloat()
                setColor(Color.parseColor("#2B382F"))
                setStroke(dpToPx(1f), Color.parseColor("#3B5041"))
            }
            background = aBg
            setPadding(dpToPx(18), 0, dpToPx(18), 0)
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                dpToPx(30)
            )
            setOnClickListener {
                triggerKeyFeedback("ENTER")
                handleAcceptCurrentSuggestion()
            }
        }

        btnAiDismiss = TextView(this).apply {
            text = "Dismiss"
            textSize = 12.5f
            setTextColor(Color.parseColor("#9CA3AF"))
            gravity = Gravity.CENTER
            setPadding(dpToPx(14), 0, dpToPx(14), 0)
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                dpToPx(30)
            ).apply { marginStart = dpToPx(8) }
            setOnClickListener {
                triggerKeyFeedback("DEL")
                closeFullAiPanel()
            }
        }

        cardActionsRow.addView(btnAiAccept)
        cardActionsRow.addView(btnAiDismiss)
        card.addView(cardActionsRow)

        fullAiPanelContainer.addView(card)

        // 3. Bottom Navigation Bar: [ ⌨ (Back to Keyboard) ]  • •  [ Accept all ]
        val bottomBar = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(0, dpToPx(8), 0, 0)
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                dpToPx(44)
            )
        }

        // Bottom Left: The Keyboard Button to go back to typing!
        btnAiBackToKeyboard = FrameLayout(this).apply {
            val kBg = GradientDrawable().apply {
                cornerRadius = dpToPx(9).toFloat()
                setColor(Color.parseColor("#262C27"))
                setStroke(dpToPx(1f), Color.parseColor("#38423A"))
            }
            background = kBg
            isClickable = true
            isFocusable = false
            layoutParams = LinearLayout.LayoutParams(dpToPx(42), dpToPx(38))

            val kIcon = ImageView(this@SaynInputMethodService).apply {
                setImageResource(R.drawable.ic_sayn_keyboard)
                setColorFilter(Color.parseColor("#E5E7EB"))
                layoutParams = FrameLayout.LayoutParams(
                    dpToPx(20),
                    dpToPx(20),
                    Gravity.CENTER
                )
            }
            addView(kIcon)

            setOnClickListener {
                triggerKeyFeedback("SPACE")
                closeFullAiPanel()
            }
        }
        bottomBar.addView(btnAiBackToKeyboard)

        // Center: Pagination Dots • •
        aiPagerIndicator = TextView(this).apply {
            text = "• •"
            textSize = 18f
            setTextColor(Color.parseColor("#9CA3AF"))
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.MATCH_PARENT, 1f)
        }
        bottomBar.addView(aiPagerIndicator)

        // Bottom Right: [ Accept all ] Pill Button in vibrant green
        btnAiAcceptAll = TextView(this).apply {
            text = "Accept all"
            textSize = 13.5f
            typeface = Typeface.DEFAULT_BOLD
            setTextColor(Color.parseColor("#052E16")) // Deep dark green text on bright green pill
            gravity = Gravity.CENTER
            val accBg = GradientDrawable().apply {
                cornerRadius = dpToPx(19).toFloat()
                setColor(Color.parseColor("#22C55E")) // Vibrant emerald green
            }
            background = accBg
            setPadding(dpToPx(22), 0, dpToPx(22), 0)
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                dpToPx(38)
            )
            setOnClickListener {
                triggerKeyFeedback("ENTER")
                handleAcceptAllSuggestions()
            }
        }
        bottomBar.addView(btnAiAcceptAll)

        fullAiPanelContainer.addView(bottomBar)

        rootLayout.addView(fullAiPanelContainer)
    }

    private fun updateAiPanelModesHighlight() {
        for (i in 0 until aiPanelModesRow.childCount) {
            val pill = aiPanelModesRow.getChildAt(i) as? TextView ?: continue
            val (mId, _) = modes.getOrNull(i) ?: continue
            val isSelected = mId == activeMode
            pill.setTextColor(if (isSelected) Color.parseColor("#22C55E") else Color.parseColor("#9CA3AF"))
            val pBg = GradientDrawable().apply {
                cornerRadius = dpToPx(15).toFloat()
                setColor(if (isSelected) Color.parseColor("#223829") else Color.parseColor("#202522"))
                if (isSelected) setStroke(dpToPx(1.2f), Color.parseColor("#22C55E"))
            }
            pill.background = pBg
        }
    }

    private fun openFullAiPanel(mode: String = activeMode) {
        val ic = currentInputConnection ?: return
        val selected = ic.getSelectedText(0)?.toString()
        val textToTransform = if (!selected.isNullOrBlank()) {
            selected.trim()
        } else {
            (ic.getTextBeforeCursor(400, 0)?.toString() ?: "").trim()
        }

        lastOriginalText = textToTransform
        keysContainer.visibility = View.GONE
        aiToolbar.visibility = View.GONE
        voiceLiveBar.visibility = View.GONE
        suggestionArea.visibility = View.GONE
        fullAiPanelContainer.visibility = View.VISIBLE

        if (textToTransform.isBlank()) {
            aiCardTitle.text = "• Input Empty"
            aiCardDiffWord.text = "Type some words first"
            aiCardDiffBadge.text = ""
            aiCardPreview.text = "Tap the keyboard button at bottom left [⌨] to type a message, then tap the purple sparkle [✨] to polish it!"
            return
        }

        runFullAiRefinement(mode)
    }

    private fun closeFullAiPanel() {
        fullAiPanelContainer.visibility = View.GONE
        keysContainer.visibility = View.VISIBLE
        aiToolbar.visibility = if (isSensitiveField) View.GONE else View.VISIBLE
    }

    private fun formatModeTitle(mode: String): String {
        return if (mode.isNotEmpty()) {
            mode.substring(0, 1).uppercase(Locale.ROOT) + mode.substring(1)
        } else {
            mode
        }
    }

    private fun runFullAiRefinement(mode: String) {
        if (lastOriginalText.isBlank()) return
        aiCardTitle.text = "• Refining (${formatModeTitle(mode)})..."
        aiCardDiffWord.text = "Analyzing..."
        aiCardDiffBadge.text = ""
        aiCardPreview.text = "SAYN AI is polishing your text..."

        CoroutineScope(Dispatchers.IO).launch {
            try {
                val refined = requestAiRefinement(lastOriginalText, mode)
                withContext(Dispatchers.Main) {
                    lastSuggestion = refined
                    aiCardTitle.text = when (mode) {
                        "grammar" -> "• Grammar correction"
                        "flow" -> "• Flow optimization"
                        "professional" -> "• Professional polish"
                        "humanize" -> "• Humanized tone"
                        else -> "• ${formatModeTitle(mode)} Polish"
                    }
                    val diff = extractDiffSnippet(lastOriginalText, refined)
                    aiCardDiffWord.text = diff.first
                    aiCardDiffBadge.text = diff.second
                    aiCardPreview.text = refined
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    aiCardTitle.text = "• Offline Mode"
                    aiCardDiffWord.text = "Could not reach AI"
                    aiCardDiffBadge.text = ""
                    aiCardPreview.text = lastOriginalText
                }
            }
        }
    }

    private fun extractDiffSnippet(original: String, refined: String): Pair<String, String> {
        val origWords = original.split(" ")
        val refWords = refined.split(" ")
        val limit = Math.min(origWords.size, refWords.size)
        for (i in 0 until limit) {
            if (origWords[i] != refWords[i]) {
                return Pair(origWords[i], "[${refWords[i]}]")
            }
        }
        if (refWords.size > origWords.size) {
            return Pair(origWords.lastOrNull() ?: "", "[+${refWords.takeLast(refWords.size - origWords.size).joinToString(" ")}]")
        }
        return Pair("Refined", "✓")
    }

    private fun handleAcceptCurrentSuggestion() {
        val ic = currentInputConnection ?: return
        if (lastSuggestion.isNotEmpty()) {
            val selected = ic.getSelectedText(0)?.toString()
            if (!selected.isNullOrBlank()) {
                ic.commitText(lastSuggestion, 1)
            } else {
                val textBefore = ic.getTextBeforeCursor(lastOriginalText.length, 0)?.toString() ?: ""
                if (textBefore.isNotEmpty()) {
                    ic.deleteSurroundingText(textBefore.length, 0)
                }
                ic.commitText(lastSuggestion, 1)
            }
            Toast.makeText(this, "Accepted & replaced!", Toast.LENGTH_SHORT).show()
        }
        closeFullAiPanel()
    }

    private fun handleAcceptAllSuggestions() {
        handleAcceptCurrentSuggestion()
    }

    // ─────────────────────────────────────────────────────────────────────────────
    // 4. Cloudflare Edge AI Refinement
    // ─────────────────────────────────────────────────────────────────────────────

    private fun triggerRefinement(mode: String) {
        val ic = currentInputConnection ?: return
        if (isSensitiveField || isRefining) return

        val selected = ic.getSelectedText(0)?.toString()
        val textToTransform = if (!selected.isNullOrBlank()) {
            selected.trim()
        } else {
            (ic.getTextBeforeCursor(400, 0)?.toString() ?: "").trim()
        }

        if (textToTransform.isBlank()) {
            Toast.makeText(this, "Type something to refine (${mode})", Toast.LENGTH_SHORT).show()
            return
        }

        lastOriginalText = textToTransform
        isRefining = true
        Toast.makeText(this, "SAYN refining (${mode})...", Toast.LENGTH_SHORT).show()

        CoroutineScope(Dispatchers.IO).launch {
            try {
                val refined = requestAiRefinement(textToTransform, mode)
                withContext(Dispatchers.Main) {
                    showSuggestion(refined, mode)
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    Toast.makeText(applicationContext, "Refinement unavailable: check connection", Toast.LENGTH_SHORT).show()
                }
            } finally {
                withContext(Dispatchers.Main) {
                    isRefining = false
                }
            }
        }
    }

    private suspend fun requestAiRefinement(text: String, mode: String): String {
        return try {
            SaynCloudVoiceClient.refineText(
                rawText = text,
                activeAppPackage = currentInputEditorInfo?.packageName,
                mode = mode
            )
        } catch (e: Exception) {
            text
        }
    }

    // ─────────────────────────────────────────────────────────────────────────────
    // 5. In-Keyboard Speech Recognizer (San Voice Flow)
    // ─────────────────────────────────────────────────────────────────────────────

    private fun toggleInKeyboardVoice() {
        if (isListening) {
            stopInKeyboardVoice()
            hideVoiceLiveBar()
        } else {
            startInKeyboardVoice()
        }
    }

    private fun startInKeyboardVoice() {
        // 1. Permission check
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            Toast.makeText(this, "Microphone permission required for SAYN voice", Toast.LENGTH_LONG).show()
            val intent = Intent(this, MainActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                putExtra("request_mic_permission", true)
            }
            startActivity(intent)
            return
        }

        // Tear down any previous recognizer session
        destroySpeechRecognizer()

        val recognizer = createSpeechRecognizerSafe()
        if (recognizer == null) {
            Toast.makeText(this, "Speech recognition unavailable on this device", Toast.LENGTH_SHORT).show()
            return
        }

        speechRecognizer = recognizer
        speechRecognizer?.setRecognitionListener(object : RecognitionListener {
            override fun onReadyForSpeech(params: Bundle?) {
                voiceTranscriptText.text = "Listening... speak now"
            }

            override fun onBeginningOfSpeech() {
                voiceTranscriptText.text = "Hearing speech..."
                voiceStatusDot.setTextColor(Color.parseColor("#34C759")) // Green while actively detecting voice
            }

            override fun onRmsChanged(rmsdB: Float) {}

            override fun onBufferReceived(buffer: ByteArray?) {}

            override fun onEndOfSpeech() {
                voiceTranscriptText.text = "Processing speech..."
                voiceStatusDot.setTextColor(Color.parseColor("#FF9F0A"))
            }

            override fun onError(error: Int) {
                isListening = false
                voiceStatusDot.setTextColor(Color.parseColor("#FF453A"))

                // Clean up immediately so subsequent tap works cleanly
                destroySpeechRecognizer()

                when (error) {
                    9 -> { // INSUFFICIENT_PERMISSIONS
                        Toast.makeText(applicationContext, "Microphone permission needed", Toast.LENGTH_SHORT).show()
                        val intent = Intent(applicationContext, MainActivity::class.java).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                            putExtra("request_mic_permission", true)
                        }
                        startActivity(intent)
                    }
                    5 -> { // ERROR_CLIENT
                        voiceTranscriptText.text = "Tap mic to retry"
                        Toast.makeText(applicationContext, "Speech engine reconnecting. Tap mic again to speak.", Toast.LENGTH_SHORT).show()
                    }
                    SpeechRecognizer.ERROR_NO_MATCH, SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> {
                        if (currentSpokenText.isEmpty()) {
                            voiceTranscriptText.text = "No speech. Tap mic to retry"
                        }
                    }
                    SpeechRecognizer.ERROR_NETWORK, SpeechRecognizer.ERROR_NETWORK_TIMEOUT -> {
                        voiceTranscriptText.text = "Network timeout. Check connection."
                    }
                    SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> {
                        voiceTranscriptText.text = "Microphone busy. Tap to retry"
                    }
                    else -> {
                        voiceTranscriptText.text = "Mic error ($error). Tap to retry"
                    }
                }
            }

            override fun onResults(results: Bundle?) {
                val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                if (!matches.isNullOrEmpty()) {
                    currentSpokenText = matches[0]
                    voiceTranscriptText.text = currentSpokenText
                    voiceTranscriptText.setTextColor(Color.WHITE)
                }
                isListening = false
                voiceStatusDot.setTextColor(Color.parseColor("#8E8E93"))
            }

            override fun onPartialResults(partialResults: Bundle?) {
                val matches = partialResults?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                if (!matches.isNullOrEmpty()) {
                    currentSpokenText = matches[0]
                    voiceTranscriptText.text = currentSpokenText
                    voiceTranscriptText.setTextColor(Color.WHITE)
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
            currentSpokenText = ""
            showVoiceLiveBar()
        } catch (e: Exception) {
            destroySpeechRecognizer()
            Toast.makeText(this, "Could not start microphone", Toast.LENGTH_SHORT).show()
        }
    }

    private fun createSpeechRecognizerSafe(): SpeechRecognizer? {
        return try {
            // Android 13+ on-device recognizer if available
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
                SpeechRecognizer.isOnDeviceRecognitionAvailable(applicationContext)
            ) {
                return SpeechRecognizer.createOnDeviceSpeechRecognizer(applicationContext)
            }

            // Check installed RecognitionService components
            val pm = packageManager
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
                return SpeechRecognizer.createSpeechRecognizer(applicationContext, comp)
            }

            if (services.isNotEmpty()) {
                val first = services[0]
                val comp = android.content.ComponentName(
                    first.serviceInfo.packageName,
                    first.serviceInfo.name
                )
                return SpeechRecognizer.createSpeechRecognizer(applicationContext, comp)
            }

            SpeechRecognizer.createSpeechRecognizer(applicationContext)
        } catch (e: Exception) {
            try {
                SpeechRecognizer.createSpeechRecognizer(applicationContext)
            } catch (e2: Exception) {
                null
            }
        }
    }

    private fun stopInKeyboardVoice() {
        if (isListening) {
            try {
                speechRecognizer?.stopListening()
            } catch (e: Exception) {}
            isListening = false
        }
        destroySpeechRecognizer()
    }

    private fun destroySpeechRecognizer() {
        try {
            speechRecognizer?.destroy()
        } catch (e: Exception) {}
        speechRecognizer = null
    }

    // ─────────────────────────────────────────────────────────────────────────────
    // 6. Authentic iOS Dark Chiclet Virtual Keyboard
    // ─────────────────────────────────────────────────────────────────────────────

    private fun buildKeysLayout() {
        keysContainer = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
        }
        rootLayout.addView(keysContainer)
        renderKeys()
    }

    private fun renderKeys() {
        keysContainer.removeAllViews()

        when (symbolLayoutMode) {
            0 -> renderQwertyLayout()
            1 -> renderSymbols123Layout()
            2 -> renderSymbolsAltLayout()
            3 -> renderEmojiLayout()
        }
    }

    private fun renderQwertyLayout() {
        // Row 1: Q W E R T Y U I O P (10 keys - weight: 1.0 each = 10.0f)
        val row1 = listOf("Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P")
        keysContainer.addView(createRowView(row1, hasSpacer = false))

        // Row 2: A S D F G H J K L (9 keys, perfectly centered with 0.5f spacer on left & right = 10.0f)
        val row2 = listOf("A", "S", "D", "F", "G", "H", "J", "K", "L")
        keysContainer.addView(createRowView(row2, hasSpacer = true))

        // Row 3: SHIFT (1.45f), Z X C V B N M (7.0f), DEL (1.55f) = 10.0f
        val row3 = listOf("SHIFT", "Z", "X", "C", "V", "B", "N", "M", "DEL")
        keysContainer.addView(createRowView(row3, hasSpacer = false))

        // Row 4: EMOJI in bottom left corner! (1.25f), 123 (1.25f), SPACE (4.5f), MIC (1.15f), ENTER (1.85f) = 10.0f
        val row4 = listOf("EMOJI", "123", "SPACE", "MIC", "ENTER")
        keysContainer.addView(createRowView(row4, hasSpacer = false))
    }

    private fun renderSymbols123Layout() {
        val row1 = listOf("1", "2", "3", "4", "5", "6", "7", "8", "9", "0")
        keysContainer.addView(createRowView(row1, hasSpacer = false))

        val row2 = listOf("-", "/", ":", ";", "(", ")", "$", "&", "@", "\"")
        keysContainer.addView(createRowView(row2, hasSpacer = false))

        val row3 = listOf("#+=", ".", ",", "?", "!", "'", "DEL")
        keysContainer.addView(createRowView(row3, hasSpacer = false))

        val row4 = listOf("EMOJI", "ABC", "SPACE", "MIC", "ENTER")
        keysContainer.addView(createRowView(row4, hasSpacer = false))
    }

    private fun renderSymbolsAltLayout() {
        val row1 = listOf("[", "]", "{", "}", "#", "%", "^", "*", "+", "=")
        keysContainer.addView(createRowView(row1, hasSpacer = false))

        val row2 = listOf("_", "\\", "|", "~", "<", ">", "€", "£", "¥", "•")
        keysContainer.addView(createRowView(row2, hasSpacer = false))

        val row3 = listOf("123", ".", ",", "?", "!", "'", "DEL")
        keysContainer.addView(createRowView(row3, hasSpacer = false))

        val row4 = listOf("EMOJI", "ABC", "SPACE", "MIC", "ENTER")
        keysContainer.addView(createRowView(row4, hasSpacer = false))
    }

    private fun renderEmojiLayout() {
        val emojiScroll = HorizontalScrollView(this).apply {
            isHorizontalScrollBarEnabled = false
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                dpToPx(152)
            ).apply { bottomMargin = dpToPx(7) }
        }

        val emojiGrid = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dpToPx(4), 0, dpToPx(4), 0)
        }

        val emojiRows = listOf(
            listOf("😀", "😃", "😄", "😁", "😆", "😅", "😂", "🤣", "😊", "😇", "🙂", "🙃", "😉", "😍", "🥰", "😘", "😋", "😜", "🤪", "😎", "🤩", "🥳", "🥺"),
            listOf("👍", "👎", "👏", "🙌", "🤝", "👊", "✌️", "🤞", "🤟", "🤘", "👌", "👈", "👉", "👆", "👇", "✋", "👋", "🤙", "💪", "🙏", "✍️", "🤳", "🔥"),
            listOf("❤️", "🧡", "💛", "💚", "💙", "💜", "🖤", "🤍", "💔", "❣️", "💕", "✨", "💯", "🎉", "🚀", "⭐", "💡", "📌", "🎯", "🏆", "👑", "🍕", "☕")
        )

        for (row in emojiRows) {
            val rowView = LinearLayout(this).apply {
                orientation = LinearLayout.HORIZONTAL
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.WRAP_CONTENT,
                    dpToPx(48)
                ).apply { bottomMargin = dpToPx(3) }
            }

            for (emoji in row) {
                val emojiButton = TextView(this).apply {
                    text = emoji
                    textSize = 23f
                    gravity = Gravity.CENTER
                    setPadding(dpToPx(8), dpToPx(4), dpToPx(8), dpToPx(4))
                    isClickable = true
                    isFocusable = false
                    setOnClickListener {
                        triggerKeyFeedback("SPACE")
                        currentInputConnection?.commitText(emoji, 1)
                    }
                }
                rowView.addView(emojiButton)
            }
            emojiGrid.addView(rowView)
        }

        emojiScroll.addView(emojiGrid)
        keysContainer.addView(emojiScroll)

        // Bottom control row in emoji layout: [ ABC ] [ 123 ] [ SPACE ] [ DEL ] [ ENTER ]
        val bottomRow = listOf("ABC", "123", "SPACE", "DEL", "ENTER")
        keysContainer.addView(createRowView(bottomRow, hasSpacer = false))
    }

    private fun createRowView(keys: List<String>, hasSpacer: Boolean): LinearLayout {
        val rowLayout = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                dpToPx(46)
            ).apply { bottomMargin = dpToPx(7) }
        }

        if (hasSpacer) {
            val leftSpacer = View(this).apply {
                layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.MATCH_PARENT, 0.5f)
            }
            rowLayout.addView(leftSpacer)
        }

        for (key in keys) {
            val weight = when (key) {
                "SPACE" -> 4.5f
                "ENTER" -> 1.85f
                "SHIFT" -> 1.45f
                "DEL" -> 1.55f
                "123", "ABC", "#+=" -> 1.25f
                "EMOJI" -> 1.25f
                "MIC" -> 1.15f
                else -> 1.0f
            }

            val keyView = buildKeycapView(key, weight)
            rowLayout.addView(keyView)
        }

        if (hasSpacer) {
            val rightSpacer = View(this).apply {
                layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.MATCH_PARENT, 0.5f)
            }
            rowLayout.addView(rightSpacer)
        }

        return rowLayout
    }

    private fun buildKeycapView(key: String, weight: Float): TextView {
        val displayText = formatKeyText(key)
        val isSpecial = key in listOf("ENTER", "123", "ABC", "#+=", "DEL", "SHIFT", "GLOBE", "MIC", "EMOJI")

        val keyView = TextView(this).apply {
            text = displayText
            gravity = Gravity.CENTER
            includeFontPadding = false
            setPadding(0, 0, 0, 0)
            minWidth = 0
            minHeight = 0
            isClickable = true
            isFocusable = false

            // Crisp typography matching normal keyboards
            if (key.length == 1 && symbolLayoutMode == 0) {
                textSize = 22.5f
                typeface = Typeface.DEFAULT
                setTextColor(Color.WHITE)
            } else if (key == "ENTER") {
                textSize = 14f
                typeface = Typeface.DEFAULT_BOLD
                setTextColor(Color.parseColor("#111115")) // Contrast dark text on volt neon green key
            } else if (key in listOf("SHIFT", "DEL")) {
                textSize = 18f
                typeface = Typeface.DEFAULT
                setTextColor(if (key == "SHIFT" && (isShifted || isCapsLock)) Color.BLACK else Color.WHITE)
            } else if (key == "SPACE") {
                textSize = 14f
                typeface = Typeface.DEFAULT
                setTextColor(Color.parseColor("#D1D1D6"))
            } else if (key in listOf("123", "ABC", "#+=")) {
                textSize = 14f
                typeface = Typeface.DEFAULT
                setTextColor(Color.WHITE)
            } else if (key == "EMOJI") {
                textSize = 20f
                typeface = Typeface.DEFAULT
                setTextColor(Color.WHITE)
            } else {
                textSize = 16f
                typeface = Typeface.DEFAULT
                setTextColor(Color.WHITE)
            }

            // Authentic vector icons replacing emojis
            if (key == "MIC") {
                text = ""
                val micDrawable = ContextCompat.getDrawable(this@SaynInputMethodService, R.drawable.ic_sayn_mic)?.mutate()
                micDrawable?.setBounds(0, 0, dpToPx(19), dpToPx(19))
                micDrawable?.setColorFilter(Color.parseColor("#CBFE00"), PorterDuff.Mode.SRC_IN)
                setCompoundDrawables(null, micDrawable, null, null)
            } else if (key == "GLOBE") {
                text = ""
                val globeDrawable = ContextCompat.getDrawable(this@SaynInputMethodService, R.drawable.ic_sayn_globe)?.mutate()
                globeDrawable?.setBounds(0, 0, dpToPx(18), dpToPx(18))
                globeDrawable?.setColorFilter(Color.WHITE, PorterDuff.Mode.SRC_IN)
                setCompoundDrawables(null, globeDrawable, null, null)
            }

            // Authentic tactile Chiclet Backgrounds
            val bg = when {
                key == "ENTER" -> {
                    createIosKeyDrawable(
                        normalColor = Color.parseColor("#CBFE00"), // San Volt Neon Green
                        pressedColor = Color.parseColor("#A6CF00"),
                        shadowColor = Color.parseColor("#80A000")
                    )
                }
                key == "SHIFT" && (isShifted || isCapsLock) -> {
                    createIosKeyDrawable(
                        normalColor = Color.WHITE,
                        pressedColor = Color.parseColor("#D1D1D6"),
                        shadowColor = Color.parseColor("#8E8E93")
                    )
                }
                isSpecial -> {
                    createIosKeyDrawable(
                        normalColor = Color.parseColor("#2C2C2E"),
                        pressedColor = Color.parseColor("#424246"),
                        shadowColor = Color.parseColor("#18181A")
                    )
                }
                else -> {
                    createIosKeyDrawable(
                        normalColor = Color.parseColor("#4A4A4D"),
                        pressedColor = Color.parseColor("#636366"),
                        shadowColor = Color.parseColor("#202022")
                    )
                }
            }
            background = bg

            // Backspace hold-to-repeat
            if (key == "DEL") {
                setupDeleteRepeat(this)
            } else {
                setOnClickListener {
                    triggerKeyFeedback(key)
                    handleKeyAction(key)
                }
            }

            layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.MATCH_PARENT, weight).apply {
                marginStart = dpToPx(2.5f)
                marginEnd = dpToPx(2.5f)
            }
        }

        return keyView
    }

    private fun formatKeyText(key: String): String {
        return when (key) {
            "SHIFT" -> if (isCapsLock || isShifted) "▲" else "⇧"
            "DEL" -> "⌫"
            "GLOBE" -> ""
            "MIC" -> ""
            "EMOJI" -> "😊"
            "SPACE" -> "space"
            "ENTER" -> {
                val currentInfo = currentInputEditorInfo
                val action = currentInfo?.imeOptions?.and(EditorInfo.IME_MASK_ACTION) ?: EditorInfo.IME_ACTION_NONE
                when (action) {
                    EditorInfo.IME_ACTION_SEARCH -> "search"
                    EditorInfo.IME_ACTION_GO -> "go"
                    EditorInfo.IME_ACTION_SEND -> "send"
                    EditorInfo.IME_ACTION_NEXT -> "next"
                    EditorInfo.IME_ACTION_DONE -> "done"
                    else -> "return"
                }
            }
            else -> if (key.length == 1 && symbolLayoutMode == 0) {
                if (isShifted || isCapsLock) key.uppercase() else key.lowercase()
            } else {
                key
            }
        }
    }

    /**
     * Applies deterministic auto-correction strictly inside the keyboard.
     * Corrects common typos, missing apostrophes, and capitalization (e.g. "teh" -> "the", "dont" -> "don't", "im" -> "I'm", lone "i" -> "I").
     */
    private fun applyAutoCorrect(delimiter: String) {
        val ic = currentInputConnection ?: return
        if (!isAutoCorrectEnabled || isSensitiveField) {
            if (delimiter.isNotEmpty()) ic.commitText(delimiter, 1)
            return
        }

        val before = ic.getTextBeforeCursor(40, 0)?.toString() ?: ""
        if (before.isEmpty()) {
            if (delimiter.isNotEmpty()) ic.commitText(delimiter, 1)
            return
        }

        val match = Regex("""([a-zA-Z']+)\z""").find(before)
        if (match != null) {
            val rawWord = match.value
            val lower = rawWord.lowercase()

            val replacement = when {
                rawWord == "i" -> "I"
                autoCorrectMap.containsKey(lower) -> {
                    val corrected = autoCorrectMap[lower]!!
                    when {
                        rawWord.all { it.isUpperCase() } && rawWord.length > 1 -> corrected.uppercase()
                        rawWord.first().isUpperCase() -> corrected.replaceFirstChar { it.uppercase() }
                        else -> corrected
                    }
                }
                else -> null
            }

            if (replacement != null && replacement != rawWord) {
                ic.deleteSurroundingText(rawWord.length, 0)
                ic.commitText(replacement + delimiter, 1)
                return
            }
        }

        if (delimiter.isNotEmpty()) {
            ic.commitText(delimiter, 1)
        }
    }

    private fun handleKeyAction(key: String) {
        val ic = currentInputConnection ?: return
        when (key) {
            "DEL" -> ic.deleteSurroundingText(1, 0)
            "SPACE" -> applyAutoCorrect(" ")
            "ENTER" -> {
                applyAutoCorrect("")
                handleEnterAction()
            }
            "MIC" -> toggleInKeyboardVoice()
            "EMOJI" -> {
                symbolLayoutMode = if (symbolLayoutMode == 3) 0 else 3
                renderKeys()
            }
            "123" -> {
                symbolLayoutMode = 1
                renderKeys()
            }
            "#+=" -> {
                symbolLayoutMode = 2
                renderKeys()
            }
            "ABC" -> {
                symbolLayoutMode = 0
                renderKeys()
            }
            "." -> applyAutoCorrect(".")
            "," -> applyAutoCorrect(",")
            "!" -> applyAutoCorrect("!")
            "?" -> applyAutoCorrect("?")
            "SHIFT" -> {
                val now = System.currentTimeMillis()
                if (now - lastShiftPressTime < 350) {
                    // Double tap: Caps lock
                    isCapsLock = !isCapsLock
                    isShifted = isCapsLock
                } else {
                    if (isCapsLock) {
                        isCapsLock = false
                        isShifted = false
                    } else {
                        isShifted = !isShifted
                    }
                }
                lastShiftPressTime = now
                renderKeys()
            }
            "GLOBE" -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                    switchToPreviousInputMethod()
                } else {
                    val imm = getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
                    imm.showInputMethodPicker()
                }
            }
            else -> {
                val charToCommit = if (key.length == 1 && symbolLayoutMode == 0) {
                    if (isShifted || isCapsLock) key.uppercase() else key.lowercase()
                } else {
                    key
                }
                ic.commitText(charToCommit, 1)

                if (isShifted && !isCapsLock) {
                    isShifted = false
                    renderKeys()
                }
            }
        }
    }

    private fun setupDeleteRepeat(view: View) {
        view.setOnTouchListener { v, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    triggerKeyFeedback("DEL")
                    handleKeyAction("DEL")
                    deleteRunnable = object : Runnable {
                        override fun run() {
                            handleKeyAction("DEL")
                            deleteHandler.postDelayed(this, 50)
                        }
                    }
                    deleteHandler.postDelayed(deleteRunnable!!, 350)
                    true
                }
                MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                    deleteRunnable?.let { deleteHandler.removeCallbacks(it) }
                    deleteRunnable = null
                    true
                }
                else -> false
            }
        }
    }

    private fun handleEnterAction() {
        val ic = currentInputConnection ?: return
        val currentInfo = currentInputEditorInfo
        val action = currentInfo?.imeOptions?.and(EditorInfo.IME_MASK_ACTION) ?: EditorInfo.IME_ACTION_NONE

        if (action != EditorInfo.IME_ACTION_NONE && action != EditorInfo.IME_ACTION_UNSPECIFIED) {
            ic.performEditorAction(action)
        } else {
            ic.commitText("\n", 1)
        }
    }

    private fun vibrateTap() {
        triggerKeyFeedback("SPACE")
    }

    private fun triggerKeyFeedback(key: String) {
        // 1. Audio Click Sound
        if (isSoundEnabled) {
            val fx = when (key) {
                "DEL" -> AudioManager.FX_KEYPRESS_DELETE
                "SPACE" -> AudioManager.FX_KEYPRESS_SPACEBAR
                "ENTER" -> AudioManager.FX_KEYPRESS_RETURN
                else -> AudioManager.FX_KEYPRESS_STANDARD
            }
            try {
                audioManager?.playSoundEffect(fx, 0.65f)
            } catch (e: Exception) {}
        }

        // 2. Physical Vibration Pulse
        if (isVibrationEnabled) {
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    val (duration, amplitude) = when (vibrationIntensity) {
                        "subtle" -> Pair(12L, 50)
                        "strong" -> Pair(35L, 210)
                        else -> Pair(20L, 120) // medium
                    }
                    vibrator?.vibrate(VibrationEffect.createOneShot(duration, amplitude))
                } else {
                    @Suppress("DEPRECATION")
                    vibrator?.vibrate(20L)
                }
            } catch (e: Exception) {
                try {
                    rootLayout.performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP)
                } catch (ex: Exception) {}
            }
        }
    }

    /**
     * Creates an authentic iOS tactile chiclet keycap with a physical bottom drop shadow.
     */
    private fun createIosKeyDrawable(
        normalColor: Int,
        pressedColor: Int,
        shadowColor: Int = Color.parseColor("#202022"),
        cornerRadiusDp: Float = 5f
    ): StateListDrawable {
        val states = StateListDrawable()
        val shadowInsetBottom = dpToPx(1.5f)

        // Pressed state
        val pressedFace = GradientDrawable().apply {
            setColor(pressedColor)
            cornerRadius = dpToPx(cornerRadiusDp).toFloat()
        }
        val pressedShadow = GradientDrawable().apply {
            setColor(shadowColor)
            cornerRadius = dpToPx(cornerRadiusDp).toFloat()
        }
        val pressedLayer = LayerDrawable(arrayOf(pressedShadow, pressedFace)).apply {
            setLayerInset(1, 0, 0, 0, shadowInsetBottom)
        }

        // Normal state
        val normalFace = GradientDrawable().apply {
            setColor(normalColor)
            cornerRadius = dpToPx(cornerRadiusDp).toFloat()
        }
        val normalShadow = GradientDrawable().apply {
            setColor(shadowColor)
            cornerRadius = dpToPx(cornerRadiusDp).toFloat()
        }
        val normalLayer = LayerDrawable(arrayOf(normalShadow, normalFace)).apply {
            setLayerInset(1, 0, 0, 0, shadowInsetBottom)
        }

        states.addState(intArrayOf(android.R.attr.state_pressed), pressedLayer)
        states.addState(intArrayOf(), normalLayer)
        return states
    }

    override fun onDestroy() {
        super.onDestroy()
        if (instance == this) instance = null
        destroySpeechRecognizer()
        deleteRunnable?.let { deleteHandler.removeCallbacks(it) }
    }

    private fun dpToPx(dp: Float): Int = (dp * resources.displayMetrics.density).toInt()
    private fun dpToPx(dp: Int): Int = (dp * resources.displayMetrics.density).toInt()
}
