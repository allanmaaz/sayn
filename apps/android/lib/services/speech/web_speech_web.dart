import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:math' as math;
import 'dart:typed_data';

class WebSpeechHelper {
  html.SpeechRecognition? _recognition;
  html.MediaStream? _mediaStream;
  dynamic _audioContext;
  dynamic _analyser;
  Timer? _levelTimer;
  bool _isListening = false;
  String _accumulatedFinal = '';

  bool get isSupported => html.SpeechRecognition.supported;
  bool get isListening => _isListening;

  Future<bool> start({
    required Function(String partial) onPartial,
    required Function(String finalText) onFinal,
    required Function(double level) onAudioLevel,
    required Function(String error) onError,
    required Function() onEnd,
  }) async {
    if (!isSupported) {
      onError('Web Speech API is not supported in this browser. Please use Chrome.');
      return false;
    }

    try {
      _stopAudioAnalyser();
      _recognition?.abort();
      _accumulatedFinal = '';

      _recognition = html.SpeechRecognition()
        ..continuous = true
        ..interimResults = true
        ..lang = 'en-US';

      _recognition!.onResult.listen((event) {
        final results = event.results;
        if (results == null) return;
        String currentInterim = '';
        for (var i = event.resultIndex ?? 0; i < results.length; i++) {
          final item = results[i];
          final transcript = item.item(0).transcript ?? '';
          if (item.isFinal == true) {
            _accumulatedFinal += (_accumulatedFinal.isEmpty ? '' : ' ') + transcript.trim();
          } else {
            currentInterim += transcript;
          }
        }
        if (currentInterim.isNotEmpty) {
          final full = _accumulatedFinal.isEmpty ? currentInterim : '$_accumulatedFinal $currentInterim';
          onPartial(full.trim());
        } else if (_accumulatedFinal.isNotEmpty) {
          onPartial(_accumulatedFinal.trim());
        }
      });

      _recognition!.onError.listen((event) {
        final error = event.error ?? 'Speech recognition error';
        if (error != 'no-speech') {
          onError('Microphone input note: $error');
        }
      });

      _recognition!.onEnd.listen((_) {
        _isListening = false;
        _stopAudioAnalyser();
        if (_accumulatedFinal.isNotEmpty) {
          onFinal(_accumulatedFinal.trim());
        }
        onEnd();
      });

      _recognition!.start();
      _isListening = true;

      // Start live audio RMS level measurement with software gain
      await _startAudioAnalyser(onAudioLevel);

      return true;
    } catch (e) {
      _isListening = false;
      _stopAudioAnalyser();
      onError('Could not start laptop microphone: $e');
      return false;
    }
  }

  Future<void> _startAudioAnalyser(Function(double level) onAudioLevel) async {
    try {
      _mediaStream = await html.window.navigator.mediaDevices?.getUserMedia({'audio': true});
      if (_mediaStream != null) {
        final audioContextConstructor = js.context['AudioContext'] ?? js.context['webkitAudioContext'];
        if (audioContextConstructor != null) {
          _audioContext = js.JsObject(audioContextConstructor as js.JsFunction, []);
          final source = _audioContext.callMethod('createMediaStreamSource', [_mediaStream]);
          _analyser = _audioContext.callMethod('createAnalyser', []);
          _analyser['fftSize'] = 64;
          source.callMethod('connect', [_analyser]);

          final data = Uint8List(32);
          _levelTimer = Timer.periodic(const Duration(milliseconds: 60), (_) {
            if (!_isListening || _analyser == null) return;
            try {
              _analyser.callMethod('getByteTimeDomainData', [data]);
              double sumSquares = 0.0;
              for (var i = 0; i < data.length; i++) {
                final norm = (data[i] - 128) / 128.0;
                sumSquares += norm * norm;
              }
              final rms = math.sqrt(sumSquares / data.length);
              // Apply a 3.5x boost curve so normal voice moves the waveform vibrantly
              final boosted = (rms * 3.5).clamp(0.0, 1.0);
              onAudioLevel(boosted);
            } catch (_) {}
          });
        }
      }
    } catch (_) {
      // AudioContext failure should not block speech recognition
    }
  }

  void stop() {
    _isListening = false;
    _stopAudioAnalyser();
    try {
      _recognition?.stop();
    } catch (_) {}
  }

  void _stopAudioAnalyser() {
    _levelTimer?.cancel();
    _levelTimer = null;
    try {
      _mediaStream?.getTracks().forEach((t) => t.stop());
    } catch (_) {}
    _mediaStream = null;
    try {
      _audioContext?.callMethod('close', []);
    } catch (_) {}
    _audioContext = null;
    _analyser = null;
  }
}
