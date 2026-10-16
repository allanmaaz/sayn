import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';
import '../../services/platform_channels.dart';
import '../../core/api_client.dart';

class VoiceFlowScreen extends StatefulWidget {
  const VoiceFlowScreen({super.key});

  @override
  State<VoiceFlowScreen> createState() => _VoiceFlowScreenState();
}

class _VoiceFlowScreenState extends State<VoiceFlowScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _testInputController = TextEditingController();
  final SaynApiClient _apiClient = SaynApiClient();

  late AnimationController _pulseController;
  bool _isDictating = false;
  bool _isPolishing = false;
  String _selectedTone = 'standard';
  String _polishedResult = '';
  int _lastLatencyMs = 0;
  bool _copied = false;
  bool _overlayActive = false;
  bool _keyboardActive = false;

  final List<Map<String, String>> _tones = const [
    {'id': 'standard', 'label': 'Standard'},
    {'id': 'professional', 'label': 'Professional'},
    {'id': 'casual', 'label': 'Casual'},
    {'id': 'concise', 'label': 'Concise'},
    {'id': 'formal', 'label': 'Formal'},
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _checkSystemStatus();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _testInputController.dispose();
    super.dispose();
  }

  Future<void> _checkSystemStatus() async {
    final overlayRunning = await PlatformChannels.isOverlayRunning();
    final keyboardEnabled = await PlatformChannels.isKeyboardEnabled();
    if (mounted) {
      setState(() {
        _overlayActive = overlayRunning;
        _keyboardActive = keyboardEnabled;
      });
    }
  }

  Future<void> _runPolishTest() async {
    final rawText = _testInputController.text.trim();
    if (rawText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter or speak a phrase to test polishing.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isPolishing = true;
      _polishedResult = '';
    });

    final stopwatch = Stopwatch()..start();

    try {
      final res = await _apiClient.refineText(
        text: rawText,
        mode: _selectedTone,
      );
      stopwatch.stop();

      if (mounted) {
        setState(() {
          _polishedResult = res['refinedText'] ?? rawText;
          _lastLatencyMs = stopwatch.elapsedMilliseconds;
        });
      }
    } catch (_) {
      // Offline fallback: deterministic local cleanup
      stopwatch.stop();
      if (mounted) {
        setState(() {
          _polishedResult = _cleanLocalFallback(rawText);
          _lastLatencyMs = stopwatch.elapsedMilliseconds;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isPolishing = false);
      }
    }
  }

  String _cleanLocalFallback(String text) {
    var s = text.replaceAll(
        RegExp(r'(?i)\b(um+|uh+|er+|ah+|basically|you know|literally)\b,?\s*'),
        '');
    s = s.replaceAll(
        RegExp(r'(?i)\b(\w+)\s+(?:no wait|wait no|actually)\s+(\w+)\b'),
        r'$2');
    s = s.trim();
    if (s.isNotEmpty) {
      s = s[0].toUpperCase() + s.substring(1);
      if (!s.endsWith('.') && !s.endsWith('!') && !s.endsWith('?')) {
        s += '.';
      }
    }
    return s;
  }

  void _copyResult() {
    if (_polishedResult.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _polishedResult));
      setState(() => _copied = true);
      HapticFeedback.lightImpact();
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _copied = false);
      });
    }
  }

  void _loadSampleSpeech() {
    _testInputController.text =
        "um so basically we need to finish the meeting at 2 no wait 3 pm tomorrow you know";
    _runPolishTest();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SaynColors.darkBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card with Wispr Flow Status
              _buildHeaderStatusCard(),
              const SizedBox(height: 16),

              // Interactive Mic & Dictation Hub
              _buildVoiceMicCard(),
              const SizedBox(height: 16),

              // Tone Selectors
              _buildToneSelector(),
              const SizedBox(height: 16),

              // Test Input & Direct Polishing Sandbox
              _buildTestInputBox(),
              const SizedBox(height: 16),

              // Polished Output Result
              if (_polishedResult.isNotEmpty || _isPolishing) ...[
                _buildPolishedResultCard(),
                const SizedBox(height: 16),
              ],

              // System Assistant Status & Toggles
              _buildSystemControlsCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SaynColors.darkSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SaynColors.darkDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: SaynColors.darkAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: SaynColors.darkAccent.withOpacity(0.4),
                      ),
                    ),
                    child: const Icon(
                      Icons.graphic_eq_rounded,
                      color: SaynColors.darkAccent,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SAN VOICE ENGINE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: SaynColors.darkText,
                        ),
                      ),
                      Text(
                        'Sub-500ms Instantaneous Speech',
                        style: TextStyle(
                          fontSize: 11,
                          color: SaynColors.darkSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: SaynColors.darkAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: SaynColors.darkAccent.withOpacity(0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: SaynColors.darkAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'UNLIMITED LPU',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: SaynColors.darkAccent,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: SaynColors.darkDivider, height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.bolt_rounded, size: 14, color: SaynColors.darkAccent),
              const SizedBox(width: 6),
              const Text(
                'Groq Whisper Turbo + Qwen 3.8 27B',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: SaynColors.darkText,
                ),
              ),
              const Spacer(),
              Text(
                _lastLatencyMs > 0 ? 'Last: ${_lastLatencyMs}ms' : 'Ready',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: SaynColors.darkAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceMicCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: SaynColors.darkSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: SaynColors.darkDivider),
      ),
      child: Column(
        children: [
          // Glowing Pulse Mic Button
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final scale = _isDictating
                  ? 1.0 + (_pulseController.value * 0.12)
                  : 1.0;
              return Transform.scale(
                scale: scale,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.heavyImpact();
                    setState(() => _isDictating = !_isDictating);
                    if (_isDictating) {
                      _loadSampleSpeech();
                    }
                  },
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isDictating
                          ? SaynColors.darkAccent
                          : SaynColors.darkSurface2,
                      border: Border.all(
                        color: SaynColors.darkAccent,
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: SaynColors.darkAccent
                              .withOpacity(_isDictating ? 0.45 : 0.15),
                          blurRadius: _isDictating ? 30 : 14,
                          spreadRadius: _isDictating ? 4 : 0,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isDictating ? Icons.mic : Icons.mic_none_rounded,
                      color: _isDictating
                          ? const Color(0xFF0D0D12)
                          : SaynColors.darkAccent,
                      size: 38,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 18),
          Text(
            _isDictating ? 'Listening... Speak Naturally' : 'Tap to Test Voice Dictation',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: _isDictating ? SaynColors.darkAccent : SaynColors.darkText,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Zero filler words • Instant auto-paste • No transcription delay',
            style: TextStyle(
              fontSize: 11.5,
              color: SaynColors.darkSecondary,
            ),
          ),
          const SizedBox(height: 14),
          // Animated Waveform Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(11, (index) {
              final heights = [10.0, 16.0, 26.0, 18.0, 32.0, 40.0, 32.0, 20.0, 24.0, 14.0, 8.0];
              final h = _isDictating ? heights[index] : 4.0;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                width: 3.5,
                height: h,
                decoration: BoxDecoration(
                  color: SaynColors.darkAccent,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildToneSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'POLISHING TONE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: SaynColors.darkSecondary,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _tones.map((tone) {
              final isSelected = _selectedTone == tone['id'];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(tone['label']!),
                  selected: isSelected,
                  selectedColor: SaynColors.darkAccent,
                  backgroundColor: SaynColors.darkSurface2,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? const Color(0xFF0D0D12)
                        : SaynColors.darkSecondary,
                  ),
                  side: BorderSide(
                    color: isSelected
                        ? SaynColors.darkAccent
                        : SaynColors.darkDivider,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  onSelected: (val) {
                    if (val) {
                      setState(() => _selectedTone = tone['id']!);
                      if (_testInputController.text.isNotEmpty) {
                        _runPolishTest();
                      }
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTestInputBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SaynColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SaynColors.darkDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'RAW SPEECH / INPUT',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: SaynColors.darkSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              TextButton(
                onPressed: _loadSampleSpeech,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Load Sample',
                  style: TextStyle(
                    fontSize: 11,
                    color: SaynColors.darkAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _testInputController,
            maxLines: 3,
            style: const TextStyle(fontSize: 13.5, color: SaynColors.darkText),
            decoration: const InputDecoration(
              hintText: 'Type or paste raw spoken words here with fillers...',
              hintStyle: TextStyle(color: SaynColors.darkMuted, fontSize: 13),
              border: InputBorder.none,
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _isPolishing ? null : _runPolishTest,
              icon: _isPolishing
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF0D0D12),
                      ),
                    )
                  : const Icon(Icons.auto_awesome, size: 16),
              label: Text(
                _isPolishing ? 'Polishing...' : 'Polish Instantaneously',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: SaynColors.darkAccent,
                foregroundColor: const Color(0xFF0D0D12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolishedResultCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SaynColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: SaynColors.darkAccent.withOpacity(0.5),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: SaynColors.darkAccent,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'POLISHED OUTPUT',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: SaynColors.darkAccent,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              if (_lastLatencyMs > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: SaynColors.darkSurface2,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_lastLatencyMs}ms',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: SaynColors.darkAccent,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          SelectableText(
            _polishedResult.isEmpty ? 'Processing...' : _polishedResult,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              color: SaynColors.darkText,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: _copyResult,
                icon: Icon(
                  _copied ? Icons.check : Icons.copy_rounded,
                  size: 14,
                  color: _copied ? SaynColors.darkAccent : SaynColors.darkText,
                ),
                label: Text(
                  _copied ? 'Copied' : 'Copy Text',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _copied ? SaynColors.darkAccent : SaynColors.darkText,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: _copied
                        ? SaynColors.darkAccent
                        : SaynColors.darkDivider,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSystemControlsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SaynColors.darkSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SaynColors.darkDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SYSTEM-WIDE INTEGRATIONS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: SaynColors.darkSecondary,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 12),
          // Floating Bubble Status
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _overlayActive
                    ? SaynColors.darkAccent.withOpacity(0.15)
                    : SaynColors.darkSurface2,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.layers_rounded,
                color: _overlayActive
                    ? SaynColors.darkAccent
                    : SaynColors.darkSecondary,
                size: 20,
              ),
            ),
            title: const Text(
              'Floating Capsule Overlay',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              _overlayActive ? 'Active over WhatsApp, Slack, Gmail' : 'Stopped',
              style: const TextStyle(fontSize: 11, color: SaynColors.darkSecondary),
            ),
            trailing: Switch.adaptive(
              value: _overlayActive,
              activeColor: SaynColors.darkAccent,
              onChanged: (val) async {
                if (val) {
                  final ok = await PlatformChannels.startFloatingAssistant();
                  setState(() => _overlayActive = ok);
                } else {
                  final stopped = await PlatformChannels.stopFloatingAssistant();
                  setState(() => _overlayActive = !stopped);
                }
              },
            ),
          ),
          const Divider(color: SaynColors.darkDivider, height: 16),
          // Smart Keyboard Status
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _keyboardActive
                    ? SaynColors.darkAccent.withOpacity(0.15)
                    : SaynColors.darkSurface2,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.keyboard_rounded,
                color: _keyboardActive
                    ? SaynColors.darkAccent
                    : SaynColors.darkSecondary,
                size: 20,
              ),
            ),
            title: const Text(
              'Smart Keyboard (IME)',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              _keyboardActive ? 'Enabled in system settings' : 'Tap to enable',
              style: const TextStyle(fontSize: 11, color: SaynColors.darkSecondary),
            ),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: SaynColors.darkSecondary,
            ),
            onTap: () async {
              await PlatformChannels.openKeyboardSettings();
              _checkSystemStatus();
            },
          ),
        ],
      ),
    );
  }
}
