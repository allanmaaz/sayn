package com.sayn.app.overlay

import android.Manifest
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.PackageManager
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.view.Gravity
import android.view.View
import android.widget.*
import androidx.core.content.ContextCompat
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.util.Locale

class FloatingPanelView(
    context: Context,
    private val onClose: () -> Unit
) : LinearLayout(context) {

    private val prefs: SharedPreferences = context.getSharedPreferences("com.sayn.app.PREFS", Context.MODE_PRIVATE)
    private val speechRecognizer: SpeechRecognizer = SpeechRecognizer.createSpeechRecognizer(context)

    // UI Elements
    private val transcriptText: TextView
    private val timerText: TextView
    private val waveformContainer: LinearLayout
    private val recordButton: Button
    private val refineButton: Button
    private val copyButton: Button
    private val shareButton: Button
    private val modesContainer: LinearLayout

    // State
    private var isRecording = false
    private var isRefining = false
    private var secondsElapsed = 0
    private var timerHandler = Handler(Looper.getMainLooper())
    private var timerRunnable: Runnable? = null
    private var activeMode = "standard"

    private val modes = listOf(
        "standard" to "Standard",
        "fluent" to "Fluent",
        "natural" to "Natural",
        "professional" to "Professional",
        "casual" to "Casual",
        "shorten" to "Shorten",
        "expand" to "Expand",
        "formal" to "Formal"
    )

    init {
        orientation = VERTICAL
        setPadding(dpToPx(16), dpToPx(14), dpToPx(16), dpToPx(14))

        activeMode = prefs.getString("default_mode", "standard") ?: "standard"

        val bg = GradientDrawable().apply {
            cornerRadius = dpToPx(14).toFloat()
            setColor(Color.parseColor("#151518"))
            setStroke(dpToPx(1), Color.parseColor("#303036"))
        }
        background = bg
        elevation = dpToPx(12).toFloat()

        // 1. Top Bar: Header, Timer, and Close
        val topBar = LinearLayout(context).apply {
            orientation = HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }

        val title = TextView(context).apply {
            text = "SAYN Floating Assistant"
            setTextColor(Color.parseColor("#F5F5F7"))
            textSize = 12.5f
            typeface = Typeface.DEFAULT_BOLD
            layoutParams = LayoutParams(0, LayoutParams.WRAP_CONTENT, 1f)
        }

        timerText = TextView(context).apply {
            text = ""
            setTextColor(Color.parseColor("#5DE4FF"))
            textSize = 11f
            typeface = Typeface.MONOSPACE
            visibility = View.GONE
            setPadding(0, 0, dpToPx(8), 0)
        }

        val closeBtn = ImageView(context).apply {
            setImageResource(android.R.drawable.ic_menu_close_clear_cancel)
            setColorFilter(Color.parseColor("#71717A"))
            setOnClickListener { onClose() }
        }

        topBar.addView(title)
        topBar.addView(timerText)
        topBar.addView(closeBtn)
        addView(topBar)

        val spacer1 = View(context).apply { layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, dpToPx(10)) }
        addView(spacer1)

        // 2. Waveform Visualization Container (Restrained cyan bars)
        waveformContainer = LinearLayout(context).apply {
            orientation = HORIZONTAL
            gravity = Gravity.CENTER
            visibility = View.GONE
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, dpToPx(24)).apply {
                bottomMargin = dpToPx(8)
            }
        }
        buildWaveformBars()
        addView(waveformContainer)

        // 3. Transcript Display Area
        transcriptText = TextView(context).apply {
            text = "Tap Dictate to speak, or select a style to refine..."
            setTextColor(Color.parseColor("#A1A1AA"))
            textSize = 12.5f
            setPadding(dpToPx(10), dpToPx(10), dpToPx(10), dpToPx(10))
            val textBg = GradientDrawable().apply {
                cornerRadius = dpToPx(8).toFloat()
                setColor(Color.parseColor("#1C1C20"))
                setStroke(dpToPx(1), Color.parseColor("#303036"))
            }
            background = textBg
            minHeight = dpToPx(75)
        }
        addView(transcriptText)

        val spacer2 = View(context).apply { layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, dpToPx(10)) }
        addView(spacer2)

        // 4. Writing-Style Selector Pills (QuillBot style)
        val modesScroll = HorizontalScrollView(context).apply {
            isHorizontalScrollBarEnabled = false
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT).apply {
                bottomMargin = dpToPx(10)
            }
        }

        modesContainer = LinearLayout(context).apply {
            orientation = HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }

        for ((modeId, label) in modes) {
            val pill = Button(context).apply {
                text = label
                textSize = 10f
                setTextColor(if (modeId == activeMode) Color.WHITE else Color.parseColor("#A1A1AA"))
                val pillBg = GradientDrawable().apply {
                    cornerRadius = dpToPx(12).toFloat()
                    setColor(if (modeId == activeMode) Color.parseColor("#0A84FF") else Color.parseColor("#1C1C20"))
                    setStroke(dpToPx(1), Color.parseColor("#303036"))
                }
                background = pillBg
                setPadding(dpToPx(8), 0, dpToPx(8), 0)
                setOnClickListener {
                    activeMode = modeId
                    prefs.edit().putString("default_mode", modeId).apply()
                    updateModePills()
                    if (transcriptText.text.isNotEmpty() && !transcriptText.text.startsWith("Tap Dictate")) {
                        refineCurrentText()
                    }
                }
                layoutParams = LayoutParams(LayoutParams.WRAP_CONTENT, dpToPx(28)).apply {
                    marginEnd = dpToPx(4)
                }
            }
            modesContainer.addView(pill)
        }
        modesScroll.addView(modesContainer)
        addView(modesScroll)

        // 5. Dictate & Refine Action Buttons
        val actionsRow = LinearLayout(context).apply {
            orientation = HORIZONTAL
            gravity = Gravity.CENTER
        }

        recordButton = Button(context).apply {
            text = "Dictate"
            textSize = 11.5f
            setTextColor(Color.WHITE)
            val btnBg = GradientDrawable().apply {
                cornerRadius = dpToPx(8).toFloat()
                setColor(Color.parseColor("#1C1C20"))
                setStroke(dpToPx(1), Color.parseColor("#303036"))
            }
            background = btnBg
            setOnClickListener { toggleDictation() }
            layoutParams = LayoutParams(0, dpToPx(38), 1f).apply { marginEnd = dpToPx(6) }
        }

        refineButton = Button(context).apply {
            text = "Refine"
            textSize = 11.5f
            setTextColor(Color.WHITE)
            val btnBg = GradientDrawable().apply {
                cornerRadius = dpToPx(8).toFloat()
                setColor(Color.parseColor("#0A84FF"))
            }
            background = btnBg
            setOnClickListener { refineCurrentText() }
            layoutParams = LayoutParams(0, dpToPx(38), 1f)
        }

        actionsRow.addView(recordButton)
        actionsRow.addView(refineButton)
        addView(actionsRow)

        val spacer3 = View(context).apply { layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, dpToPx(8)) }
        addView(spacer3)

        // 6. Copy & Insert Actions Row
        val bottomRow = LinearLayout(context).apply {
            orientation = HORIZONTAL
            gravity = Gravity.CENTER
        }

        copyButton = Button(context).apply {
            text = "Copy"
            textSize = 10.5f
            setTextColor(Color.parseColor("#A1A1AA"))
            setBackgroundColor(Color.TRANSPARENT)
            setOnClickListener { copyToClipboard() }
            layoutParams = LayoutParams(0, LayoutParams.WRAP_CONTENT, 1f)
        }

        shareButton = Button(context).apply {
            text = "Insert / Share"
            textSize = 10.5f
            setTextColor(Color.parseColor("#0A84FF"))
            setBackgroundColor(Color.TRANSPARENT)
            setOnClickListener { shareToOpenApp() }
            layoutParams = LayoutParams(0, LayoutParams.WRAP_CONTENT, 1f)
        }

        bottomRow.addView(copyButton)
        bottomRow.addView(shareButton)
        addView(bottomRow)

        setupSpeechRecognizer()
    }

    private fun buildWaveformBars() {
        waveformContainer.removeAllViews()
        for (i in 0..7) {
            val bar = View(context).apply {
                val barBg = GradientDrawable().apply {
                    cornerRadius = dpToPx(2).toFloat()
                    setColor(Color.parseColor("#5DE4FF"))
                }
                background = barBg
                layoutParams = LayoutParams(dpToPx(3), dpToPx(12 + (i % 3) * 4)).apply {
                    marginStart = dpToPx(2)
                    marginEnd = dpToPx(2)
                }
            }
            waveformContainer.addView(bar)
        }
    }

    private fun updateModePills() {
        for (i in 0 until modesContainer.childCount) {
            val pill = modesContainer.getChildAt(i) as? Button ?: continue
            val modeId = modes[i].first
            val isSelected = modeId == activeMode
            pill.setTextColor(if (isSelected) Color.WHITE else Color.parseColor("#A1A1AA"))
            val pillBg = GradientDrawable().apply {
                cornerRadius = dpToPx(12).toFloat()
                setColor(if (isSelected) Color.parseColor("#0A84FF") else Color.parseColor("#1C1C20"))
                setStroke(dpToPx(1), Color.parseColor("#303036"))
            }
            pill.background = pillBg
        }
    }

    private fun setupSpeechRecognizer() {
        speechRecognizer.setRecognitionListener(object : RecognitionListener {
            override fun onReadyForSpeech(params: Bundle?) {}
            override fun onBeginningOfSpeech() {}
            override fun onRmsChanged(rmsdB: Float) {
                // Modulate waveform heights slightly with audio energy
                val boost = Math.max(8, (rmsdB * 2.5f).toInt())
                for (i in 0 until waveformContainer.childCount) {
                    val bar = waveformContainer.getChildAt(i)
                    bar.layoutParams.height = dpToPx(boost + (i % 3) * 3)
                    bar.requestLayout()
                }
            }
            override fun onBufferReceived(buffer: ByteArray?) {}
            override fun onEndOfSpeech() { stopDictation() }
            override fun onError(error: Int) {
                stopDictation()
                if (error == 9) { // INSUFFICIENT_PERMISSIONS
                    transcriptText.text = "Microphone permission required. Tap Dictate to allow."
                    val intent = Intent(context, com.sayn.app.MainActivity::class.java).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        putExtra("request_mic_permission", true)
                    }
                    context.startActivity(intent)
                } else {
                    transcriptText.text = "Microphone paused ($error). Tap Dictate to retry."
                }
            }
            override fun onResults(results: Bundle?) {
                val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                if (!matches.isNullOrEmpty()) {
                    transcriptText.text = matches[0]
                    transcriptText.setTextColor(Color.parseColor("#F5F5F7"))
                }
            }
            override fun onPartialResults(partialResults: Bundle?) {
                val matches = partialResults?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                if (!matches.isNullOrEmpty()) {
                    transcriptText.text = matches[0]
                }
            }
            override fun onEvent(eventType: Int, params: Bundle?) {}
        })
    }

    private fun toggleDictation() {
        if (isRecording) {
            stopDictation()
        } else {
            startDictation()
        }
    }

    private fun startDictation() {
        if (ContextCompat.checkSelfPermission(context, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            Toast.makeText(context, "Microphone permission required for SAYN", Toast.LENGTH_LONG).show()
            val intent = Intent(context, com.sayn.app.MainActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                putExtra("request_mic_permission", true)
            }
            context.startActivity(intent)
            return
        }

        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, Locale.getDefault())
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
        }

        try {
            speechRecognizer.startListening(intent)
            isRecording = true
            recordButton.text = "Stop"
            recordButton.setTextColor(Color.parseColor("#FF453A"))
            waveformContainer.visibility = View.VISIBLE
            timerText.visibility = View.VISIBLE
            secondsElapsed = 0
            startTimer()
        } catch (e: Exception) {
            Toast.makeText(context, "Could not access microphone", Toast.LENGTH_SHORT).show()
        }
    }

    private fun stopDictation() {
        speechRecognizer.stopListening()
        isRecording = false
        recordButton.text = "Dictate"
        recordButton.setTextColor(Color.WHITE)
        waveformContainer.visibility = View.GONE
        timerText.visibility = View.GONE
        stopTimer()
    }

    private fun startTimer() {
        timerRunnable = object : Runnable {
            override fun run() {
                if (isRecording) {
                    secondsElapsed++
                    val m = secondsElapsed / 60
                    val s = secondsElapsed % 60
                    timerText.text = String.format("%02d:%02d", m, s)
                    timerHandler.postDelayed(this, 1000)
                }
            }
        }
        timerHandler.post(timerRunnable!!)
    }

    private fun stopTimer() {
        timerRunnable?.let { timerHandler.removeCallbacks(it) }
    }

    private fun refineCurrentText() {
        val text = transcriptText.text.toString().trim()
        if (text.isEmpty() || text.startsWith("Tap Dictate") || isRefining) return

        isRefining = true
        refineButton.text = "Refining..."
        refineButton.isEnabled = false

        CoroutineScope(Dispatchers.IO).launch {
            try {
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
                    put("mode", activeMode)
                }

                conn.outputStream.use { os ->
                    os.write(payload.toString().toByteArray())
                }

                if (conn.responseCode == 200) {
                    val respStr = conn.inputStream.bufferedReader().use { it.readText() }
                    val json = JSONObject(respStr)
                    val refined = json.optString("refinedText", text)

                    withContext(Dispatchers.Main) {
                        transcriptText.text = refined
                        transcriptText.setTextColor(Color.parseColor("#F5F5F7"))
                    }
                } else {
                    withContext(Dispatchers.Main) {
                        Toast.makeText(context, "Refinement service busy (${conn.responseCode})", Toast.LENGTH_SHORT).show()
                    }
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    Toast.makeText(context, "Could not refine: check connection", Toast.LENGTH_SHORT).show()
                }
            } finally {
                withContext(Dispatchers.Main) {
                    isRefining = false
                    refineButton.text = "Refine"
                    refineButton.isEnabled = true
                }
            }
        }
    }

    private fun copyToClipboard() {
        val text = transcriptText.text.toString().trim()
        if (text.isNotEmpty()) {
            val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
            clipboard.setPrimaryClip(ClipData.newPlainText("SAYN Refinement", text))
            Toast.makeText(context, "Copied to clipboard", Toast.LENGTH_SHORT).show()
        }
    }

    private fun shareToOpenApp() {
        val text = transcriptText.text.toString().trim()
        if (text.isNotEmpty()) {
            val intent = Intent(Intent.ACTION_SEND).apply {
                type = "text/plain"
                putExtra(Intent.EXTRA_TEXT, text)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(Intent.createChooser(intent, "Insert via SAYN").apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            })
        }
    }

    private fun dpToPx(dp: Int): Int = (dp * resources.displayMetrics.density).toInt()
}
