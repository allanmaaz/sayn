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
import android.text.TextUtils
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
    private lateinit var candidateStrip: LinearLayout
    private lateinit var candidateLeft: TextView
    private lateinit var candidateCenter: TextView
    private lateinit var candidateRight: TextView
    private lateinit var voiceLiveBar: LinearLayout
    private lateinit var suggestionArea: LinearLayout
    private lateinit var keysContainer: LinearLayout

    // Wispr Voice Live Bar Views (3-piece Wispr pill)
    private lateinit var voiceStatusDot: TextView
    private lateinit var voiceTranscriptText: TextView
    private lateinit var btnCorrectAndInsert: ImageView

    // Suggestion Area Views
    private lateinit var suggestionBadge: TextView
    private lateinit var suggestionText: TextView
    private lateinit var btnReplace: TextView
    private lateinit var btnInsert: TextView
    private lateinit var btnCopy: TextView
    private lateinit var btnDismiss: ImageView

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
    private var lastSpacePressTime = 0L
    private var isRefining = false
    private var activeMode = "mammals"
    private var lastSuggestion = ""
    private var lastOriginalText = ""
    private var isPredictionActive = false

    // Speech Recognizer for In-Keyboard Dictation (Wispr flow)
    private var speechRecognizer: SpeechRecognizer? = null
    private var isListening = false
    private var currentSpokenText = ""

    // Dedicated Handlers for delete repeat and long press
    private val deleteHandler = Handler(Looper.getMainLooper())
    private var deleteRunnable: Runnable? = null
    private val longPressHandler = Handler(Looper.getMainLooper())

    // In-place references for zero-allocation case shifting
    private val letterKeyViews = mutableMapOf<String, TextView>()
    private var shiftKeyContainer: FrameLayout? = null
    private var shiftKeyIcon: ImageView? = null

    // Long-press key hints from user reference screenshot
    private val keyHintMap = mapOf(
        "Q" to "1", "W" to "2", "E" to "3", "R" to "4", "T" to "5",
        "Y" to "6", "U" to "7", "I" to "8", "O" to "9", "P" to "0",
        "A" to "@", "S" to "#", "D" to "$", "F" to "-", "G" to "!",
        "H" to "_", "J" to "*", "K" to "(", "L" to ")",
        "Z" to "+", "X" to "'", "C" to "\"", "V" to ":", "B" to ";",
        "N" to ",", "M" to "?",
        "." to "..."
    )

    // 4 Core AI Writing Styles + Utilities
    private val modes = listOf(
        "flow" to "Fluency",
        "professional" to "Professional",
        "humanize" to "Humanize",
        "mammals" to "Mammals",
        "grammar" to "Grammar",
        "rewrite" to "Rewrite",
        "casual" to "Casual",
        "shorten" to "Shorten"
    )
 
    companion object {
        var instance: SaynInputMethodService? = null
            private set

        // Authentic Obsidian Plum & Warm Ivory Palette (Matching User's Reference Screenshot)
        val COLOR_BG = Color.parseColor("#0C0709") // Pitch obsidian dark canvas
        val COLOR_SURFACE = Color.parseColor("#180B10")
        val COLOR_KEY_NORMAL = Color.parseColor("#261118") // Rich burgundy/wine chiclet face
        val COLOR_KEY_PRESSED = Color.parseColor("#3E1824") // Illuminated burgundy feedback
        val COLOR_KEY_BORDER = Color.parseColor("#441D29") // Luminous subtle wine rim (1dp)
        val COLOR_KEY_BORDER_PRESSED = Color.parseColor("#5A2435")
        val COLOR_KEY_SHADOW = Color.parseColor("#070305")
        val COLOR_KEY_SPECIAL = Color.parseColor("#1C0B12") // Deep obsidian for Shift, Del, 123, Enter
        val COLOR_KEY_SPECIAL_PRESSED = Color.parseColor("#2C101B")
        val COLOR_KEY_SPECIAL_BORDER = Color.parseColor("#381721")
        val COLOR_BORDER = Color.parseColor("#381721")
        val COLOR_MAROON = Color.parseColor("#261118")
        val COLOR_MAROON_PRESSED = Color.parseColor("#3E1824")
        val COLOR_ROSE_MAROON = Color.parseColor("#A83249")
        val COLOR_ROSE_MAROON_PRESSED = Color.parseColor("#872639")
        val COLOR_WARM_CREAM = Color.parseColor("#F5EBE1") // Warm Champagne / Ivory text
        val COLOR_MUTED_CREAM = Color.parseColor("#D4C4B6") // Secondary warm cream
        val COLOR_FAINT_CREAM = Color.parseColor("#A27E89") // Dusty mauve sub-labels
        val COLOR_TEXT_HINT = Color.parseColor("#A27E89") // Top-right character hints (1, 2, 3...)
        val COLOR_DIVIDER = Color.parseColor("#381F27") // Thin vertical dividers in top bar
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

    // Instant Vocabulary for prefix auto-completion
    private val commonWords = listOf(
        "the", "be", "to", "of", "and", "a", "in", "that", "have", "I",
        "it", "for", "not", "on", "with", "he", "as", "you", "do", "at",
        "this", "but", "his", "by", "from", "they", "we", "say", "her", "she",
        "or", "an", "will", "my", "one", "all", "would", "there", "their", "what",
        "so", "up", "out", "if", "about", "who", "get", "which", "go", "me",
        "when", "make", "can", "like", "time", "no", "just", "him", "know", "take",
        "people", "into", "year", "your", "good", "some", "could", "them", "see", "other",
        "than", "then", "now", "look", "only", "come", "its", "over", "think", "also",
        "back", "after", "use", "two", "how", "our", "work", "first", "well", "way",
        "even", "new", "want", "because", "any", "these", "give", "day", "most", "us",
        "great", "hello", "thanks", "thank", "please", "happy", "love", "awesome",
        "amazing", "perfect", "sounds", "meeting", "tomorrow", "today", "tonight",
        "call", "message", "email", "office", "home", "ready", "working",
        "talking", "running", "going", "doing", "getting", "looking", "forward",
        "welcome", "congratulations", "definitely", "absolutely", "probably", "maybe",
        "everything", "something", "anything", "nothing", "everyone", "someone", "anyone",
        "always", "never", "sometimes", "usually", "really", "actually", "already",
        "together", "without", "between", "through", "before", "around", "another",
        "beautiful", "important", "different", "possible", "questions", "updates", "project",
        "schedule", "available", "information", "support", "appreciate", "interesting"
    )

    // High-Probability Next-Word Predictions (Bigram Context Engine)
    private val nextWordMap = mapOf(
        "i" to listOf("am", "will", "have"),
        "i'm" to listOf("going", "not", "so"),
        "i've" to listOf("been", "got", "seen"),
        "i'll" to listOf("be", "call", "let"),
        "you" to listOf("are", "can", "have"),
        "you're" to listOf("welcome", "right", "going"),
        "we" to listOf("are", "can", "will"),
        "we're" to listOf("going", "ready", "working"),
        "they" to listOf("are", "will", "have"),
        "it" to listOf("is", "was", "will"),
        "it's" to listOf("a", "going", "very"),
        "that" to listOf("is", "was", "would"),
        "that's" to listOf("great", "awesome", "true"),
        "what" to listOf("do", "is", "about"),
        "how" to listOf("are", "is", "about"),
        "where" to listOf("are", "is", "do"),
        "when" to listOf("can", "will", "are"),
        "why" to listOf("not", "did", "would"),
        "thank" to listOf("you", "so", "everyone"),
        "thanks" to listOf("for", "again", "so"),
        "let" to listOf("me", "us", "them"),
        "let's" to listOf("go", "do", "meet"),
        "sounds" to listOf("good", "great", "like"),
        "looking" to listOf("forward", "at", "for"),
        "forward" to listOf("to", "with", "today"),
        "please" to listOf("let", "find", "check"),
        "good" to listOf("morning", "luck", "night"),
        "have" to listOf("a", "been", "done"),
        "hope" to listOf("you", "this", "all"),
        "see" to listOf("you", "what", "it"),
        "call" to listOf("me", "you", "back"),
        "can" to listOf("you", "we", "I"),
        "could" to listOf("you", "be", "have"),
        "would" to listOf("be", "love", "like"),
        "no" to listOf("problem", "worries", "way"),
        "happy" to listOf("to", "birthday", "for"),
        "love" to listOf("you", "it", "this"),
        "great" to listOf("to", "job", "news"),
        "take" to listOf("care", "your", "it"),
        "on" to listOf("my", "the", "time"),
        "at" to listOf("the", "work", "home"),
        "in" to listOf("the", "a", "touch"),
        "talk" to listOf("to", "soon", "later"),
        "best" to listOf("regards", "wishes", "way"),
        "nice" to listOf("to", "work", "meeting"),
        "are" to listOf("you", "we", "they"),
        "is" to listOf("it", "that", "there")
    )

    // Contextual Emoji auto-suggestions
    private val emojiSuggestions = mapOf(
        "fire" to "🔥", "lit" to "🔥",
        "love" to "❤️", "heart" to "❤️",
        "happy" to "😊", "smile" to "😊",
        "cool" to "😎",
        "laugh" to "😂", "lol" to "😂", "haha" to "😂",
        "sad" to "🥺", "cry" to "😭",
        "party" to "🥳", "celebrate" to "🎉", "congrats" to "🎉",
        "rocket" to "🚀", "fast" to "⚡",
        "star" to "⭐", "hundred" to "💯", "100" to "💯",
        "ok" to "👌", "good" to "👍", "yes" to "👍",
        "check" to "✅", "done" to "✅",
        "coffee" to "☕", "pizza" to "🍕", "cake" to "🎂",
        "clap" to "👏", "pray" to "🙏", "thanks" to "🙏"
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
            setBackgroundColor(COLOR_BG) // SAYN Royal Near-Black Background
            // Elevated keyboard: 24dp bottom padding elevates keyboard away from the phone's bottom bezel & gesture bar
            setPadding(dpToPx(4), dpToPx(4), dpToPx(4), dpToPx(24))
        }

        buildVoiceLiveBar()
        buildSuggestionArea()
        buildAiToolbar()
        buildCandidateStrip()
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
            if (::candidateStrip.isInitialized) candidateStrip.visibility = View.GONE
        } else {
            aiToolbar.visibility = View.GONE // Normal, clean single-bar keyboard
            if (::candidateStrip.isInitialized) {
                candidateStrip.visibility = View.VISIBLE
                updateCandidates()
            }
        }

        symbolLayoutMode = 0
        isCapsLock = false
        val ic = currentInputConnection
        val reqModes = android.text.TextUtils.CAP_MODE_CHARACTERS or
                       android.text.TextUtils.CAP_MODE_WORDS or
                       android.text.TextUtils.CAP_MODE_SENTENCES
        val capsMode = if (ic != null) ic.getCursorCapsMode(reqModes) else 0
        val before = ic?.getTextBeforeCursor(4, 0)?.toString() ?: ""
        isShifted = !isSensitiveField && (capsMode != 0 || before.isEmpty() || before.endsWith("\n") || 
                     before.endsWith(". ") || before.endsWith("? ") || before.endsWith("! "))

        if (!::keysContainer.isInitialized || keysContainer.childCount == 0 || letterKeyViews.isEmpty()) {
            renderKeys()
        } else {
            updateShiftState()
        }
        checkAutoCapitalization()
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

    override fun onUpdateSelection(
        oldSelStart: Int,
        oldSelEnd: Int,
        newSelStart: Int,
        newSelEnd: Int,
        candidatesStart: Int,
        candidatesEnd: Int
    ) {
        super.onUpdateSelection(oldSelStart, oldSelEnd, newSelStart, newSelEnd, candidatesStart, candidatesEnd)
        updateCandidates()
        checkAutoCapitalization()
    }

    // ─────────────────────────────────────────────────────────────────────────────
    // 0. Real-Time Auto-Suggest & Prediction Candidate Strip
    // ─────────────────────────────────────────────────────────────────────────────

    private fun buildCandidateStrip() {
        candidateStrip = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setBackgroundColor(COLOR_BG)
            setPadding(dpToPx(6), dpToPx(2), dpToPx(6), dpToPx(2))
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                dpToPx(38)
            ).apply { bottomMargin = dpToPx(4) }
        }

        // 1. Far Left: Sparkle / Quick Action Icon
        val sparkleBtn = FrameLayout(this).apply {
            val sIcon = ImageView(this@SaynInputMethodService).apply {
                setImageResource(R.drawable.ic_sayn_sparkles)
                setColorFilter(COLOR_WARM_CREAM, PorterDuff.Mode.SRC_IN)
                layoutParams = FrameLayout.LayoutParams(dpToPx(18), dpToPx(18), Gravity.CENTER)
            }
            addView(sIcon)
            isClickable = true
            isFocusable = false
            setOnClickListener {
                triggerKeyFeedback("ENTER")
                val ic = currentInputConnection
                val before = ic?.getTextBeforeCursor(40, 0)?.toString() ?: ""
                val selected = ic?.getSelectedText(0)?.toString() ?: ""
                if (before.isNotBlank() || selected.isNotBlank()) {
                    openFullAiPanel(activeMode)
                } else {
                    toggleInKeyboardVoice()
                }
            }
            layoutParams = LinearLayout.LayoutParams(dpToPx(34), dpToPx(34))
        }

        val div0 = createDividerView()

        // 2. Candidate Left (Standard word prediction)
        candidateLeft = TextView(this).apply {
            text = "I"
            textSize = 14f
            setTextColor(COLOR_WARM_CREAM)
            gravity = Gravity.CENTER
            isSingleLine = true
            ellipsize = android.text.TextUtils.TruncateAt.END
            isClickable = true
            isFocusable = false
            setOnClickListener {
                val t = text.toString().trim()
                if (t.isNotEmpty()) {
                    triggerKeyFeedback("SPACE")
                    commitCandidate(t)
                }
            }
            layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.MATCH_PARENT, 1f)
        }

        val div1 = createDividerView()

        // 3. Candidate Center (Best word prediction)
        candidateCenter = TextView(this).apply {
            text = "the"
            textSize = 14.5f
            typeface = Typeface.DEFAULT_BOLD
            setTextColor(COLOR_WARM_CREAM)
            gravity = Gravity.CENTER
            isSingleLine = true
            ellipsize = android.text.TextUtils.TruncateAt.END
            background = null
            setPadding(dpToPx(6), 0, dpToPx(6), 0)
            isClickable = true
            isFocusable = false
            setOnClickListener {
                val t = text.toString().trim()
                if (t.isNotEmpty()) {
                    triggerKeyFeedback("ENTER")
                    commitCandidate(t)
                }
            }
            layoutParams = LinearLayout.LayoutParams(0, dpToPx(32), 1.2f)
        }

        val div2 = createDividerView()

        // 4. Candidate Right (Secondary word prediction)
        candidateRight = TextView(this).apply {
            text = "thanks"
            textSize = 14f
            setTextColor(COLOR_WARM_CREAM)
            gravity = Gravity.CENTER
            isSingleLine = true
            ellipsize = android.text.TextUtils.TruncateAt.END
            isClickable = true
            isFocusable = false
            setOnClickListener {
                val t = text.toString().trim()
                if (t.isNotEmpty()) {
                    triggerKeyFeedback("SPACE")
                    commitCandidate(t)
                }
            }
            layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.MATCH_PARENT, 1f)
        }

        val div3 = createDividerView()

        // 5. Far Right: Voice Dictation Mic Button (🎙️)
        val micBtn = FrameLayout(this).apply {
            val mIcon = ImageView(this@SaynInputMethodService).apply {
                setImageResource(R.drawable.ic_sayn_mic)
                setColorFilter(COLOR_WARM_CREAM, PorterDuff.Mode.SRC_IN)
                layoutParams = FrameLayout.LayoutParams(dpToPx(18), dpToPx(18), Gravity.CENTER)
            }
            addView(mIcon)
            isClickable = true
            isFocusable = false
            setOnClickListener {
                triggerKeyFeedback("SPACE")
                toggleInKeyboardVoice()
            }
            layoutParams = LinearLayout.LayoutParams(dpToPx(34), dpToPx(34))
        }

        candidateStrip.addView(sparkleBtn)
        candidateStrip.addView(div0)
        candidateStrip.addView(candidateLeft)
        candidateStrip.addView(div1)
        candidateStrip.addView(candidateCenter)
        candidateStrip.addView(div2)
        candidateStrip.addView(candidateRight)
        candidateStrip.addView(div3)
        candidateStrip.addView(micBtn)

        rootLayout.addView(candidateStrip)
    }

    private fun createDividerView(): View {
        return View(this).apply {
            setBackgroundColor(COLOR_DIVIDER)
            layoutParams = LinearLayout.LayoutParams(dpToPx(1f), dpToPx(16)).apply {
                marginStart = dpToPx(4)
                marginEnd = dpToPx(4)
            }
        }
    }

    private fun commitCandidate(candidate: String) {
        val ic = currentInputConnection ?: return
        val before = ic.getTextBeforeCursor(40, 0)?.toString() ?: ""

        val match = Regex("""([a-zA-Z']+)\z""").find(before)
        ic.beginBatchEdit()
        try {
            if (match != null) {
                ic.deleteSurroundingText(match.value.length, 0)
            }
            ic.commitText("$candidate ", 1)
        } finally {
            ic.endBatchEdit()
        }
        updateCandidates()
        checkAutoCapitalization()
    }

    private fun updateCandidates() {
        if (!::candidateStrip.isInitialized) return
        val ic = currentInputConnection ?: return

        if (isSensitiveField) {
            candidateStrip.visibility = View.GONE
            return
        } else {
            candidateStrip.visibility = View.VISIBLE
        }

        val before = ic.getTextBeforeCursor(40, 0)?.toString() ?: ""

        // Case 1: Empty or start of sentence -> Show standard starter words
        if (before.isEmpty()) {
            isPredictionActive = true
            setCandidateTexts("I", "The", "Thanks")
            return
        }

        if (before.endsWith(". ") || before.endsWith("? ") || before.endsWith("! ") || before.endsWith("\n")) {
            isPredictionActive = true
            setCandidateTexts("I", "The", "Thanks")
            return
        }

        // Case 2: Currently typing a word
        val wordMatch = Regex("""([a-zA-Z']+)\z""").find(before)
        if (wordMatch != null) {
            isPredictionActive = true
            val typed = wordMatch.value
            val lower = typed.lowercase()

            if (autoCorrectMap.containsKey(lower)) {
                val corrected = autoCorrectMap[lower]!!
                val left = typed
                val right = emojiSuggestions[lower] ?: commonWords.firstOrNull { it.startsWith(lower) && it != corrected } ?: ""
                setCandidateTexts(left, corrected, right)
                return
            }

            val matches = commonWords.filter { it.startsWith(lower) && it != lower }
            val emojiMatch = emojiSuggestions[lower]

            val center = if (matches.isNotEmpty()) matches[0] else typed
            val left = if (matches.isNotEmpty()) typed else ""
            val right = emojiMatch ?: if (matches.size > 1) matches[1] else ""

            val isCapitalized = typed.isNotEmpty() && typed[0].isUpperCase()
            val finalCenter = if (isCapitalized && center.isNotEmpty()) center.replaceFirstChar { it.uppercase() } else center
            val finalLeft = if (isCapitalized && left.isNotEmpty()) left.replaceFirstChar { it.uppercase() } else left
            val finalRight = if (isCapitalized && right.isNotEmpty() && right[0].isLetter()) right.replaceFirstChar { it.uppercase() } else right

            setCandidateTexts(finalLeft, finalCenter, finalRight)
            return
        }

        // Case 3: After word and space (Next-word prediction)
        val prevWordMatch = Regex("""([a-zA-Z']+)\s+\z""").find(before)
        if (prevWordMatch != null) {
            val prevWord = prevWordMatch.groupValues[1].lowercase()
            val predictions = nextWordMap[prevWord]
            if (predictions != null && predictions.isNotEmpty()) {
                isPredictionActive = true
                val center = predictions.getOrElse(0) { "" }
                val left = predictions.getOrElse(1) { "" }
                val right = predictions.getOrElse(2) { "" }
                setCandidateTexts(left, center, right)
                return
            }
        }

        isPredictionActive = true
        setCandidateTexts("I", "The", "Thanks")
    }

    private fun setCandidateTexts(left: String, center: String, right: String) {
        candidateLeft.text = left
        candidateLeft.visibility = if (left.isNotEmpty()) View.VISIBLE else View.INVISIBLE
        candidateCenter.text = center
        candidateCenter.visibility = if (center.isNotEmpty()) View.VISIBLE else View.INVISIBLE
        candidateRight.text = right
        candidateRight.visibility = if (right.isNotEmpty()) View.VISIBLE else View.INVISIBLE
    }

    private fun checkAutoCapitalization() {
        if (isCapsLock || symbolLayoutMode != 0) return
        val ic = currentInputConnection ?: return
        if (isSensitiveField) {
            if (isShifted) {
                isShifted = false
                updateShiftState()
            }
            return
        }
        val reqModes = android.text.TextUtils.CAP_MODE_CHARACTERS or
                       android.text.TextUtils.CAP_MODE_WORDS or
                       android.text.TextUtils.CAP_MODE_SENTENCES
        val capsMode = ic.getCursorCapsMode(reqModes)
        val before = ic.getTextBeforeCursor(4, 0)?.toString() ?: ""
        val shouldShift = (capsMode != 0) || before.isEmpty() || before.endsWith("\n") || 
                          before.endsWith(". ") || before.endsWith("? ") || before.endsWith("! ")
        if (shouldShift != isShifted) {
            isShifted = shouldShift
            updateShiftState()
        }
    }

    // ─────────────────────────────────────────────────────────────────────────────
    // 1. Wispr Flow 3-Piece Floating Speech Pill ([ Close ] [ ••• text ••• ] [ Confirm ])
    // ─────────────────────────────────────────────────────────────────────────────

    private fun buildVoiceLiveBar() {
        voiceLiveBar = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            visibility = View.GONE
            setPadding(dpToPx(6), dpToPx(2), dpToPx(6), dpToPx(2))
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                dpToPx(38)
            ).apply { bottomMargin = dpToPx(4) }
        }

        // 1. Left Circle: Frosted Glass Cancel Button [ Close ]
        val cancelCircle = FrameLayout(this).apply {
            val bg = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(COLOR_KEY_NORMAL)
                setStroke(dpToPx(1f), COLOR_BORDER)
            }
            background = bg
            isClickable = true
            isFocusable = false
            layoutParams = LinearLayout.LayoutParams(dpToPx(30), dpToPx(30))
        }

        val cancelIcon = ImageView(this).apply {
            setImageResource(R.drawable.ic_sayn_close)
            setColorFilter(COLOR_WARM_CREAM)
            layoutParams = FrameLayout.LayoutParams(
                dpToPx(13),
                dpToPx(13),
                Gravity.CENTER
            )
        }
        cancelCircle.addView(cancelIcon)
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
                cornerRadius = dpToPx(15f).toFloat()
                setColor(COLOR_SURFACE)
                setStroke(dpToPx(1f), COLOR_BORDER)
            }
            background = bg
            setPadding(dpToPx(10), 0, dpToPx(10), 0)
            layoutParams = LinearLayout.LayoutParams(0, dpToPx(30), 1f).apply {
                marginStart = dpToPx(5)
                marginEnd = dpToPx(5)
            }
        }

        voiceTranscriptText = TextView(this).apply {
            text = "Listening..."
            textSize = 12.5f
            setTextColor(COLOR_WARM_CREAM)
            gravity = Gravity.CENTER_VERTICAL
            isSingleLine = true
            ellipsize = android.text.TextUtils.TruncateAt.END
            layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.MATCH_PARENT, 1f)
        }

        voiceStatusDot = TextView(this).apply {
            text = "• • •"
            textSize = 13f
            setTextColor(COLOR_ROSE_MAROON)
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dpToPx(4), 0, 0, 0)
        }

        centerCapsule.addView(voiceTranscriptText)
        centerCapsule.addView(voiceStatusDot)
        voiceLiveBar.addView(centerCapsule)

        // 3. Right Circle: Deep Maroon Confirm Button [ Confirm ]
        val confirmCircle = FrameLayout(this).apply {
            val bg = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(COLOR_MAROON)
                setStroke(dpToPx(1f), COLOR_BORDER)
            }
            background = bg
            isClickable = true
            isFocusable = false
            layoutParams = LinearLayout.LayoutParams(dpToPx(30), dpToPx(30))
        }

        btnCorrectAndInsert = ImageView(this).apply {
            setImageResource(R.drawable.ic_sayn_check)
            setColorFilter(COLOR_WARM_CREAM)
            layoutParams = FrameLayout.LayoutParams(
                dpToPx(14),
                dpToPx(14),
                Gravity.CENTER
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
        if (::candidateStrip.isInitialized) candidateStrip.visibility = View.GONE
        voiceTranscriptText.text = "Listening..."
        voiceStatusDot.setTextColor(COLOR_ROSE_MAROON)
    }

    private fun hideVoiceLiveBar() {
        voiceLiveBar.visibility = View.GONE
        if (::candidateStrip.isInitialized && !isSensitiveField) candidateStrip.visibility = View.VISIBLE
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
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            visibility = View.GONE
            val bg = GradientDrawable().apply {
                cornerRadius = dpToPx(8).toFloat()
                setColor(COLOR_SURFACE)
                setStroke(dpToPx(1f), COLOR_BORDER)
            }
            background = bg
            setPadding(dpToPx(6), dpToPx(2), dpToPx(6), dpToPx(2))
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                dpToPx(38)
            ).apply { bottomMargin = dpToPx(4) }
        }

        // 1. Left: Mode Chiclet (e.g. "✦ Flow ▾" or "✦ Mammals ▾")
        suggestionBadge = TextView(this).apply {
            text = "✦ FLOW ▾"
            textSize = 11f
            setTextColor(COLOR_WARM_CREAM)
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            val pBg = GradientDrawable().apply {
                cornerRadius = dpToPx(12).toFloat()
                setColor(COLOR_MAROON)
            }
            background = pBg
            setPadding(dpToPx(8), 0, dpToPx(8), 0)
            isClickable = true
            isFocusable = false
            setOnClickListener {
                cycleNextMode()
            }
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                dpToPx(28)
            ).apply { marginEnd = dpToPx(6) }
        }
        suggestionArea.addView(suggestionBadge)

        // 2. Center: One-line preview of the refined text
        suggestionText = TextView(this).apply {
            text = ""
            textSize = 12.5f
            setTextColor(COLOR_WARM_CREAM)
            gravity = Gravity.CENTER_VERTICAL
            isSingleLine = true
            ellipsize = android.text.TextUtils.TruncateAt.END
            setPadding(dpToPx(4), 0, dpToPx(4), 0)
            isClickable = true
            isFocusable = false
            setOnClickListener {
                handleReplace()
            }
            layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.MATCH_PARENT, 1f)
        }
        suggestionArea.addView(suggestionText)

        // 3. Right Action 1: [ ✓ ] Apply Button
        btnReplace = TextView(this).apply {
            text = "✓"
            textSize = 14f
            typeface = Typeface.DEFAULT_BOLD
            setTextColor(COLOR_WARM_CREAM)
            gravity = Gravity.CENTER
            val bg = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(COLOR_ROSE_MAROON)
            }
            background = bg
            isClickable = true
            isFocusable = false
            layoutParams = LinearLayout.LayoutParams(dpToPx(30), dpToPx(30)).apply {
                marginStart = dpToPx(4)
            }
            setOnClickListener { handleReplace() }
        }
        suggestionArea.addView(btnReplace)

        // 4. Right Action 2: [ ✕ ] Cancel Button
        btnDismiss = ImageView(this).apply {
            setImageResource(R.drawable.ic_sayn_close)
            setColorFilter(COLOR_MUTED_CREAM, PorterDuff.Mode.SRC_IN)
            layoutParams = LinearLayout.LayoutParams(dpToPx(28), dpToPx(28)).apply {
                marginStart = dpToPx(4)
            }
            setPadding(dpToPx(6), dpToPx(6), dpToPx(6), dpToPx(6))
            isClickable = true
            isFocusable = false
            setOnClickListener { hideSuggestionArea() }
        }
        suggestionArea.addView(btnDismiss)

        btnInsert = TextView(this)
        btnCopy = TextView(this)

        rootLayout.addView(suggestionArea)
    }

    private fun showSuggestion(refined: String, mode: String) {
        lastSuggestion = refined
        suggestionBadge.text = "✦ ${formatModeTitle(mode).uppercase()} ▾"
        suggestionText.text = refined
        suggestionArea.visibility = View.VISIBLE
        if (::candidateStrip.isInitialized) candidateStrip.visibility = View.GONE
        hideVoiceLiveBar()
    }

    private fun hideSuggestionArea() {
        suggestionArea.visibility = View.GONE
        if (::candidateStrip.isInitialized && !isSensitiveField) candidateStrip.visibility = View.VISIBLE
    }

    private fun cycleNextMode() {
        val coreModes = listOf("flow", "professional", "humanize", "mammals")
        val currentIndex = coreModes.indexOf(activeMode.lowercase())
        val nextMode = if (currentIndex != -1) {
            coreModes[(currentIndex + 1) % coreModes.size]
        } else {
            coreModes[0]
        }
        activeMode = nextMode
        getSharedPreferences("com.sayn.app.PREFS", Context.MODE_PRIVATE)
            .edit().putString("default_mode", nextMode).apply()

        if (lastOriginalText.isNotBlank()) {
            runFullAiRefinement(nextMode)
        } else {
            suggestionBadge.text = "✦ ${formatModeTitle(nextMode).uppercase()} ▾"
        }
    }

    private fun handleReplace() {
        val ic = currentInputConnection ?: return
        if (lastSuggestion.isEmpty()) return

        ic.beginBatchEdit()
        try {
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
        } finally {
            ic.endBatchEdit()
        }

        hideSuggestionArea()
        Toast.makeText(this, "Polished text applied", Toast.LENGTH_SHORT).show()
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
    // 3. SAYN AI Toolbar (With Sparkle Button & Mic)
    // ─────────────────────────────────────────────────────────────────────────────

    private fun buildAiToolbar() {
        aiToolbar = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            val bg = GradientDrawable().apply {
                cornerRadius = dpToPx(8).toFloat()
                setColor(COLOR_SURFACE)
                setStroke(dpToPx(1f), COLOR_BORDER)
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
                setTextColor(if (isSelected) COLOR_WARM_CREAM else COLOR_MUTED_CREAM)
                val pillBg = GradientDrawable().apply {
                    cornerRadius = dpToPx(13).toFloat()
                    setColor(if (isSelected) COLOR_MAROON else COLOR_KEY_NORMAL)
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

        // Right 1: Rose-Maroon Sparkle Circle Button [ Sparkle ]
        val btnSparkle = FrameLayout(this).apply {
            val sBg = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(COLOR_ROSE_MAROON)
            }
            background = sBg
            isClickable = true
            isFocusable = false
            layoutParams = LinearLayout.LayoutParams(dpToPx(34), dpToPx(34)).apply {
                marginStart = dpToPx(6)
            }

            val sIcon = ImageView(this@SaynInputMethodService).apply {
                setImageResource(R.drawable.ic_sayn_sparkles)
                setColorFilter(COLOR_WARM_CREAM)
                layoutParams = FrameLayout.LayoutParams(dpToPx(18), dpToPx(18), Gravity.CENTER)
            }
            addView(sIcon)

            setOnClickListener {
                triggerKeyFeedback("ENTER")
                openFullAiPanel(activeMode)
            }
        }
        aiToolbar.addView(btnSparkle)

        // Right 2: The Voice Dictation Mic Circle Button [ Mic ]
        val btnVoice = FrameLayout(this).apply {
            val vBg = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(COLOR_KEY_NORMAL)
                setStroke(dpToPx(1f), COLOR_BORDER)
            }
            background = vBg
            isClickable = true
            isFocusable = false
            layoutParams = LinearLayout.LayoutParams(dpToPx(34), dpToPx(34)).apply {
                marginStart = dpToPx(5)
            }

            val vIcon = ImageView(this@SaynInputMethodService).apply {
                setImageResource(R.drawable.ic_sayn_mic)
                setColorFilter(COLOR_WARM_CREAM)
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
            pill.setTextColor(if (isSelected) COLOR_WARM_CREAM else COLOR_MUTED_CREAM)
            val pillBg = GradientDrawable().apply {
                cornerRadius = dpToPx(13).toFloat()
                setColor(if (isSelected) COLOR_MAROON else COLOR_KEY_NORMAL)
            }
            pill.background = pillBg
        }
    }

    // ─────────────────────────────────────────────────────────────────────────────
    // 4. Full AI Assistant Panel
    // ─────────────────────────────────────────────────────────────────────────────

    private fun buildFullAiPanel() {
        fullAiPanelContainer = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            visibility = View.GONE
            val bg = GradientDrawable().apply {
                setColor(COLOR_BG)
                cornerRadius = dpToPx(12).toFloat()
            }
            background = bg
            setPadding(dpToPx(8), dpToPx(6), dpToPx(8), dpToPx(8))
            layoutParams = LinearLayout.LayoutParams(0, 0)
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
                setTextColor(if (isSelected) COLOR_WARM_CREAM else COLOR_MUTED_CREAM)
                val pBg = GradientDrawable().apply {
                    cornerRadius = dpToPx(15).toFloat()
                    setColor(if (isSelected) COLOR_MAROON else COLOR_KEY_NORMAL)
                    if (isSelected) setStroke(dpToPx(1.2f), COLOR_ROSE_MAROON)
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

        // 2. Center: Suggestion Card
        val card = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            val cardBg = GradientDrawable().apply {
                cornerRadius = dpToPx(14).toFloat()
                setColor(COLOR_SURFACE)
                setStroke(dpToPx(1f), COLOR_BORDER)
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
            setTextColor(COLOR_MUTED_CREAM)
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
            setTextColor(COLOR_WARM_CREAM)
            typeface = Typeface.DEFAULT_BOLD
        }
        aiCardDiffBadge = TextView(this).apply {
            text = ""
            textSize = 15f
            setTextColor(COLOR_WARM_CREAM)
            typeface = Typeface.DEFAULT_BOLD
            val badgeBg = GradientDrawable().apply {
                cornerRadius = dpToPx(4).toFloat()
                setColor(COLOR_MAROON)
                setStroke(dpToPx(1f), COLOR_ROSE_MAROON)
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
            setTextColor(COLOR_WARM_CREAM)
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
            setTextColor(COLOR_WARM_CREAM)
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            val aBg = GradientDrawable().apply {
                cornerRadius = dpToPx(14).toFloat()
                setColor(COLOR_KEY_NORMAL)
                setStroke(dpToPx(1f), COLOR_BORDER)
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
            setTextColor(COLOR_MUTED_CREAM)
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

        // 3. Bottom Navigation Bar: [ Back to Keyboard ]  • •  [ Accept all ]
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
                setColor(COLOR_KEY_NORMAL)
                setStroke(dpToPx(1f), COLOR_BORDER)
            }
            background = kBg
            isClickable = true
            isFocusable = false
            layoutParams = LinearLayout.LayoutParams(dpToPx(42), dpToPx(38))

            val kIcon = ImageView(this@SaynInputMethodService).apply {
                setImageResource(R.drawable.ic_sayn_keyboard)
                setColorFilter(COLOR_WARM_CREAM)
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
            setTextColor(COLOR_MUTED_CREAM)
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.MATCH_PARENT, 1f)
        }
        bottomBar.addView(aiPagerIndicator)

        // Bottom Right: [ Accept all ] Pill Button in Deep Maroon
        btnAiAcceptAll = TextView(this).apply {
            text = "Accept all"
            textSize = 13.5f
            typeface = Typeface.DEFAULT_BOLD
            setTextColor(COLOR_WARM_CREAM)
            gravity = Gravity.CENTER
            val accBg = GradientDrawable().apply {
                cornerRadius = dpToPx(19).toFloat()
                setColor(COLOR_MAROON)
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
            pill.setTextColor(if (isSelected) COLOR_WARM_CREAM else COLOR_MUTED_CREAM)
            val pBg = GradientDrawable().apply {
                cornerRadius = dpToPx(15).toFloat()
                setColor(if (isSelected) COLOR_MAROON else COLOR_KEY_NORMAL)
                if (isSelected) setStroke(dpToPx(1.2f), COLOR_ROSE_MAROON)
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
        if (textToTransform.isBlank()) {
            Toast.makeText(this, "Type some text to polish first", Toast.LENGTH_SHORT).show()
            return
        }

        // Keys stay 100% visible and interactive!
        if (::keysContainer.isInitialized) keysContainer.visibility = View.VISIBLE
        if (::fullAiPanelContainer.isInitialized) fullAiPanelContainer.visibility = View.GONE
        showSuggestion("Polishing with SAYN AI...", mode)
        runFullAiRefinement(mode)
    }

    private fun closeFullAiPanel() {
        if (::fullAiPanelContainer.isInitialized) fullAiPanelContainer.visibility = View.GONE
        if (::keysContainer.isInitialized) keysContainer.visibility = View.VISIBLE
        hideSuggestionArea()
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
        suggestionBadge.text = "✦ ${formatModeTitle(mode).uppercase()} ▾"
        suggestionText.text = "Polishing with SAYN AI..."

        CoroutineScope(Dispatchers.IO).launch {
            try {
                val refined = requestAiRefinement(lastOriginalText, mode)
                withContext(Dispatchers.Main) {
                    lastSuggestion = refined
                    showSuggestion(refined, mode)
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    showSuggestion(lastOriginalText, mode)
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
        return Pair("Refined", "Polished")
    }

    private fun handleAcceptCurrentSuggestion() {
        val ic = currentInputConnection ?: return
        if (lastSuggestion.isNotEmpty()) {
            ic.beginBatchEdit()
            try {
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
            } finally {
                ic.endBatchEdit()
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
                voiceTranscriptText.text = "Polishing..."
                voiceTranscriptText.setTextColor(COLOR_WARM_CREAM)
                voiceStatusDot.setTextColor(COLOR_ROSE_MAROON)
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
                    voiceTranscriptText.text = "Polishing ($activeMode)..."
                    voiceTranscriptText.setTextColor(COLOR_WARM_CREAM)
                    voiceStatusDot.setTextColor(COLOR_ROSE_MAROON)
                    // Automatically refine and inject into text field without requiring manual tap
                    stopInKeyboardVoice()
                    refineAndCommitSpokenText()
                } else {
                    isListening = false
                    voiceStatusDot.setTextColor(Color.parseColor("#8E8E93"))
                    hideVoiceLiveBar()
                }
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
        letterKeyViews.clear()
        shiftKeyContainer = null
        shiftKeyIcon = null

        when (symbolLayoutMode) {
            0 -> renderQwertyLayout()
            1 -> renderSymbols123Layout()
            2 -> renderSymbolsAltLayout()
            3 -> renderEmojiLayout()
        }
    }

    private fun updateShiftState() {
        if (symbolLayoutMode != 0) return
        val isUpper = isShifted || isCapsLock
        for ((baseKey, tv) in letterKeyViews) {
            tv.text = if (isUpper) baseKey.uppercase() else baseKey.lowercase()
        }
        updateShiftKeyVisuals()
    }

    private fun updateShiftKeyVisuals() {
        val isActive = isShifted || isCapsLock
        shiftKeyContainer?.background = createObsidianKeyDrawable("SHIFT", true)
        val tint = if (isActive) COLOR_BG else COLOR_WARM_CREAM
        shiftKeyIcon?.setColorFilter(tint, PorterDuff.Mode.SRC_IN)
    }

    private fun renderQwertyLayout() {
        letterKeyViews.clear()
        shiftKeyContainer = null
        shiftKeyIcon = null

        // Row 1: Q W E R T Y U I O P (10 keys - weight: 1.0 each = 10.0f)
        val row1 = listOf("Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P")
        keysContainer.addView(createRowView(row1, hasSpacer = false))

        // Row 2: A S D F G H J K L (9 keys, perfectly centered with 0.5f spacer on left & right = 10.0f)
        val row2 = listOf("A", "S", "D", "F", "G", "H", "J", "K", "L")
        keysContainer.addView(createRowView(row2, hasSpacer = true))

        // Row 3: SHIFT (1.45f), Z X C V B N M (7.0f), DEL (1.55f) = 10.0f
        val row3 = listOf("SHIFT", "Z", "X", "C", "V", "B", "N", "M", "DEL")
        keysContainer.addView(createRowView(row3, hasSpacer = false))

        // Row 4: Exactly matches screenshot: [123] [😊] [@] [  SAYN  ] [.] [↓]
        val row4 = listOf("123", "EMOJI", "@", "SPACE", ".", "ENTER")
        keysContainer.addView(createRowView(row4, hasSpacer = false))
    }

    private fun renderSymbols123Layout() {
        val row1 = listOf("1", "2", "3", "4", "5", "6", "7", "8", "9", "0")
        keysContainer.addView(createRowView(row1, hasSpacer = false))

        val row2 = listOf("-", "/", ":", ";", "(", ")", "$", "&", "@", "\"")
        keysContainer.addView(createRowView(row2, hasSpacer = false))

        val row3 = listOf("#+=", ".", ",", "?", "!", "'", "DEL")
        keysContainer.addView(createRowView(row3, hasSpacer = false))

        val row4 = listOf("ABC", "EMOJI", "@", "SPACE", ".", "ENTER")
        keysContainer.addView(createRowView(row4, hasSpacer = false))
    }

    private fun renderSymbolsAltLayout() {
        val row1 = listOf("[", "]", "{", "}", "#", "%", "^", "*", "+", "=")
        keysContainer.addView(createRowView(row1, hasSpacer = false))

        val row2 = listOf("_", "\\", "|", "~", "<", ">", "€", "£", "¥", "•")
        keysContainer.addView(createRowView(row2, hasSpacer = false))

        val row3 = listOf("123", ".", ",", "?", "!", "'", "DEL")
        keysContainer.addView(createRowView(row3, hasSpacer = false))

        val row4 = listOf("ABC", "EMOJI", "@", "SPACE", ".", "ENTER")
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

        // Bottom control row in emoji layout: [ ABC ] [ 123 ] [ @ ] [ SPACE ] [ DEL ] [ ENTER ]
        val bottomRow = listOf("ABC", "123", "@", "SPACE", "DEL", "ENTER")
        keysContainer.addView(createRowView(bottomRow, hasSpacer = false))
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
                "SPACE" -> 4.4f
                "ENTER" -> 1.3f
                "SHIFT" -> 1.45f
                "DEL" -> 1.55f
                "123" -> 1.15f
                "ABC", "#+=" -> 1.2f
                "EMOJI" -> 1.05f
                "@" -> 1.05f
                "." -> 1.05f
                "MIC" -> 1.1f
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

    private fun buildKeycapView(key: String, weight: Float): View {
        val container = FrameLayout(this).apply {
            layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.MATCH_PARENT, weight).apply {
                marginStart = dpToPx(2.5f)
                marginEnd = dpToPx(2.5f)
            }
            isClickable = true
            isFocusable = false
        }

        val isSpecial = key in listOf("ENTER", "123", "ABC", "#+=", "DEL", "SHIFT", "GLOBE", "MIC", "EMOJI", "@", ".")
        container.background = createObsidianKeyDrawable(key, isSpecial)

        // 1. Center Content: Text or Vector Icon
        val displayText = formatKeyText(key)
        if (key in listOf("SHIFT", "DEL", "EMOJI", "ENTER", "MIC", "GLOBE")) {
            val iconView = ImageView(this).apply {
                val iconRes = when (key) {
                    "SHIFT" -> R.drawable.ic_sayn_shift
                    "DEL" -> R.drawable.ic_sayn_backspace
                    "EMOJI" -> R.drawable.ic_sayn_emoji
                    "ENTER" -> R.drawable.ic_sayn_down
                    "MIC" -> R.drawable.ic_sayn_mic
                    else -> R.drawable.ic_sayn_globe
                }
                val tint = if (key == "SHIFT" && (isShifted || isCapsLock)) COLOR_BG else COLOR_WARM_CREAM
                setImageResource(iconRes)
                setColorFilter(tint, PorterDuff.Mode.SRC_IN)
                layoutParams = FrameLayout.LayoutParams(dpToPx(19), dpToPx(19), Gravity.CENTER)
            }
            container.addView(iconView)
            if (key == "SHIFT" && symbolLayoutMode == 0) {
                shiftKeyContainer = container
                shiftKeyIcon = iconView
            }
        } else {
            val textView = TextView(this).apply {
                text = displayText
                gravity = Gravity.CENTER
                includeFontPadding = false
                if (key.length == 1 && symbolLayoutMode == 0) {
                    textSize = 21f
                    typeface = Typeface.DEFAULT
                    setTextColor(COLOR_WARM_CREAM)
                } else if (key == "SPACE") {
                    textSize = 12.5f
                    typeface = Typeface.DEFAULT
                    setTextColor(COLOR_FAINT_CREAM)
                } else if (key in listOf("123", "ABC", "#+=")) {
                    textSize = 13.5f
                    typeface = Typeface.DEFAULT
                    setTextColor(COLOR_WARM_CREAM)
                } else if (key in listOf("@", ".")) {
                    textSize = 18f
                    typeface = Typeface.DEFAULT
                    setTextColor(COLOR_WARM_CREAM)
                } else {
                    textSize = 15f
                    typeface = Typeface.DEFAULT
                    setTextColor(COLOR_WARM_CREAM)
                }
                layoutParams = FrameLayout.LayoutParams(
                    FrameLayout.LayoutParams.MATCH_PARENT,
                    FrameLayout.LayoutParams.MATCH_PARENT,
                    Gravity.CENTER
                )
            }
            container.addView(textView)
            if (key.length == 1 && symbolLayoutMode == 0 && key[0].isLetter()) {
                letterKeyViews[key.uppercase()] = textView
            }
        }

        // 2. Top-Right Corner Hint (1..0, !, ?, etc. as shown in reference screenshot)
        val hintChar = if (symbolLayoutMode == 0) keyHintMap[key.uppercase()] else null
        if (hintChar != null) {
            val hintView = TextView(this).apply {
                text = hintChar
                textSize = 9.5f
                setTextColor(COLOR_TEXT_HINT)
                includeFontPadding = false
                gravity = Gravity.TOP or Gravity.END
                setPadding(0, dpToPx(3), dpToPx(5), 0)
                layoutParams = FrameLayout.LayoutParams(
                    FrameLayout.LayoutParams.WRAP_CONTENT,
                    FrameLayout.LayoutParams.WRAP_CONTENT,
                    Gravity.TOP or Gravity.END
                )
            }
            container.addView(hintView)
        }

        // 3. Touch & Gestures Handling (Swipe on spacebar, Long press for hints, Repeat on backspace)
        when (key) {
            "DEL" -> setupDeleteRepeat(container)
            "SPACE" -> setupSpacebarSwipe(container)
            else -> setupKeyTouchWithLongPress(container, key, hintChar)
        }

        return container
    }

    private fun setupSpacebarSwipe(view: View) {
        var startX = 0f
        var lastStepX = 0f
        var isSwiping = false

        view.setOnTouchListener { v, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    v.isPressed = true
                    startX = event.x
                    lastStepX = event.x
                    isSwiping = false
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    val totalDx = event.x - startX
                    if (!isSwiping && Math.abs(totalDx) > dpToPx(12)) {
                        isSwiping = true
                    }
                    if (isSwiping) {
                        val stepDx = event.x - lastStepX
                        val threshold = dpToPx(10)
                        if (Math.abs(stepDx) >= threshold) {
                            val dir = if (stepDx > 0) 1 else -1
                            moveCursor(dir)
                            lastStepX = event.x
                            vibrateTap()
                        }
                    }
                    true
                }
                MotionEvent.ACTION_UP -> {
                    v.isPressed = false
                    if (isSwiping) {
                        isSwiping = false
                    } else {
                        triggerKeyFeedback("SPACE")
                        handleKeyAction("SPACE")
                    }
                    true
                }
                MotionEvent.ACTION_CANCEL -> {
                    v.isPressed = false
                    isSwiping = false
                    true
                }
                else -> false
            }
        }
    }

    private fun moveCursor(direction: Int) {
        val ic = currentInputConnection ?: return
        val keycode = if (direction < 0) android.view.KeyEvent.KEYCODE_DPAD_LEFT else android.view.KeyEvent.KEYCODE_DPAD_RIGHT
        ic.sendKeyEvent(android.view.KeyEvent(android.view.KeyEvent.ACTION_DOWN, keycode))
        ic.sendKeyEvent(android.view.KeyEvent(android.view.KeyEvent.ACTION_UP, keycode))
    }

    private fun setupKeyTouchWithLongPress(view: View, key: String, hintChar: String?) {
        var isLongPressed = false
        val longPressRunnable = Runnable {
            if (hintChar != null) {
                isLongPressed = true
                vibrateTap()
                val ic = currentInputConnection
                if (ic != null) {
                    ic.commitText(hintChar, 1)
                    updateCandidates()
                    checkAutoCapitalization()
                }
            }
        }

        view.setOnTouchListener { v, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    v.isPressed = true
                    isLongPressed = false
                    if (hintChar != null) {
                        longPressHandler.postDelayed(longPressRunnable, 320)
                    }
                    true
                }
                MotionEvent.ACTION_UP -> {
                    v.isPressed = false
                    longPressHandler.removeCallbacks(longPressRunnable)
                    if (!isLongPressed) {
                        triggerKeyFeedback(key)
                        handleKeyAction(key)
                    }
                    true
                }
                MotionEvent.ACTION_CANCEL -> {
                    v.isPressed = false
                    longPressHandler.removeCallbacks(longPressRunnable)
                    isLongPressed = false
                    true
                }
                else -> false
            }
        }
    }

    private fun createObsidianKeyDrawable(key: String, isSpecial: Boolean): StateListDrawable {
        val states = StateListDrawable()
        val corner = dpToPx(8.5f).toFloat()
        val strokeW = dpToPx(1f)

        // Active Shift / CapsLock State
        if (key == "SHIFT" && (isShifted || isCapsLock)) {
            val normalActive = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = corner
                setColor(COLOR_WARM_CREAM)
                setStroke(strokeW, Color.WHITE)
            }
            val pressedActive = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = corner
                setColor(COLOR_MUTED_CREAM)
                setStroke(strokeW, Color.WHITE)
            }
            states.addState(intArrayOf(android.R.attr.state_pressed), pressedActive)
            states.addState(intArrayOf(), normalActive)
            return states
        }

        val normalColor = if (isSpecial) COLOR_KEY_SPECIAL else COLOR_KEY_NORMAL
        val pressedColor = if (isSpecial) COLOR_KEY_SPECIAL_PRESSED else COLOR_KEY_PRESSED
        val normalBorder = if (isSpecial) COLOR_KEY_SPECIAL_BORDER else COLOR_KEY_BORDER
        val pressedBorder = COLOR_KEY_BORDER_PRESSED

        val pressedFace = GradientDrawable().apply {
            shape = GradientDrawable.RECTANGLE
            cornerRadius = corner
            setColor(pressedColor)
            setStroke(strokeW, pressedBorder)
        }

        val normalFace = GradientDrawable().apply {
            shape = GradientDrawable.RECTANGLE
            cornerRadius = corner
            setColor(normalColor)
            setStroke(strokeW, normalBorder)
        }

        states.addState(intArrayOf(android.R.attr.state_pressed), pressedFace)
        states.addState(intArrayOf(), normalFace)
        return states
    }

    private fun formatKeyText(key: String): String {
        return when (key) {
            "SHIFT" -> ""
            "DEL" -> ""
            "GLOBE" -> ""
            "MIC" -> ""
            "EMOJI" -> ""
            "ENTER" -> ""
            "SPACE" -> "SAYN"
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
                ic.beginBatchEdit()
                try {
                    ic.deleteSurroundingText(rawWord.length, 0)
                    ic.commitText(replacement + delimiter, 1)
                } finally {
                    ic.endBatchEdit()
                }
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
            "DEL" -> {
                ic.deleteSurroundingText(1, 0)
                updateCandidates()
                checkAutoCapitalization()
            }
            "SPACE" -> {
                val now = System.currentTimeMillis()
                val before = ic.getTextBeforeCursor(2, 0)?.toString() ?: ""
                if (now - lastSpacePressTime < 450 && before.endsWith(" ")) {
                    // Double space for period
                    ic.beginBatchEdit()
                    try {
                        ic.deleteSurroundingText(1, 0)
                        ic.commitText(". ", 1)
                        isShifted = true
                        updateShiftState()
                    } finally {
                        ic.endBatchEdit()
                    }
                    lastSpacePressTime = 0L
                    updateCandidates()
                } else {
                    lastSpacePressTime = now
                    applyAutoCorrect(" ")
                    updateCandidates()
                    checkAutoCapitalization()
                }
            }
            "ENTER" -> {
                applyAutoCorrect("")
                handleEnterAction()
                updateCandidates()
                checkAutoCapitalization()
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
            "." -> {
                applyAutoCorrect(".")
                updateCandidates()
                checkAutoCapitalization()
            }
            "," -> {
                applyAutoCorrect(",")
                updateCandidates()
                checkAutoCapitalization()
            }
            "!" -> {
                applyAutoCorrect("!")
                updateCandidates()
                checkAutoCapitalization()
            }
            "?" -> {
                applyAutoCorrect("?")
                updateCandidates()
                checkAutoCapitalization()
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
                updateShiftState()
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
                ic.beginBatchEdit()
                try {
                    ic.commitText(charToCommit, 1)

                    if (isShifted && !isCapsLock) {
                        isShifted = false
                        updateShiftState()
                    }
                } finally {
                    ic.endBatchEdit()
                }
                updateCandidates()
            }
        }
    }

    private fun setupDeleteRepeat(view: View) {
        view.setOnTouchListener { v, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    v.isPressed = true
                    triggerKeyFeedback("DEL")
                    handleKeyAction("DEL")
                    deleteRunnable = object : Runnable {
                        override fun run() {
                            handleKeyAction("DEL")
                            deleteHandler.postDelayed(this, 40)
                        }
                    }
                    deleteHandler.postDelayed(deleteRunnable!!, 280)
                    true
                }
                MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                    v.isPressed = false
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
            val inputType = currentInfo?.inputType ?: 0
            val isMultiline = (inputType and EditorInfo.TYPE_TEXT_FLAG_MULTI_LINE) != 0
            if (isMultiline) {
                ic.commitText("\n", 1)
            } else {
                requestHideSelf(0)
            }
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
        shadowColor: Int = COLOR_KEY_SHADOW,
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
        deleteHandler.removeCallbacksAndMessages(null)
        longPressHandler.removeCallbacksAndMessages(null)
    }

    private fun dpToPx(dp: Float): Int = (dp * resources.displayMetrics.density).toInt()
    private fun dpToPx(dp: Int): Int = (dp * resources.displayMetrics.density).toInt()
}
