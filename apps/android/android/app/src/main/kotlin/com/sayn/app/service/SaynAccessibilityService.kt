package com.sayn.app.service

import android.accessibilityservice.AccessibilityService
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.os.Bundle
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import com.sayn.app.overlay.FloatingBubbleService

class SaynAccessibilityService : AccessibilityService() {

    companion object {
        var instance: SaynAccessibilityService? = null
            private set
        var isConnected = false
            private set
    }

    private var lastFocusedNode: AccessibilityNodeInfo? = null

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        isConnected = true
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        when (event.eventType) {
            AccessibilityEvent.TYPE_VIEW_FOCUSED -> {
                val node = event.source ?: rootInActiveWindow?.findFocus(AccessibilityNodeInfo.FOCUS_INPUT)
                if (node != null && node.isEditable) {
                    lastFocusedNode = node
                    FloatingBubbleService.setUniversalInputActive(true)
                }
            }
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED -> {
                val focused = rootInActiveWindow?.findFocus(AccessibilityNodeInfo.FOCUS_INPUT)
                if (focused != null && focused.isEditable) {
                    lastFocusedNode = focused
                    FloatingBubbleService.setUniversalInputActive(true)
                } else {
                    val anyFocus = rootInActiveWindow?.findFocus(AccessibilityNodeInfo.FOCUS_INPUT)
                    if (anyFocus == null || !anyFocus.isEditable) {
                        FloatingBubbleService.setUniversalInputActive(false)
                    }
                }
            }
        }
    }

    override fun onInterrupt() {
        instance = null
        isConnected = false
        lastFocusedNode = null
    }

    override fun onDestroy() {
        super.onDestroy()
        instance = null
        isConnected = false
        lastFocusedNode = null
    }

    /**
     * Inserts text directly into whichever text box is active across ANY app or ANY keyboard.
     */
    fun insertTextIntoFocusedField(text: String): Boolean {
        val targetNode = lastFocusedNode ?: rootInActiveWindow?.findFocus(AccessibilityNodeInfo.FOCUS_INPUT)
        if (targetNode != null) {
            val arguments = Bundle().apply {
                putCharSequence(AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE, text)
            }
            val setResult = targetNode.performAction(AccessibilityNodeInfo.ACTION_SET_TEXT, arguments)
            if (setResult) return true

            // Fallback: Clipboard paste
            val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
            clipboard.setPrimaryClip(ClipData.newPlainText("SAYN Voice", text))
            val pasteResult = targetNode.performAction(AccessibilityNodeInfo.ACTION_PASTE)
            if (pasteResult) return true
        }

        // Final fallback: copy to clipboard
        val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        clipboard.setPrimaryClip(ClipData.newPlainText("SAYN Voice", text))
        return false
    }
}
