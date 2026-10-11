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
import com.sayn.app.MainActivity
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

    // Wispr Voice Live Bar Views
    private lateinit var voiceStatusDot: TextView
    private lateinit var voiceStatusText: TextView
    private lateinit var voiceTranscriptText: TextView
    private lateinit var btnCorrectAndInsert: TextView
    private lateinit var btnVoiceRefine: TextView
    private lateinit var btnVoiceDismiss: TextView

    // Suggestion Area Views
    private lateinit var suggestionBadge: TextView
    private lateinit var suggestionText: TextView
    private lateinit var btnReplace: TextView
    private lateinit var btnInsert: TextView
    private lateinit var btnCopy: TextView
    private lateinit var btnDismiss: TextView

    // State Variables
    private var isSensitiveField = false
    private var symbolLayoutMode = 0 // 0 = Letters, 1 = 123, 2 = #+=
    private var isShifted = false
    private var isCapsLock = false
    private var lastShiftPressTime = 0L
    private var isRefining = false
    private var activeMode = "standard"
    private var lastSuggestion = ""
    private var lastOriginalText = ""

    // Speech Recognizer for In-Keyboard Dictation (Wispr flow)
    private var speechRecognizer: SpeechRecognizer? = null
    private var isListening = false
    private var currentSpokenText = ""

    // Delete repeat handler
    private val deleteHandler = Handler(Looper.getMainLooper())
    private var deleteRunnable: Runnable? = null

    // Writing Modes (QuillBot & Wispr Flow style)
    private val modes = listOf(
        "standard" to "Standard",
        "fluent" to "Fluent",
        "natural" to "Natural",
        "professional" to "Professional",
        "casual" to "Casual",
        "shorten" to "Shorten",
        "expand" to "Expand"
    )

    override fun onCreate() {
        super.onCreate()
        val prefs = getSharedPreferences("com.sayn.app.PREFS", Context.MODE_PRIVATE)
        activeMode = prefs.getString("default_mode", "standard") ?: "standard"
    }

    override fun onCreateInputView(): View {
        rootLayout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.parseColor("#1C1C1E")) // Authentic iOS Dark Gray
            setPadding(dpToPx(3), dpToPx(3), dpToPx(3), dpToPx(6))
        }

        buildVoiceLiveBar()
        buildSuggestionArea()
        buildAiToolbar()
        buildKeysLayout()

        return rootLayout
    }

    override fun onStartInputView(info: EditorInfo?, restarting: Boolean) {
        super.onStartInputView(info, restarting)
        isSensitiveField = SensitiveFieldGuard.isSensitiveField(info)

        hideVoiceLiveBar()
        hideSuggestionArea()

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

    // ─────────────────────────────────────────────────────────────────────────────
    // 1. Wispr Live Voice Dictation Bar
    // ─────────────────────────────────────────────────────────────────────────────

    private fun buildVoiceLiveBar() {
        voiceLiveBar = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            visibility = View.GONE
            val bg = GradientDrawable().apply {
                cornerRadius = dpToPx(10).toFloat()
                setColor(Color.parseColor("#252528"))
                setStroke(dpToPx(1.2f), Color.parseColor("#007AFF")) // iOS Blue border
            }
            background = bg
            setPadding(dpToPx(10), dpToPx(8), dpToPx(10), dpToPx(8))
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply { bottomMargin = dpToPx(4) }
        }

        // Top Status Row: Pulsing Dot + Status + Close
        val statusRow = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }

        voiceStatusDot = TextView(this).apply {
            text = "●"
            textSize = 12f
            setTextColor(Color.parseColor("#FF453A")) // Red recording dot
            setPadding(0, 0, dpToPx(5), 0)
        }

        voiceStatusText = TextView(this).apply {
            text = "Listening... speak now"
            textSize = 11f
            setTextColor(Color.parseColor("#5DE4FF"))
            typeface = Typeface.DEFAULT_BOLD
            layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
        }

        btnVoiceDismiss = TextView(this).apply {
            text = "✕"
            textSize = 14f
            setTextColor(Color.parseColor("#8E8E93"))
            gravity = Gravity.CENTER
            setPadding(dpToPx(8), 0, dpToPx(4), 0)
            setOnClickListener {
                stopInKeyboardVoice()
                hideVoiceLiveBar()
            }
        }

        statusRow.addView(voiceStatusDot)
        statusRow.addView(voiceStatusText)
        statusRow.addView(btnVoiceDismiss)
        voiceLiveBar.addView(statusRow)

        // Live Real-Time Transcript Text Box
        voiceTranscriptText = TextView(this).apply {
            text = "Say anything... Wispr is capturing your speech"
            textSize = 13.5f
            setTextColor(Color.parseColor("#E5E5EA"))
            setPadding(0, dpToPx(5), 0, dpToPx(6))
            maxLines = 3
        }
        voiceLiveBar.addView(voiceTranscriptText)

        // Action Buttons Row: Correct & Insert, Refine & Insert
        val actionRow = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }

        // "✓ Correct" Button -> COMMITS IMMEDIATELY to where the user is typing & dismisses!
        btnCorrectAndInsert = TextView(this).apply {
            text = "✓ Correct"
            textSize = 12f
            setTextColor(Color.WHITE)
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            background = createIosKeyDrawable(
                normalColor = Color.parseColor("#007AFF"),
                pressedColor = Color.parseColor("#0056B3"),
                shadowColor = Color.parseColor("#004085"),
                cornerRadiusDp = 7f
            )
            setOnClickListener {
                vibrateTap()
                stopInKeyboardVoice()
                commitSpokenTextToInput()
            }
            layoutParams = LinearLayout.LayoutParams(0, dpToPx(34), 1.2f).apply {
                marginEnd = dpToPx(6)
            }
        }

        // "✨ Polish (Mode)" Button -> Refines via Cloudflare Worker and immediately inserts!
        btnVoiceRefine = TextView(this).apply {
            text = "✨ Polish & Insert"
            textSize = 11.5f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            background = createIosKeyDrawable(
                normalColor = Color.parseColor("#343438"),
                pressedColor = Color.parseColor("#4A4A4E"),
                shadowColor = Color.parseColor("#1C1C1E"),
                cornerRadiusDp = 7f
            )
            setOnClickListener {
                vibrateTap()
                stopInKeyboardVoice()
                refineAndCommitSpokenText()
            }
            layoutParams = LinearLayout.LayoutParams(0, dpToPx(34), 1.2f)
        }

        actionRow.addView(btnCorrectAndInsert)
        actionRow.addView(btnVoiceRefine)
        voiceLiveBar.addView(actionRow)

        rootLayout.addView(voiceLiveBar)
    }

    private fun showVoiceLiveBar() {
        voiceLiveBar.visibility = View.VISIBLE
        suggestionArea.visibility = View.GONE
        voiceStatusDot.setTextColor(Color.parseColor("#FF453A"))
        voiceStatusText.text = "Listening... speak now"
        voiceTranscriptText.text = "Listening..."
        btnVoiceRefine.text = "✨ Polish (${activeMode.replaceFirstChar { it.uppercase() }})"
    }

    private fun hideVoiceLiveBar() {
        voiceLiveBar.visibility = View.GONE
    }

    private fun commitSpokenTextToInput() {
        val ic = currentInputConnection ?: return
        val textToCommit = currentSpokenText.trim()
        if (textToCommit.isNotEmpty()) {
            ic.commitText(textToCommit + " ", 1)
            Toast.makeText(this, "Inserted", Toast.LENGTH_SHORT).show()
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

        voiceStatusText.text = "SAYN AI polishing (${activeMode})..."
        Toast.makeText(this, "Polishing with AI...", Toast.LENGTH_SHORT).show()

        CoroutineScope(Dispatchers.IO).launch {
            try {
                val refined = requestAiRefinement(textToRefine, activeMode)
                withContext(Dispatchers.Main) {
                    val ic = currentInputConnection
                    if (ic != null && refined.isNotBlank()) {
                        ic.commitText(refined.trim() + " ", 1)
                        Toast.makeText(applicationContext, "Refined & inserted!", Toast.LENGTH_SHORT).show()
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
                setStroke(dpToPx(1.2f), Color.parseColor("#007AFF"))
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
            setTextColor(Color.parseColor("#007AFF"))
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
            setTextColor(Color.WHITE)
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            background = createIosKeyDrawable(
                normalColor = Color.parseColor("#007AFF"),
                pressedColor = Color.parseColor("#0056B3"),
                shadowColor = Color.parseColor("#004085"),
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
    // 3. SAYN AI Toolbar & Writing-Style Selector
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
            setPadding(dpToPx(5), dpToPx(2), dpToPx(5), dpToPx(2))
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                dpToPx(38)
            ).apply { bottomMargin = dpToPx(4) }
        }

        // Voice Dictation Quick Button inside Toolbar
        val btnVoice = TextView(this).apply {
            text = "🎤 Voice"
            textSize = 11f
            setTextColor(Color.parseColor("#5DE4FF")) // Audio cyan
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            setPadding(dpToPx(8), 0, dpToPx(8), 0)
            setOnClickListener {
                vibrateTap()
                toggleInKeyboardVoice()
            }
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                dpToPx(30)
            )
        }
        aiToolbar.addView(btnVoice)

        // Writing-Style Horizontal Pills ScrollView
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
                textSize = 11f
                gravity = Gravity.CENTER
                val isSelected = modeId == activeMode
                setTextColor(if (isSelected) Color.WHITE else Color.parseColor("#8E8E93"))
                val pillBg = GradientDrawable().apply {
                    cornerRadius = dpToPx(13).toFloat()
                    setColor(if (isSelected) Color.parseColor("#007AFF") else Color.parseColor("#2C2C2E"))
                }
                background = pillBg
                setPadding(dpToPx(11), 0, dpToPx(11), 0)
                setOnClickListener {
                    vibrateTap()
                    activeMode = modeId
                    getSharedPreferences("com.sayn.app.PREFS", Context.MODE_PRIVATE)
                        .edit().putString("default_mode", modeId).apply()
                    updateToolbarPills(pillsRow)
                    triggerRefinement(modeId)
                }
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.WRAP_CONTENT,
                    dpToPx(27)
                ).apply {
                    marginStart = dpToPx(2)
                    marginEnd = dpToPx(2)
                }
            }
            pillsRow.addView(pill)
        }

        pillsScroll.addView(pillsRow)
        aiToolbar.addView(pillsScroll)

        rootLayout.addView(aiToolbar)
    }

    private fun updateToolbarPills(pillsRow: LinearLayout) {
        for (i in 0 until pillsRow.childCount) {
            val pill = pillsRow.getChildAt(i) as? TextView ?: continue
            val modeId = modes[i].first
            val isSelected = modeId == activeMode
            pill.setTextColor(if (isSelected) Color.WHITE else Color.parseColor("#8E8E93"))
            val pillBg = GradientDrawable().apply {
                cornerRadius = dpToPx(13).toFloat()
                setColor(if (isSelected) Color.parseColor("#007AFF") else Color.parseColor("#2C2C2E"))
            }
            pill.background = pillBg
        }
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

    private fun requestAiRefinement(text: String, mode: String): String {
        val url = URL("https://sayn-api-worker.allanmaazimdad.workers.dev/api/v1/ai/refine")
        val conn = (url.openConnection() as HttpURLConnection).apply {
            requestMethod = "POST"
            setRequestProperty("Content-Type", "application/json")
            doOutput = true
            connectTimeout = 8000
            readTimeout = 8000
        }

        val payload = JSONObject().apply {
            put("text", text)
            put("mode", mode)
        }

        conn.outputStream.use { os ->
            os.write(payload.toString().toByteArray())
        }

        return if (conn.responseCode == 200) {
            val respStr = conn.inputStream.bufferedReader().use { it.readText() }
            val json = JSONObject(respStr)
            json.optString("refinedText", text)
        } else {
            text
        }
    }

    // ─────────────────────────────────────────────────────────────────────────────
    // 5. In-Keyboard Speech Recognizer (Wispr Flow)
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
                voiceStatusText.text = "Listening... speak now"
            }

            override fun onBeginningOfSpeech() {
                voiceStatusText.text = "Hearing speech..."
                voiceStatusDot.setTextColor(Color.parseColor("#34C759")) // Green while actively detecting voice
            }

            override fun onRmsChanged(rmsdB: Float) {}

            override fun onBufferReceived(buffer: ByteArray?) {}

            override fun onEndOfSpeech() {
                voiceStatusText.text = "Processing speech..."
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
                        voiceStatusText.text = "Voice engine initializing. Tap mic to retry."
                        Toast.makeText(applicationContext, "Speech engine reconnecting. Tap mic again to speak.", Toast.LENGTH_SHORT).show()
                    }
                    SpeechRecognizer.ERROR_NO_MATCH, SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> {
                        if (currentSpokenText.isEmpty()) {
                            voiceStatusText.text = "No speech detected. Tap mic to retry."
                        }
                    }
                    SpeechRecognizer.ERROR_NETWORK, SpeechRecognizer.ERROR_NETWORK_TIMEOUT -> {
                        voiceStatusText.text = "Network timeout. Check internet connection."
                    }
                    SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> {
                        voiceStatusText.text = "Microphone busy. Tap mic to retry."
                    }
                    else -> {
                        voiceStatusText.text = "Mic error ($error). Tap mic to retry."
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
                voiceStatusText.text = "✓ Speech captured. Tap Correct to insert."
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
        }
    }

    private fun renderQwertyLayout() {
        // Row 1: Q W E R T Y U I O P (10 keys)
        val row1 = listOf("Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P")
        keysContainer.addView(createRowView(row1, hasSpacer = false))

        // Row 2: A S D F G H J K L (9 keys, indented with 0.5f spacer on left/right for iconic iOS stagger!)
        val row2 = listOf("A", "S", "D", "F", "G", "H", "J", "K", "L")
        keysContainer.addView(createRowView(row2, hasSpacer = true))

        // Row 3: SHIFT, Z X C V B N M, DEL
        val row3 = listOf("SHIFT", "Z", "X", "C", "V", "B", "N", "M", "DEL")
        keysContainer.addView(createRowView(row3, hasSpacer = false))

        // Row 4: 123, GLOBE, MIC, SPACE, ENTER
        val row4 = listOf("123", "GLOBE", "MIC", "SPACE", "ENTER")
        keysContainer.addView(createRowView(row4, hasSpacer = false))
    }

    private fun renderSymbols123Layout() {
        val row1 = listOf("1", "2", "3", "4", "5", "6", "7", "8", "9", "0")
        keysContainer.addView(createRowView(row1, hasSpacer = false))

        val row2 = listOf("-", "/", ":", ";", "(", ")", "$", "&", "@", "\"")
        keysContainer.addView(createRowView(row2, hasSpacer = false))

        val row3 = listOf("#+=", ".", ",", "?", "!", "'", "DEL")
        keysContainer.addView(createRowView(row3, hasSpacer = false))

        val row4 = listOf("ABC", "GLOBE", "MIC", "SPACE", "ENTER")
        keysContainer.addView(createRowView(row4, hasSpacer = false))
    }

    private fun renderSymbolsAltLayout() {
        val row1 = listOf("[", "]", "{", "}", "#", "%", "^", "*", "+", "=")
        keysContainer.addView(createRowView(row1, hasSpacer = false))

        val row2 = listOf("_", "\\", "|", "~", "<", ">", "€", "£", "¥", "•")
        keysContainer.addView(createRowView(row2, hasSpacer = false))

        val row3 = listOf("123", ".", ",", "?", "!", "'", "DEL")
        keysContainer.addView(createRowView(row3, hasSpacer = false))

        val row4 = listOf("ABC", "GLOBE", "MIC", "SPACE", "ENTER")
        keysContainer.addView(createRowView(row4, hasSpacer = false))
    }

    private fun createRowView(keys: List<String>, hasSpacer: Boolean): LinearLayout {
        val rowLayout = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                dpToPx(46)
            ).apply { bottomMargin = dpToPx(6) }
        }

        if (hasSpacer) {
            val leftSpacer = View(this).apply {
                layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.MATCH_PARENT, 0.5f)
            }
            rowLayout.addView(leftSpacer)
        }

        for (key in keys) {
            val weight = when (key) {
                "SPACE" -> 4.2f
                "ENTER" -> 1.8f
                "SHIFT", "DEL" -> 1.35f
                "123", "ABC", "#+=" -> 1.35f
                "GLOBE", "MIC" -> 1.0f
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
        val isSpecial = key in listOf("ENTER", "123", "ABC", "#+=", "DEL", "SHIFT", "GLOBE", "MIC")

        val keyView = TextView(this).apply {
            text = displayText
            gravity = Gravity.CENTER
            includeFontPadding = false
            setPadding(0, 0, 0, 0)
            minWidth = 0
            minHeight = 0
            isClickable = true
            isFocusable = false

            // Crisp typography matching iOS
            if (key.length == 1 && symbolLayoutMode == 0) {
                textSize = 22.5f
                typeface = Typeface.DEFAULT
                setTextColor(Color.WHITE)
            } else if (key == "ENTER") {
                textSize = 14f
                typeface = Typeface.DEFAULT_BOLD
                setTextColor(Color.WHITE)
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
            } else {
                textSize = 16f
                typeface = Typeface.DEFAULT
                setTextColor(Color.WHITE)
            }

            // Authentic iOS Keycap Chiclet Backgrounds
            val bg = when {
                key == "ENTER" -> {
                    createIosKeyDrawable(
                        normalColor = Color.parseColor("#007AFF"), // Apple Blue
                        pressedColor = Color.parseColor("#0056B3"),
                        shadowColor = Color.parseColor("#004085")
                    )
                }
                key == "SHIFT" && (isShifted || isCapsLock) -> {
                    // In iOS, active shift turns white with black icon
                    createIosKeyDrawable(
                        normalColor = Color.WHITE,
                        pressedColor = Color.parseColor("#D1D1D6"),
                        shadowColor = Color.parseColor("#8E8E93")
                    )
                }
                isSpecial -> {
                    // iOS Dark Mode Function Keys
                    createIosKeyDrawable(
                        normalColor = Color.parseColor("#2C2C2E"),
                        pressedColor = Color.parseColor("#424246"),
                        shadowColor = Color.parseColor("#18181A")
                    )
                }
                else -> {
                    // iOS Dark Mode Letter Keys (Raised Chiclets)
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
                    vibrateTap()
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
            "GLOBE" -> "🌐"
            "MIC" -> "🎤"
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

    private fun handleKeyAction(key: String) {
        val ic = currentInputConnection ?: return
        when (key) {
            "DEL" -> ic.deleteSurroundingText(1, 0)
            "SPACE" -> ic.commitText(" ", 1)
            "ENTER" -> handleEnterAction()
            "MIC" -> toggleInKeyboardVoice()
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
                    vibrateTap()
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
        try {
            rootLayout.performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP)
        } catch (e: Exception) {}
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
        speechRecognizer?.destroy()
        speechRecognizer = null
        deleteRunnable?.let { deleteHandler.removeCallbacks(it) }
    }

    private fun dpToPx(dp: Float): Int = (dp * resources.displayMetrics.density).toInt()
    private fun dpToPx(dp: Int): Int = (dp * resources.displayMetrics.density).toInt()
}
