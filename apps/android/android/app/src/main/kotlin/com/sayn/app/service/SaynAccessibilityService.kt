package com.sayn.app.service

import android.accessibilityservice.AccessibilityService
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.view.accessibility.AccessibilityWindowInfo
import com.sayn.app.overlay.FloatingBubbleService

class SaynAccessibilityService : AccessibilityService() {

    companion object {
        var instance: SaynAccessibilityService? = null
            private set
        var isConnected = false
            private set
        var activePackageName: String? = null
            private set

        fun resolveAdaptiveModeForPackage(packageName: String?): String {
            if (packageName == null) return "mammals"
            val pkg = packageName.lowercase()
            return when {
                // Professional / Email / Docs
                pkg.contains("gm") || pkg.contains("email") || pkg.contains("outlook") ||
                pkg.contains("docs") || pkg.contains("word") || pkg.contains("notion") -> "professional"

                // Concise / Team chat
                pkg.contains("slack") || pkg.contains("teams") -> "concise"

                // Confident / Social media
                pkg.contains("linkedin") || pkg.contains("twitter") || pkg.contains("x.android") -> "confident"

                // Casual / Messaging (natural cadence, zero trailing period)
                pkg.contains("whatsapp") || pkg.contains("telegram") || pkg.contains("signal") ||
                pkg.contains("messaging") || pkg.contains("mms") || pkg.contains("instagram") -> "mammals"

                else -> "mammals"
            }
        }
    }

    private var lastFocusedNode: AccessibilityNodeInfo? = null

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        isConnected = true
    }

    private fun ensureFloatingBubbleRunning() {
        if (!FloatingBubbleService.isRunning && Settings.canDrawOverlays(this)) {
            try {
                val intent = Intent(this, FloatingBubbleService::class.java)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    startForegroundService(intent)
                } else {
                    startService(intent)
                }
            } catch (e: Exception) {
                // Ignore service start issues
            }
        }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        val eventPkg = event.packageName?.toString()
        if (!eventPkg.isNullOrEmpty() && eventPkg != packageName) {
            activePackageName = eventPkg
        }

        when (event.eventType) {
            AccessibilityEvent.TYPE_VIEW_FOCUSED -> {
                val node = event.source ?: rootInActiveWindow?.findFocus(AccessibilityNodeInfo.FOCUS_INPUT)
                if (node != null && node.isEditable) {
                    lastFocusedNode = node
                    ensureFloatingBubbleRunning()
                    FloatingBubbleService.setUniversalInputActive(true)
                }
            }
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED,
            AccessibilityEvent.TYPE_WINDOWS_CHANGED -> {
                val focused = findEditableTargetNode()
                if (focused != null) {
                    lastFocusedNode = focused
                    ensureFloatingBubbleRunning()
                    FloatingBubbleService.setUniversalInputActive(true)
                } else {
                    FloatingBubbleService.setUniversalInputActive(false)
                }
            }
            AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED -> {
                val node = event.source
                if (node != null && node.isEditable && node.isFocused) {
                    lastFocusedNode = node
                    ensureFloatingBubbleRunning()
                    FloatingBubbleService.setUniversalInputActive(true)
                }
            }
        }
    }

    override fun onInterrupt() {
        instance = null
        isConnected = false
        activePackageName = null
        lastFocusedNode = null
    }

    override fun onDestroy() {
        super.onDestroy()
        instance = null
        isConnected = false
        activePackageName = null
        lastFocusedNode = null
    }

    /**
     * Recursively searches for the best active editable text field.
     */
    fun findEditableTargetNode(): AccessibilityNodeInfo? {
        // 1. Check lastFocusedNode if still valid and editable
        lastFocusedNode?.let { node ->
            try {
                if (node.refresh() && node.isEditable) {
                    return node
                }
            } catch (e: Exception) {
                // Ignore stale node
            }
        }

        // 2. Search root in active window
        rootInActiveWindow?.let { root ->
            try {
                val focused = root.findFocus(AccessibilityNodeInfo.FOCUS_INPUT)
                if (focused != null && focused.isEditable) {
                    return focused
                }
                val editable = findFirstEditable(root)
                if (editable != null) {
                    return editable
                }
            } catch (e: Exception) {
                // Ignore window errors
            }
        }

        // 3. Search across all interactive windows (WhatsApp, Instagram, Telegram)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            try {
                val appWindows = windows.filter {
                    it.type == AccessibilityWindowInfo.TYPE_APPLICATION ||
                    it.type == AccessibilityWindowInfo.TYPE_INPUT_METHOD
                }
                for (window in appWindows) {
                    val root = window.root ?: continue
                    val inputFocused = root.findFocus(AccessibilityNodeInfo.FOCUS_INPUT)
                    if (inputFocused != null && inputFocused.isEditable) {
                        return inputFocused
                    }
                    val editable = findFirstEditable(root)
                    if (editable != null) {
                        return editable
                    }
                }
            } catch (e: Exception) {
                // Ignore
            }
        }

        return null
    }

    private fun findFirstEditable(root: AccessibilityNodeInfo): AccessibilityNodeInfo? {
        if (root.isEditable) {
            return root
        }
        for (i in 0 until root.childCount) {
            val child = root.getChild(i) ?: continue
            val found = findFirstEditable(child)
            if (found != null) {
                return found
            }
        }
        return null
    }

    /**
     * Inserts text directly into whichever text box is active across ANY app or ANY keyboard.
     */
    fun insertTextIntoFocusedField(text: String): Boolean {
        val targetNode = findEditableTargetNode() ?: return false

        try {
            // Ensure target has focus
            targetNode.performAction(AccessibilityNodeInfo.ACTION_FOCUS)

            val currentText = targetNode.text?.toString() ?: ""
            val textToInsert = if (currentText.isNotEmpty() && !currentText.endsWith(" ")) {
                "$currentText $text "
            } else if (currentText.isNotEmpty()) {
                "$currentText$text "
            } else {
                "$text "
            }

            // 1. Try ACTION_SET_TEXT directly
            val arguments = Bundle().apply {
                putCharSequence(AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE, textToInsert)
            }
            if (targetNode.performAction(AccessibilityNodeInfo.ACTION_SET_TEXT, arguments)) {
                return true
            }

            // 2. Try ACTION_PASTE
            val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
            clipboard.setPrimaryClip(ClipData.newPlainText("SAYN Voice", textToInsert))
            if (targetNode.performAction(AccessibilityNodeInfo.ACTION_PASTE)) {
                return true
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }

        return false
    }
}
