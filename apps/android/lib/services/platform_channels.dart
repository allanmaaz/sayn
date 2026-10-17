import 'package:flutter/services.dart';

class PlatformChannels {
  static const MethodChannel _overlayChannel =
      MethodChannel('com.sayn.app/overlay');
  static const MethodChannel _keyboardChannel =
      MethodChannel('com.sayn.app/keyboard');

  // Overlay Methods
  static Future<bool> checkOverlayPermission() async {
    try {
      final bool hasPermission =
          await _overlayChannel.invokeMethod('checkOverlayPermission');
      return hasPermission;
    } catch (_) {
      return false;
    }
  }

  static Future<void> requestOverlayPermission() async {
    try {
      await _overlayChannel.invokeMethod('requestOverlayPermission');
    } catch (_) {}
  }

  static Future<bool> startFloatingAssistant() async {
    try {
      final bool started =
          await _overlayChannel.invokeMethod('startFloatingAssistant');
      return started;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> stopFloatingAssistant() async {
    try {
      final bool stopped =
          await _overlayChannel.invokeMethod('stopFloatingAssistant');
      return stopped;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> isOverlayRunning() async {
    try {
      final bool running = await _overlayChannel.invokeMethod('isOverlayRunning');
      return running;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> checkAccessibilityPermission() async {
    try {
      final bool connected =
          await _overlayChannel.invokeMethod('checkAccessibilityPermission') ?? false;
      return connected;
    } catch (_) {
      return false;
    }
  }

  static Future<void> openAccessibilitySettings() async {
    try {
      await _overlayChannel.invokeMethod('openAccessibilitySettings');
    } catch (_) {}
  }

  static Future<void> openAppDetailsSettings() async {
    try {
      await _overlayChannel.invokeMethod('openAppDetailsSettings');
    } catch (_) {}
  }

  // Keyboard Methods
  static Future<void> openKeyboardSettings() async {
    try {
      await _keyboardChannel.invokeMethod('openKeyboardSettings');
    } catch (_) {}
  }

  static Future<bool> isKeyboardEnabled() async {
    try {
      final bool enabled =
          await _keyboardChannel.invokeMethod('isKeyboardEnabled');
      return enabled;
    } catch (_) {
      return false;
    }
  }

  static Future<String> getDefaultMode() async {
    try {
      final String mode = await _keyboardChannel.invokeMethod('getDefaultMode') ?? 'standard';
      return mode;
    } catch (_) {
      return 'standard';
    }
  }

  static Future<void> setDefaultMode(String mode) async {
    try {
      await _keyboardChannel.invokeMethod('setDefaultMode', {'mode': mode});
    } catch (_) {}
  }

  static Future<bool> checkAudioPermission() async {
    try {
      final bool hasMic = await _keyboardChannel.invokeMethod('checkAudioPermission');
      return hasMic;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> isMicrophonePermissionGranted() => checkAudioPermission();

  static Future<void> requestAudioPermission() async {
    try {
      await _keyboardChannel.invokeMethod('requestAudioPermission');
    } catch (_) {}
  }

  static Future<void> requestMicrophonePermission() => requestAudioPermission();

  static Future<Map<String, dynamic>> getKeyboardFeedbackSettings() async {
    try {
      final res = await _keyboardChannel.invokeMethod('getKeyboardFeedbackSettings');
      if (res is Map) {
        return Map<String, dynamic>.from(res);
      }
      return {
        'soundEnabled': true,
        'vibrationEnabled': true,
        'vibrationIntensity': 'medium',
        'autoCorrectEnabled': true,
      };
    } catch (_) {
      return {
        'soundEnabled': true,
        'vibrationEnabled': true,
        'vibrationIntensity': 'medium',
        'autoCorrectEnabled': true,
      };
    }
  }

  static Future<void> setKeyboardFeedbackSettings({
    required bool soundEnabled,
    required bool vibrationEnabled,
    required String vibrationIntensity,
    bool? autoCorrectEnabled,
  }) async {
    try {
      await _keyboardChannel.invokeMethod('setKeyboardFeedbackSettings', {
        'soundEnabled': soundEnabled,
        'vibrationEnabled': vibrationEnabled,
        'vibrationIntensity': vibrationIntensity,
        if (autoCorrectEnabled != null) 'autoCorrectEnabled': autoCorrectEnabled,
      });
    } catch (_) {}
  }

  // ─────────────────────────────────────────────────────────────────────────
  // In-App Auto-Updater Methods
  // ─────────────────────────────────────────────────────────────────────────
  static const MethodChannel _updaterChannel =
      MethodChannel('com.sayn.app/updater');

  static void setUpdaterListener({
    Function(int progress)? onProgress,
    Function(String filePath)? onComplete,
    Function(String error)? onError,
  }) {
    _updaterChannel.setMethodCallHandler((call) async {
      if (call.method == 'onDownloadProgress') {
        final int progress = (call.arguments['progress'] as num?)?.toInt() ?? 0;
        onProgress?.call(progress);
      } else if (call.method == 'onDownloadComplete') {
        final String filePath = call.arguments['filePath'] ?? '';
        onComplete?.call(filePath);
      } else if (call.method == 'onDownloadError') {
        final String error = call.arguments['error'] ?? 'Download failed';
        onError?.call(error);
      }
    });
  }

  static Future<String> getAppVersion() async {
    try {
      final String version = await _updaterChannel.invokeMethod('getAppVersion') ?? '1.0.3';
      return version;
    } catch (_) {
      return '1.0.3';
    }
  }

  static Future<bool> canRequestPackageInstalls() async {
    try {
      final bool canInstall = await _updaterChannel.invokeMethod('canRequestPackageInstalls') ?? true;
      return canInstall;
    } catch (_) {
      return true;
    }
  }

  static Future<void> openInstallPermissionSettings() async {
    try {
      await _updaterChannel.invokeMethod('openInstallPermissionSettings');
    } catch (_) {}
  }

  static Future<bool> downloadAndInstallApk(String url) async {
    try {
      final bool started = await _updaterChannel.invokeMethod('downloadAndInstallApk', {'url': url}) ?? false;
      return started;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> installApkFile(String filePath) async {
    try {
      final bool success = await _updaterChannel.invokeMethod('installApkFile', {'filePath': filePath}) ?? false;
      return success;
    } catch (_) {
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Real-Time Speech Recognition Channel
  // ─────────────────────────────────────────────────────────────────────────
  static const MethodChannel _speechChannel =
      MethodChannel('com.sayn.app/speech');

  static void setSpeechListener({
    Function(String partialText)? onPartialResult,
    Function(String finalText)? onFinalResult,
    Function(String error)? onError,
    Function()? onEndOfSpeech,
  }) {
    _speechChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onPartialResult':
          final text = call.arguments['text'] as String? ?? '';
          onPartialResult?.call(text);
          break;
        case 'onFinalResult':
          final text = call.arguments['text'] as String? ?? '';
          onFinalResult?.call(text);
          break;
        case 'onEndOfSpeech':
          onEndOfSpeech?.call();
          break;
        case 'onError':
          final error = call.arguments['error'] as String? ?? '';
          onError?.call(error);
          break;
      }
    });
  }

  static Future<bool> startDictation() async {
    try {
      final bool started = await _speechChannel.invokeMethod('startDictation') ?? false;
      return started;
    } catch (_) {
      return false;
    }
  }

  static Future<void> stopDictation() async {
    try {
      await _speechChannel.invokeMethod('stopDictation');
    } catch (_) {}
  }
}
