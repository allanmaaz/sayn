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

  static Future<void> requestAudioPermission() async {
    try {
      await _keyboardChannel.invokeMethod('requestAudioPermission');
    } catch (_) {}
  }
}
