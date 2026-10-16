package com.sayn.app

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.view.inputmethod.InputMethodManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import com.sayn.app.overlay.FloatingBubbleService
import com.sayn.app.overlay.OverlayPermissionHelper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File
import java.io.FileOutputStream
import java.net.HttpURLConnection
import java.net.URL

class MainActivity : FlutterActivity() {

    private val OVERLAY_CHANNEL = "com.sayn.app/overlay"
    private val KEYBOARD_CHANNEL = "com.sayn.app/keyboard"
    private val UPDATER_CHANNEL = "com.sayn.app/updater"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        checkAndRequestAudioPermission()
    }

    override fun onResume() {
        super.onResume()
        if (intent?.getBooleanExtra("request_mic_permission", false) == true) {
            checkAndRequestAudioPermission()
        }
    }

    private fun checkAndRequestAudioPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
                ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.RECORD_AUDIO), 101)
            }
        }
    }

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
                    "checkAccessibilityPermission" -> {
                        result.success(com.sayn.app.service.SaynAccessibilityService.isConnected)
                    }
                    "openAccessibilitySettings" -> {
                        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
                        result.success(null)
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
                    "checkAudioPermission" -> {
                        val hasMic = ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED
                        result.success(hasMic)
                    }
                    "requestAudioPermission" -> {
                        checkAndRequestAudioPermission()
                        result.success(true)
                    }
                    "setCustomInstruction" -> {
                        val inst = call.argument<String>("instruction") ?: ""
                        prefs.edit().putString("custom_instruction", inst).apply()
                        result.success(true)
                    }
                    "getKeyboardFeedbackSettings" -> {
                        val sound = prefs.getBoolean("key_sound_enabled", true)
                        val vib = prefs.getBoolean("key_vibration_enabled", true)
                        val intensity = prefs.getString("key_vibration_intensity", "medium") ?: "medium"
                        val autoCorrect = prefs.getBoolean("keyboard_autocorrect_enabled", true)
                        result.success(mapOf(
                            "soundEnabled" to sound,
                            "vibrationEnabled" to vib,
                            "vibrationIntensity" to intensity,
                            "autoCorrectEnabled" to autoCorrect
                        ))
                    }
                    "setKeyboardFeedbackSettings" -> {
                        val sound = call.argument<Boolean>("soundEnabled") ?: true
                        val vib = call.argument<Boolean>("vibrationEnabled") ?: true
                        val intensity = call.argument<String>("vibrationIntensity") ?: "medium"
                        val autoCorrect = call.argument<Boolean>("autoCorrectEnabled") ?: true
                        prefs.edit()
                            .putBoolean("key_sound_enabled", sound)
                            .putBoolean("key_vibration_enabled", vib)
                            .putString("key_vibration_intensity", intensity)
                            .putBoolean("keyboard_autocorrect_enabled", autoCorrect)
                            .apply()
                        com.sayn.app.keyboard.SaynInputMethodService.instance?.reloadFeedbackSettings()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        // 3. In-App Auto-Updater Platform Channel
        val updaterChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, UPDATER_CHANNEL)
        updaterChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "getAppVersion" -> {
                    try {
                        val pInfo = packageManager.getPackageInfo(packageName, 0)
                        result.success(pInfo.versionName)
                    } catch (e: Exception) {
                        result.success("1.0.3")
                    }
                }
                "canRequestPackageInstalls" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        result.success(packageManager.canRequestPackageInstalls())
                    } else {
                        result.success(true)
                    }
                }
                "openInstallPermissionSettings" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        val intent = Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES).apply {
                            data = Uri.parse("package:$packageName")
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
                    }
                    result.success(null)
                }
                "downloadAndInstallApk" -> {
                    val urlString = call.argument<String>("url") ?: run {
                        result.error("INVALID_URL", "Download URL is required", null)
                        return@setMethodCallHandler
                    }

                    result.success(true)

                    CoroutineScope(Dispatchers.IO).launch {
                        try {
                            var currentUrl = urlString
                            var connection: HttpURLConnection
                            var redirectCount = 0

                            // Handle HTTP 301/302/307 redirects (GitHub Releases redirect to AWS S3 CDN)
                            while (true) {
                                val url = URL(currentUrl)
                                connection = url.openConnection() as HttpURLConnection
                                connection.instanceFollowRedirects = true
                                connection.connectTimeout = 15000
                                connection.readTimeout = 30000
                                connection.connect()

                                val code = connection.responseCode
                                if ((code == HttpURLConnection.HTTP_MOVED_TEMP ||
                                     code == HttpURLConnection.HTTP_MOVED_PERM ||
                                     code == 307 || code == 308) && redirectCount < 5) {
                                    val loc = connection.getHeaderField("Location")
                                    if (!loc.isNullOrEmpty()) {
                                        currentUrl = loc
                                        redirectCount++
                                        continue
                                    }
                                }
                                break
                            }

                            val totalLength = connection.contentLength
                            val outputFile = File(cacheDir, "sayn-update.apk")
                            if (outputFile.exists()) {
                                outputFile.delete()
                            }

                            connection.inputStream.use { input ->
                                FileOutputStream(outputFile).use { output ->
                                    val buffer = ByteArray(8192)
                                    var bytesRead: Int
                                    var downloaded = 0L
                                    var lastReport = -1

                                    while (input.read(buffer).also { bytesRead = it } != -1) {
                                        output.write(buffer, 0, bytesRead)
                                        downloaded += bytesRead
                                        if (totalLength > 0) {
                                            val progress = ((downloaded * 100) / totalLength).toInt()
                                            if (progress != lastReport && progress % 2 == 0) {
                                                lastReport = progress
                                                withContext(Dispatchers.Main) {
                                                    updaterChannel.invokeMethod("onDownloadProgress", mapOf("progress" to progress))
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            withContext(Dispatchers.Main) {
                                updaterChannel.invokeMethod("onDownloadComplete", mapOf("filePath" to outputFile.absolutePath))
                                launchInstallIntent(outputFile)
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                updaterChannel.invokeMethod("onDownloadError", mapOf("error" to (e.message ?: "Download failed")))
                            }
                        }
                    }
                }
                "installApkFile" -> {
                    val filePath = call.argument<String>("filePath")
                    if (filePath != null) {
                        launchInstallIntent(File(filePath))
                        result.success(true)
                    } else {
                        result.error("FILE_MISSING", "File path missing", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun launchInstallIntent(file: File) {
        try {
            val apkUri = FileProvider.getUriForFile(this, "$packageName.fileprovider", file)
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(apkUri, "application/vnd.android.package-archive")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
