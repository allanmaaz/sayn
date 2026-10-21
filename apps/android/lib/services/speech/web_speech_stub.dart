class WebSpeechHelper {
  bool get isSupported => false;
  bool get isListening => false;

  Future<bool> start({
    required Function(String partial) onPartial,
    required Function(String finalText) onFinal,
    required Function(double level) onAudioLevel,
    required Function(String error) onError,
    required Function() onEnd,
  }) async {
    return false;
  }

  void stop() {}
}
