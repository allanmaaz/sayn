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

        // Official SAYN Royal Brand Colors
        val COLOR_BG = Color.parseColor("#100709")
        val COLOR_SURFACE = Color.parseColor("#180B0F")
        val COLOR_KEY_NORMAL = Color.parseColor("#240F16")
        val COLOR_KEY_PRESSED = Color.parseColor("#3D1520")
        val COLOR_KEY_SHADOW = Color.parseColor("#0A0406")
        val COLOR_KEY_SPECIAL = Color.parseColor("#1A0A0E")
        val COLOR_KEY_SPECIAL_PRESSED = Color.parseColor("#2B1218")
        val COLOR_BORDER = Color.parseColor("#3D1520")
        val COLOR_MAROON = Color.parseColor("#6F1025")
        val COLOR_MAROON_PRESSED = Color.parseColor("#520B1B")
        val COLOR_ROSE_MAROON = Color.parseColor("#A83249")
        val COLOR_ROSE_MAROON_PRESSED = Color.parseColor("#872639")
        val COLOR_WARM_CREAM = Color.parseColor("#F5EBDD")
        val COLOR_MUTED_CREAM = Color.parseColor("#D6C7B2")
        val COLOR_FAINT_CREAM = Color.parseColor("#8F7E75")
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
            aiToolbar.visibility = View.VISIBLE
            if (::candidateStrip.isInitialized) {
                candidateStrip.visibility = View.VISIBLE
                updateCandidates()
            }
        }

        symbolLayoutMode = 0
        isShifted = false
        isCapsLock = false
        renderKeys()
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

        candidateLeft = TextView(this).apply {
            text = ""
            textSize = 13.5f
            setTextColor(COLOR_MUTED_CREAM)
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

        val div1 = View(this).apply {
            setBackgroundColor(COLOR_BORDER)
            layoutParams = LinearLayout.LayoutParams(dpToPx(1f), dpToPx(18)).apply {
                marginStart = dpToPx(4)
                marginEnd = dpToPx(4)
            }
        }

        candidateCenter = TextView(this).apply {
            text = ""
            textSize = 14f
            typeface = Typeface.DEFAULT_BOLD
            setTextColor(COLOR_WARM_CREAM)
            gravity = Gravity.CENTER
            isSingleLine = true
            ellipsize = android.text.TextUtils.TruncateAt.END
            val cBg = GradientDrawable().apply {
                cornerRadius = dpToPx(14).toFloat()
                setColor(COLOR_MAROON)
            }
            background = cBg
            setPadding(dpToPx(12), 0, dpToPx(12), 0)
            isClickable = true
            isFocusable = false
            setOnClickListener {
                val t = text.toString().trim()
                if (t.isNotEmpty()) {
                    triggerKeyFeedback("ENTER")
                    commitCandidate(t)
                }
            }
            layoutParams = LinearLayout.LayoutParams(0, dpToPx(30), 1.3f)
        }

        val div2 = View(this).apply {
            setBackgroundColor(COLOR_BORDER)
            layoutParams = LinearLayout.LayoutParams(dpToPx(1f), dpToPx(18)).apply {
                marginStart = dpToPx(4)
                marginEnd = dpToPx(4)
            }
        }

        candidateRight = TextView(this).apply {
            text = ""
            textSize = 13.5f
            setTextColor(COLOR_MUTED_CREAM)
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

        candidateStrip.addView(candidateLeft)
        candidateStrip.addView(div1)
        candidateStrip.addView(candidateCenter)
        candidateStrip.addView(div2)
        candidateStrip.addView(candidateRight)

        rootLayout.addView(candidateStrip)
    }

    private fun commitCandidate(candidate: String) {
        val ic = currentInputConnection ?: return
        val before = ic.getTextBeforeCursor(40, 0)?.toString() ?: ""

        val match = Regex("""([a-zA-Z']+)\z""").find(before)
        if (match != null) {
            ic.deleteSurroundingText(match.value.length, 0)
        }

        ic.commitText("$candidate ", 1)
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

        // Case 1: Empty or start of sentence
        if (before.isEmpty() || before.endsWith(". ") || before.endsWith("? ") || before.endsWith("! ") || before.endsWith("\n")) {
            setCandidateTexts("I", "The", "Thanks")
            return
        }

        // Case 2: Currently typing a word
        val wordMatch = Regex("""([a-zA-Z']+)\z""").find(before)
        if (wordMatch != null) {
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
            val left = if (matches.size > 1) matches[1] else typed
            val right = emojiMatch ?: if (matches.size > 2) matches[2] else ""

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
                val center = predictions.getOrElse(0) { "" }
                val left = predictions.getOrElse(1) { "" }
                val right = predictions.getOrElse(2) { "" }
                setCandidateTexts(left, center, right)
                return
            }
        }

        setCandidateTexts("to", "the", "and")
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
        if (isCapsLock) return
        val ic = currentInputConnection ?: return
        val before = ic.getTextBeforeCursor(4, 0)?.toString() ?: ""
        val shouldShift = before.isEmpty() || before.endsWith("\n") || 
                          before.endsWith(". ") || before.endsWith("? ") || before.endsWith("! ")
        if (shouldShift != isShifted) {
            isShifted = shouldShift
            renderKeys()
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
            setPadding(dpToPx(8), dpToPx(3), dpToPx(8), dpToPx(5))
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                dpToPx(52)
            ).apply { bottomMargin = dpToPx(2) }
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
            layoutParams = LinearLayout.LayoutParams(dpToPx(44), dpToPx(44))
        }

        val cancelIcon = ImageView(this).apply {
            setImageResource(R.drawable.ic_sayn_close)
            setColorFilter(COLOR_WARM_CREAM)
            layoutParams = FrameLayout.LayoutParams(
                dpToPx(18),
                dpToPx(18),
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
                cornerRadius = dpToPx(23f).toFloat()
                setColor(COLOR_SURFACE)
                setStroke(dpToPx(1f), COLOR_BORDER)
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
            setTextColor(COLOR_WARM_CREAM)
            gravity = Gravity.CENTER_VERTICAL
            isSingleLine = true
            ellipsize = android.text.TextUtils.TruncateAt.END
            layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.MATCH_PARENT, 1f)
        }

        voiceStatusDot = TextView(this).apply {
            text = "• • • • •"
            textSize = 15f
            setTextColor(COLOR_ROSE_MAROON)
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dpToPx(6), 0, 0, 0)
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
            layoutParams = LinearLayout.LayoutParams(dpToPx(44), dpToPx(44))
        }

        btnCorrectAndInsert = ImageView(this).apply {
            setImageResource(R.drawable.ic_sayn_check)
            setColorFilter(COLOR_WARM_CREAM)
            layoutParams = FrameLayout.LayoutParams(
                dpToPx(20),
                dpToPx(20),
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
            orientation = LinearLayout.VERTICAL
            visibility = View.GONE
            val bg = GradientDrawable().apply {
                cornerRadius = dpToPx(10).toFloat()
                setColor(COLOR_SURFACE)
                setStroke(dpToPx(1.2f), COLOR_BORDER)
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
            text = "REFINEMENT SUGGESTION"
            textSize = 10f
            setTextColor(COLOR_ROSE_MAROON)
            typeface = Typeface.DEFAULT_BOLD
            layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
        }

        btnDismiss = ImageView(this).apply {
            setImageResource(R.drawable.ic_sayn_close)
            setColorFilter(COLOR_MUTED_CREAM)
            layoutParams = LinearLayout.LayoutParams(dpToPx(18), dpToPx(18)).apply {
                marginEnd = dpToPx(4)
            }
            setOnClickListener { hideSuggestionArea() }
        }

        topRow.addView(suggestionBadge)
        topRow.addView(btnDismiss)
        suggestionArea.addView(topRow)

        suggestionText = TextView(this).apply {
            text = ""
            textSize = 13.5f
            setTextColor(COLOR_WARM_CREAM)
            setPadding(0, dpToPx(4), 0, dpToPx(6))
            maxLines = 4
        }
        suggestionArea.addView(suggestionText)

        val actionsRow = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }

        btnReplace = TextView(this).apply {
            text = "Replace"
            val chk = ContextCompat.getDrawable(this@SaynInputMethodService, R.drawable.ic_sayn_check)?.mutate()
            chk?.setBounds(0, 0, dpToPx(14), dpToPx(14))
            chk?.setColorFilter(COLOR_WARM_CREAM, PorterDuff.Mode.SRC_IN)
            setCompoundDrawables(chk, null, null, null)
            compoundDrawablePadding = dpToPx(4)
            textSize = 12f
            setTextColor(COLOR_WARM_CREAM)
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            background = createIosKeyDrawable(
                normalColor = COLOR_MAROON,
                pressedColor = COLOR_MAROON_PRESSED,
                shadowColor = COLOR_KEY_SHADOW,
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
            setTextColor(COLOR_WARM_CREAM)
            gravity = Gravity.CENTER
            background = createIosKeyDrawable(
                normalColor = COLOR_KEY_NORMAL,
                pressedColor = COLOR_KEY_PRESSED,
                shadowColor = COLOR_KEY_SHADOW,
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
            setTextColor(COLOR_MUTED_CREAM)
            gravity = Gravity.CENTER
            background = createIosKeyDrawable(
                normalColor = COLOR_KEY_SPECIAL,
                pressedColor = COLOR_KEY_SPECIAL_PRESSED,
                shadowColor = COLOR_KEY_SHADOW,
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
        suggestionBadge.text = "${mode.uppercase()} REFINEMENT"
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
        keysContainer.visibility = View.GONE
        aiToolbar.visibility = View.GONE
        voiceLiveBar.visibility = View.GONE
        suggestionArea.visibility = View.GONE
        if (::candidateStrip.isInitialized) candidateStrip.visibility = View.GONE
        fullAiPanelContainer.visibility = View.VISIBLE

        if (textToTransform.isBlank()) {
            aiCardTitle.text = "• Input Empty"
            aiCardDiffWord.text = "Type some words first"
            aiCardDiffBadge.text = ""
            aiCardPreview.text = "Tap the keyboard icon at bottom left to type a message, then tap the AI sparkle icon to polish it."
            return
        }

        runFullAiRefinement(mode)
    }

    private fun closeFullAiPanel() {
        fullAiPanelContainer.visibility = View.GONE
        keysContainer.visibility = View.VISIBLE
        aiToolbar.visibility = if (isSensitiveField) View.GONE else View.VISIBLE
        if (::candidateStrip.isInitialized && !isSensitiveField) candidateStrip.visibility = View.VISIBLE
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
        return Pair("Refined", "Polished")
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
                "SPACE" -> 4.7f
                "ENTER" -> 1.8f
                "SHIFT" -> 1.45f
                "DEL" -> 1.55f
                "123", "ABC", "#+=" -> 1.2f
                "EMOJI" -> 1.2f
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
                setTextColor(COLOR_WARM_CREAM)
            } else if (key == "ENTER") {
                textSize = 14f
                typeface = Typeface.DEFAULT_BOLD
                setTextColor(COLOR_WARM_CREAM)
            } else if (key in listOf("SHIFT", "DEL")) {
                textSize = 18f
                typeface = Typeface.DEFAULT
                setTextColor(if (key == "SHIFT" && (isShifted || isCapsLock)) COLOR_BG else COLOR_WARM_CREAM)
            } else if (key == "SPACE") {
                textSize = 14f
                typeface = Typeface.DEFAULT
                setTextColor(COLOR_FAINT_CREAM)
            } else if (key in listOf("123", "ABC", "#+=")) {
                textSize = 14f
                typeface = Typeface.DEFAULT
                setTextColor(COLOR_WARM_CREAM)
            } else if (key == "EMOJI") {
                textSize = 20f
                typeface = Typeface.DEFAULT
                setTextColor(COLOR_WARM_CREAM)
            } else {
                textSize = 16f
                typeface = Typeface.DEFAULT
                setTextColor(COLOR_WARM_CREAM)
            }

            // Authentic vector icons replacing emojis
            if (key == "MIC") {
                text = ""
                val micDrawable = ContextCompat.getDrawable(this@SaynInputMethodService, R.drawable.ic_sayn_mic)?.mutate()
                micDrawable?.setBounds(0, 0, dpToPx(19), dpToPx(19))
                micDrawable?.setColorFilter(COLOR_ROSE_MAROON, PorterDuff.Mode.SRC_IN)
                setCompoundDrawables(null, micDrawable, null, null)
            } else if (key == "GLOBE") {
                text = ""
                val globeDrawable = ContextCompat.getDrawable(this@SaynInputMethodService, R.drawable.ic_sayn_globe)?.mutate()
                globeDrawable?.setBounds(0, 0, dpToPx(18), dpToPx(18))
                globeDrawable?.setColorFilter(COLOR_WARM_CREAM, PorterDuff.Mode.SRC_IN)
                setCompoundDrawables(null, globeDrawable, null, null)
            } else if (key == "EMOJI") {
                text = ""
                val emojiDrawable = ContextCompat.getDrawable(this@SaynInputMethodService, R.drawable.ic_sayn_emoji)?.mutate()
                emojiDrawable?.setBounds(0, 0, dpToPx(19), dpToPx(19))
                emojiDrawable?.setColorFilter(COLOR_WARM_CREAM, PorterDuff.Mode.SRC_IN)
                setCompoundDrawables(null, emojiDrawable, null, null)
            } else if (key == "DEL") {
                text = ""
                val delDrawable = ContextCompat.getDrawable(this@SaynInputMethodService, R.drawable.ic_sayn_backspace)?.mutate()
                delDrawable?.setBounds(0, 0, dpToPx(19), dpToPx(19))
                delDrawable?.setColorFilter(COLOR_WARM_CREAM, PorterDuff.Mode.SRC_IN)
                setCompoundDrawables(null, delDrawable, null, null)
            } else if (key == "SHIFT") {
                text = ""
                val shiftDrawable = ContextCompat.getDrawable(this@SaynInputMethodService, R.drawable.ic_sayn_shift)?.mutate()
                val shiftColor = if (isShifted || isCapsLock) COLOR_BG else COLOR_WARM_CREAM
                shiftDrawable?.setBounds(0, 0, dpToPx(18), dpToPx(18))
                shiftDrawable?.setColorFilter(shiftColor, PorterDuff.Mode.SRC_IN)
                setCompoundDrawables(null, shiftDrawable, null, null)
            }

            // Authentic tactile Chiclet Backgrounds
            val bg = when {
                key == "ENTER" -> {
                    createIosKeyDrawable(
                        normalColor = COLOR_MAROON,
                        pressedColor = COLOR_MAROON_PRESSED,
                        shadowColor = COLOR_KEY_SHADOW
                    )
                }
                key == "SHIFT" && (isShifted || isCapsLock) -> {
                    createIosKeyDrawable(
                        normalColor = COLOR_WARM_CREAM,
                        pressedColor = COLOR_MUTED_CREAM,
                        shadowColor = COLOR_KEY_SHADOW
                    )
                }
                isSpecial -> {
                    createIosKeyDrawable(
                        normalColor = COLOR_KEY_SPECIAL,
                        pressedColor = COLOR_KEY_SPECIAL_PRESSED,
                        shadowColor = COLOR_KEY_SHADOW
                    )
                }
                else -> {
                    createIosKeyDrawable(
                        normalColor = COLOR_KEY_NORMAL,
                        pressedColor = COLOR_KEY_PRESSED,
                        shadowColor = COLOR_KEY_SHADOW
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
            "SHIFT" -> ""
            "DEL" -> ""
            "GLOBE" -> ""
            "MIC" -> ""
            "EMOJI" -> ""
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
                    ic.deleteSurroundingText(1, 0)
                    ic.commitText(". ", 1)
                    isShifted = true
                    renderKeys()
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
                updateCandidates()
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
                            deleteHandler.postDelayed(this, 40)
                        }
                    }
                    deleteHandler.postDelayed(deleteRunnable!!, 280)
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
    }

    private fun dpToPx(dp: Float): Int = (dp * resources.displayMetrics.density).toInt()
    private fun dpToPx(dp: Int): Int = (dp * resources.displayMetrics.density).toInt()
}
