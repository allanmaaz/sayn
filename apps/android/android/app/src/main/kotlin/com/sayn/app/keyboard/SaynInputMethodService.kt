package com.sayn.app.keyboard

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.inputmethodservice.InputMethodService
import android.os.Build
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.view.Gravity
import android.view.View
import android.view.inputmethod.EditorInfo
import android.view.inputmethod.InputMethodManager
import android.widget.*
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
    private lateinit var suggestionArea: LinearLayout
    private lateinit var keysContainer: LinearLayout

    // Suggestion Area Views
    private lateinit var suggestionBadge: TextView
    private lateinit var suggestionText: TextView
    private lateinit var btnInsert: Button
    private lateinit var btnReplace: Button
    private lateinit var btnCopy: Button
    private lateinit var btnRegenerate: Button
    private lateinit var btnDismiss: Button
    private lateinit var btnUndo: Button

    // State Variables
    private var isSensitiveField = false
    private var isSymbolLayout = false
    private var isShifted = false
    private var isCapsLock = false
    private var isRefining = false
    private var activeMode = "standard"
    private var lastSuggestion = ""
    private var lastOriginalText = ""
    private var lastReplacedLength = 0
    private var canUndo = false

    // Speech Recognizer for In-Keyboard Dictation
    private var speechRecognizer: SpeechRecognizer? = null
    private var isListening = false

    // Writing Modes (QuillBot & Wispr Flow style)
    private val modes = listOf(
        "standard" to "Standard",
        "fluent" to "Fluent",
        "natural" to "Natural",
        "professional" to "Professional",
        "casual" to "Casual",
        "shorten" to "Shorten",
        "expand" to "Expand",
        "formal" to "Formal",
        "custom" to "Custom"
    )

    override fun onCreate() {
        super.onCreate()
        val prefs = getSharedPreferences("com.sayn.app.PREFS", Context.MODE_PRIVATE)
        activeMode = prefs.getString("default_mode", "standard") ?: "standard"
    }

    override fun onCreateInputView(): View {
        rootLayout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.parseColor("#151518"))
            setPadding(dpToPx(4), dpToPx(4), dpToPx(4), dpToPx(6))
        }

        buildSuggestionArea()
        buildAiToolbar()
        buildKeysLayout()

        return rootLayout
    }

    override fun onStartInputView(info: EditorInfo?, restarting: Boolean) {
        super.onStartInputView(info, restarting)
        isSensitiveField = SensitiveFieldGuard.isSensitiveField(info)

        if (isSensitiveField) {
            aiToolbar.visibility = View.GONE
            suggestionArea.visibility = View.GONE
        } else {
            aiToolbar.visibility = View.VISIBLE
        }

        // Reset layouts on input start
        isSymbolLayout = false
        isShifted = false
        isCapsLock = false
        canUndo = false
        btnUndo.visibility = View.GONE
        renderKeys()
    }

    // ─────────────────────────────────────────────────────────────────────────────
    // 1. AI Suggestion Area (Section 4.1 D)
    // ─────────────────────────────────────────────────────────────────────────────

    private fun buildSuggestionArea() {
        suggestionArea = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            visibility = View.GONE
            val bg = GradientDrawable().apply {
                cornerRadius = dpToPx(10).toFloat()
                setColor(Color.parseColor("#1C1C20"))
                setStroke(dpToPx(1), Color.parseColor("#0A84FF"))
            }
            background = bg
            setPadding(dpToPx(10), dpToPx(8), dpToPx(10), dpToPx(8))
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply { bottomMargin = dpToPx(4) }
        }

        // Top info row: badge + dismiss
        val topRow = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }

        suggestionBadge = TextView(this).apply {
            text = "STANDARD REFINEMENT"
            textSize = 9.5f
            setTextColor(Color.parseColor("#0A84FF"))
            typeface = Typeface.DEFAULT_BOLD
            layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
        }

        btnDismiss = Button(this).apply {
            text = "✕"
            textSize = 11f
            setTextColor(Color.parseColor("#71717A"))
            setBackgroundColor(Color.TRANSPARENT)
            setPadding(dpToPx(4), 0, dpToPx(4), 0)
            setOnClickListener { hideSuggestionArea() }
            layoutParams = LinearLayout.LayoutParams(dpToPx(28), dpToPx(24))
        }

        topRow.addView(suggestionBadge)
        topRow.addView(btnDismiss)
        suggestionArea.addView(topRow)

        // Suggestion proposal text
        suggestionText = TextView(this).apply {
            text = ""
            textSize = 13f
            setTextColor(Color.parseColor("#F5F5F7"))
            setPadding(0, dpToPx(4), 0, dpToPx(6))
            maxLines = 4
        }
        suggestionArea.addView(suggestionText)

        // Action Buttons Row: Insert, Replace, Copy, Regenerate, Undo
        val actionsRow = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }

        btnReplace = createActionButton("Replace", Color.parseColor("#0A84FF"), Color.WHITE) {
            handleReplace()
        }

        btnInsert = createActionButton("Insert", Color.parseColor("#242428"), Color.parseColor("#F5F5F7")) {
            handleInsert()
        }

        btnCopy = createActionButton("Copy", Color.TRANSPARENT, Color.parseColor("#A1A1AA")) {
            handleCopy()
        }

        btnRegenerate = createActionButton("Regen", Color.TRANSPARENT, Color.parseColor("#A1A1AA")) {
            triggerRefinement(activeMode)
        }

        btnUndo = createActionButton("Undo", Color.parseColor("#FF453A"), Color.WHITE) {
            handleUndo()
        }.apply { visibility = View.GONE }

        actionsRow.addView(btnReplace)
        actionsRow.addView(btnInsert)
        actionsRow.addView(btnCopy)
        actionsRow.addView(btnRegenerate)
        actionsRow.addView(btnUndo)

        suggestionArea.addView(actionsRow)
        rootLayout.addView(suggestionArea)
    }

    private fun createActionButton(label: String, bgColor: Int, textColor: Int, onClick: () -> Unit): Button {
        return Button(this).apply {
            text = label
            textSize = 10f
            setTextColor(textColor)
            val bg = GradientDrawable().apply {
                cornerRadius = dpToPx(6).toFloat()
                setColor(bgColor)
                if (bgColor == Color.TRANSPARENT) {
                    setStroke(dpToPx(1), Color.parseColor("#303036"))
                }
            }
            background = bg
            setPadding(dpToPx(8), 0, dpToPx(8), 0)
            setOnClickListener { onClick() }
            layoutParams = LinearLayout.LayoutParams(0, dpToPx(30), 1f).apply {
                marginEnd = dpToPx(4)
            }
        }
    }

    private fun showSuggestion(refined: String, mode: String) {
        lastSuggestion = refined
        suggestionBadge.text = "${mode.uppercase()} SUGGESTION"
        suggestionText.text = refined
        suggestionArea.visibility = View.VISIBLE
    }

    private fun hideSuggestionArea() {
        suggestionArea.visibility = View.GONE
    }

    private fun handleReplace() {
        val ic = currentInputConnection ?: return
        if (lastSuggestion.isEmpty()) return

        // Save original draft for Undo
        val selected = ic.getSelectedText(0)?.toString()
        if (!selected.isNullOrBlank()) {
            lastOriginalText = selected
            ic.commitText(lastSuggestion, 1)
            lastReplacedLength = lastSuggestion.length
        } else {
            val textBefore = ic.getTextBeforeCursor(lastOriginalText.length, 0)?.toString() ?: ""
            if (textBefore.isNotEmpty()) {
                ic.deleteSurroundingText(textBefore.length, 0)
            }
            ic.commitText(lastSuggestion, 1)
            lastReplacedLength = lastSuggestion.length
        }

        canUndo = true
        btnUndo.visibility = View.VISIBLE
        Toast.makeText(this, "Replaced draft", Toast.LENGTH_SHORT).show()
    }

    private fun handleInsert() {
        val ic = currentInputConnection ?: return
        if (lastSuggestion.isEmpty()) return

        ic.commitText(lastSuggestion, 1)
        lastReplacedLength = lastSuggestion.length
        canUndo = true
        btnUndo.visibility = View.VISIBLE
        Toast.makeText(this, "Inserted at cursor", Toast.LENGTH_SHORT).show()
    }

    private fun handleCopy() {
        if (lastSuggestion.isEmpty()) return
        val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        clipboard.setPrimaryClip(ClipData.newPlainText("SAYN Refinement", lastSuggestion))
        Toast.makeText(this, "Copied suggestion", Toast.LENGTH_SHORT).show()
    }

    private fun handleUndo() {
        val ic = currentInputConnection ?: return
        if (!canUndo || lastOriginalText.isEmpty()) return

        // Delete replaced text and restore original
        ic.deleteSurroundingText(lastReplacedLength, 0)
        ic.commitText(lastOriginalText, 1)

        canUndo = false
        btnUndo.visibility = View.GONE
        Toast.makeText(this, "Restored original draft", Toast.LENGTH_SHORT).show()
    }

    // ─────────────────────────────────────────────────────────────────────────────
    // 2. SAYN AI Toolbar & Writing-Style Selector (Section 4.1 B & C)
    // ─────────────────────────────────────────────────────────────────────────────

    private fun buildAiToolbar() {
        aiToolbar = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            val bg = GradientDrawable().apply {
                cornerRadius = dpToPx(8).toFloat()
                setColor(Color.parseColor("#1C1C20"))
                setStroke(dpToPx(1), Color.parseColor("#303036"))
            }
            background = bg
            setPadding(dpToPx(6), dpToPx(3), dpToPx(6), dpToPx(3))
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                dpToPx(38)
            ).apply { bottomMargin = dpToPx(4) }
        }

        // Voice Dictation Button inside Toolbar
        val btnVoice = Button(this).apply {
            text = "Voice"
            textSize = 10f
            setTextColor(Color.parseColor("#5DE4FF"))
            typeface = Typeface.DEFAULT_BOLD
            setBackgroundColor(Color.TRANSPARENT)
            setPadding(dpToPx(6), 0, dpToPx(6), 0)
            setOnClickListener { toggleInKeyboardVoice() }
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
            val pill = Button(this).apply {
                text = label
                textSize = 10.5f
                setTextColor(if (modeId == activeMode) Color.WHITE else Color.parseColor("#A1A1AA"))
                val pillBg = GradientDrawable().apply {
                    cornerRadius = dpToPx(12).toFloat()
                    setColor(if (modeId == activeMode) Color.parseColor("#0A84FF") else Color.parseColor("#151518"))
                    setStroke(dpToPx(1), Color.parseColor("#303036"))
                }
                background = pillBg
                setPadding(dpToPx(10), 0, dpToPx(10), 0)
                setOnClickListener {
                    activeMode = modeId
                    getSharedPreferences("com.sayn.app.PREFS", Context.MODE_PRIVATE)
                        .edit().putString("default_mode", modeId).apply()
                    updateToolbarPills(pillsRow)
                    triggerRefinement(modeId)
                }
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.WRAP_CONTENT,
                    dpToPx(28)
                ).apply { marginEnd = dpToPx(4) }
            }
            pillsRow.addView(pill)
        }

        pillsScroll.addView(pillsRow)
        aiToolbar.addView(pillsScroll)

        rootLayout.addView(aiToolbar)
    }

    private fun updateToolbarPills(pillsRow: LinearLayout) {
        for (i in 0 until pillsRow.childCount) {
            val pill = pillsRow.getChildAt(i) as? Button ?: continue
            val modeId = modes[i].first
            val isSelected = modeId == activeMode
            pill.setTextColor(if (isSelected) Color.WHITE else Color.parseColor("#A1A1AA"))
            val pillBg = GradientDrawable().apply {
                cornerRadius = dpToPx(12).toFloat()
                setColor(if (isSelected) Color.parseColor("#0A84FF") else Color.parseColor("#151518"))
                setStroke(dpToPx(1), Color.parseColor("#303036"))
            }
            pill.background = pillBg
        }
    }

    // ─────────────────────────────────────────────────────────────────────────────
    // 3. AI Refinement Engine Call
    // ─────────────────────────────────────────────────────────────────────────────

    private fun triggerRefinement(mode: String) {
        val ic = currentInputConnection ?: return
        if (isSensitiveField || isRefining) return

        // Capture selected text or draft before cursor
        val selected = ic.getSelectedText(0)?.toString()
        val textToTransform = if (!selected.isNullOrBlank()) {
            selected.trim()
        } else {
            (ic.getTextBeforeCursor(350, 0)?.toString() ?: "").trim()
        }

        if (textToTransform.isBlank()) {
            Toast.makeText(this, "Type or select a message to refine", Toast.LENGTH_SHORT).show()
            return
        }

        lastOriginalText = textToTransform
        isRefining = true
        Toast.makeText(this, "SAYN refining (${mode})...", Toast.LENGTH_SHORT).show()

        CoroutineScope(Dispatchers.IO).launch {
            try {
                val url = URL("http://10.0.2.2:8787/api/v1/ai/refine")
                val conn = (url.openConnection() as HttpURLConnection).apply {
                    requestMethod = "POST"
                    setRequestProperty("Content-Type", "application/json")
                    doOutput = true
                    connectTimeout = 8000
                    readTimeout = 8000
                }

                val payload = JSONObject().apply {
                    put("text", textToTransform)
                    put("mode", mode)
                }

                conn.outputStream.use { os ->
                    os.write(payload.toString().toByteArray())
                }

                if (conn.responseCode == 200) {
                    val respStr = conn.inputStream.bufferedReader().use { it.readText() }
                    val json = JSONObject(respStr)
                    val refined = json.optString("refinedText", textToTransform)

                    withContext(Dispatchers.Main) {
                        showSuggestion(refined, mode)
                    }
                } else {
                    withContext(Dispatchers.Main) {
                        Toast.makeText(applicationContext, "Refinement service busy (${conn.responseCode})", Toast.LENGTH_SHORT).show()
                    }
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

    // ─────────────────────────────────────────────────────────────────────────────
    // 4. Voice Dictation inside Keyboard
    // ─────────────────────────────────────────────────────────────────────────────

    private fun toggleInKeyboardVoice() {
        if (isListening) {
            speechRecognizer?.stopListening()
            isListening = false
            Toast.makeText(this, "Voice dictation stopped", Toast.LENGTH_SHORT).show()
        } else {
            if (speechRecognizer == null) {
                speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this).apply {
                    setRecognitionListener(object : RecognitionListener {
                        override fun onReadyForSpeech(params: Bundle?) {}
                        override fun onBeginningOfSpeech() {}
                        override fun onRmsChanged(rmsdB: Float) {}
                        override fun onBufferReceived(buffer: ByteArray?) {}
                        override fun onEndOfSpeech() { isListening = false }
                        override fun onError(error: Int) {
                            isListening = false
                            Toast.makeText(applicationContext, "Microphone error ($error)", Toast.LENGTH_SHORT).show()
                        }
                        override fun onResults(results: Bundle?) {
                            val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                            if (!matches.isNullOrEmpty()) {
                                currentInputConnection?.commitText(matches[0] + " ", 1)
                            }
                        }
                        override fun onPartialResults(partialResults: Bundle?) {}
                        override fun onEvent(eventType: Int, params: Bundle?) {}
                    })
                }
            }

            val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                putExtra(RecognizerIntent.EXTRA_LANGUAGE, Locale.getDefault())
            }

            try {
                speechRecognizer?.startListening(intent)
                isListening = true
                Toast.makeText(this, "Listening... speak now", Toast.LENGTH_SHORT).show()
            } catch (e: Exception) {
                Toast.makeText(this, "Could not start microphone", Toast.LENGTH_SHORT).show()
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────────
    // 5. QWERTY / Symbols Virtual Keyboards (Section 4.1 A)
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

        val rows: List<List<String>> = if (isSymbolLayout) {
            listOf(
                listOf("1", "2", "3", "4", "5", "6", "7", "8", "9", "0"),
                listOf("@", "#", "$", "%", "&", "-", "+", "(", ")", "/"),
                listOf("=", "*", "\"", "'", ":", ";", "!", "?", "DEL"),
                listOf("ABC", ",", "SPACE", ".", "ENTER")
            )
        } else {
            val row1 = listOf("Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P")
            val row2 = listOf("A", "S", "D", "F", "G", "H", "J", "K", "L")
            val row3 = listOf("SHIFT", "Z", "X", "C", "V", "B", "N", "M", "DEL")
            val row4 = listOf("?123", "GLOBE", "SPACE", ".", "ENTER")
            listOf(row1, row2, row3, row4)
        }

        for (row in rows) {
            val rowLayout = LinearLayout(this).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    dpToPx(42)
                ).apply { bottomMargin = dpToPx(3) }
            }

            for (key in row) {
                val weight = when (key) {
                    "SPACE" -> 4.2f
                    "ENTER" -> 1.8f
                    "?123", "ABC", "DEL", "SHIFT" -> 1.4f
                    "GLOBE" -> 1.0f
                    else -> 1.0f
                }

                val displayText = formatKeyText(key)
                val keyBtn = Button(this).apply {
                    text = displayText
                    textSize = if (key.length > 2) 11f else 14f
                    setTextColor(Color.parseColor("#F5F5F7"))

                    val isSpecial = key in listOf("ENTER", "?123", "ABC", "DEL", "SHIFT", "GLOBE")
                    val bg = GradientDrawable().apply {
                        cornerRadius = dpToPx(6).toFloat()
                        if (key == "ENTER") {
                            setColor(Color.parseColor("#0A84FF"))
                        } else if (isSpecial) {
                            setColor(Color.parseColor("#1C1C20"))
                        } else {
                            setColor(Color.parseColor("#242428"))
                        }
                    }
                    background = bg

                    setOnClickListener { handleKeyAction(key) }
                    layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.MATCH_PARENT, weight).apply {
                        marginStart = dpToPx(1.5f)
                        marginEnd = dpToPx(1.5f)
                    }
                }
                rowLayout.addView(keyBtn)
            }
            keysContainer.addView(rowLayout)
        }
    }

    private fun formatKeyText(key: String): String {
        return when (key) {
            "SHIFT" -> if (isCapsLock) "▲" else if (isShifted) "▲" else "⇧"
            "DEL" -> "⌫"
            "GLOBE" -> "🌐"
            "SPACE" -> "space"
            "ENTER" -> "return"
            else -> if (key.length == 1 && !isSymbolLayout) {
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
            "?123" -> {
                isSymbolLayout = true
                renderKeys()
            }
            "ABC" -> {
                isSymbolLayout = false
                renderKeys()
            }
            "SHIFT" -> {
                if (isShifted) {
                    if (!isCapsLock) isCapsLock = true else { isCapsLock = false; isShifted = false }
                } else {
                    isShifted = true
                }
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
                val charToCommit = if (key.length == 1 && !isSymbolLayout) {
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

    override fun onDestroy() {
        super.onDestroy()
        speechRecognizer?.destroy()
        speechRecognizer = null
    }

    private fun dpToPx(dp: Float): Int = (dp * resources.displayMetrics.density).toInt()
    private fun dpToPx(dp: Int): Int = (dp * resources.displayMetrics.density).toInt()
}
