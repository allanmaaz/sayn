package com.sayn.app

import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import android.view.inputmethod.InputMethodManager
import com.sayn.app.overlay.FloatingBubbleService
import com.sayn.app.overlay.OverlayPermissionHelper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val OVERLAY_CHANNEL = "com.sayn.app/overlay"
    private val KEYBOARD_CHANNEL = "com.sayn.app/keyboard"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val prefs = getSharedPreferences("com.sayn.app.PREFS", Context.MODE_PRIVATE)

        // 1. Overlay Platform Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, OVERLAY_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "checkOverlayPermission" -> {
                        result.success(OverlayPermissionHelper.hasOverlayPermission(this))
                    }
                    "requestOverlayPermission" -> {
                        OverlayPermissionHelper.requestOverlayPermission(this)
                        result.success(null)
                    }
                    "startFloatingAssistant" -> {
                        if (OverlayPermissionHelper.hasOverlayPermission(this)) {
                            val intent = Intent(this, FloatingBubbleService::class.java)
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                startForegroundService(intent)
                            } else {
                                startService(intent)
                            }
                            result.success(true)
                        } else {
                            result.success(false)
                        }
                    }
                    "stopFloatingAssistant" -> {
                        val intent = Intent(this, FloatingBubbleService::class.java)
                        stopService(intent)
                        result.success(true)
                    }
                    "isOverlayRunning" -> {
                        result.success(FloatingBubbleService.isRunning)
                    }
                    else -> result.notImplemented()
                }
            }

        // 2. Keyboard Platform Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, KEYBOARD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openKeyboardSettings" -> {
                        val intent = Intent(Settings.ACTION_INPUT_METHOD_SETTINGS).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
                        result.success(null)
                    }
                    "isKeyboardEnabled" -> {
                        val imm = getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
                        val enabledList = imm.enabledInputMethodList
                        val isEnabled = enabledList.any { it.packageName == packageName }
                        result.success(isEnabled)
                    }
                    "getDefaultMode" -> {
                        val mode = prefs.getString("default_mode", "standard") ?: "standard"
                        result.success(mode)
                    }
                    "setDefaultMode" -> {
                        val mode = call.argument<String>("mode") ?: "standard"
                        prefs.edit().putString("default_mode", mode).apply()
                        result.success(true)
                    }
                    "setCustomInstruction" -> {
                        val inst = call.argument<String>("instruction") ?: ""
                        prefs.edit().putString("custom_instruction", inst).apply()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
