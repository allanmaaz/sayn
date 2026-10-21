import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme.dart';

class LiveAudioWaveform extends StatefulWidget {
  final bool isRecording;
  final double audioLevel; // 0.0 to 1.0 (normalized RMS)
  final Color? activeColor;
  final Color? idleColor;
  final double height;
  final int barCount;

  const LiveAudioWaveform({
    super.key,
    required this.isRecording,
    required this.audioLevel,
    this.activeColor,
    this.idleColor,
    this.height = 42.0,
    this.barCount = 13,
  });

  @override
  State<LiveAudioWaveform> createState() => _LiveAudioWaveformState();
}

class _LiveAudioWaveformState extends State<LiveAudioWaveform>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathingController;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breathingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeClr = widget.activeColor ?? SaynColors.roseMaroon;
    final idleClr = widget.idleColor ?? SaynColors.darkSecondary.withValues(alpha: 0.35);

    return AnimatedBuilder(
      animation: _breathingController,
      builder: (context, _) {
        final breath = _breathingController.value;

        return SizedBox(
          height: widget.height,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(widget.barCount, (index) {
              final centerIdx = (widget.barCount - 1) / 2.0;
              final distFromCenter = (index - centerIdx).abs() / centerIdx; // 0.0 at center, 1.0 at edges
              // Bell curve weight (higher in the middle, tapering at sides)
              final bellWeight = math.cos(distFromCenter * math.pi / 2.2);

              double barHeight;
              if (widget.isRecording) {
                // If there's audio, scale with audioLevel + frequency wobble
                final level = widget.audioLevel;
                final wobble = math.sin((index * 0.8) + (breath * math.pi * 2)) * 0.15;
                final dynamicFactor = (level * 1.6 + 0.18 + wobble).clamp(0.12, 1.0);

                final minH = 6.0;
                final maxH = widget.height - 4.0;
                barHeight = minH + (maxH - minH) * bellWeight * dynamicFactor;
              } else {
                // Resting idle state
                barHeight = 4.0;
              }

              return AnimatedContainer(
                duration: const Duration(milliseconds: 75),
                curve: Curves.easeOutQuad,
                margin: const EdgeInsets.symmetric(horizontal: 2.2),
                width: 3.5,
                height: barHeight.clamp(3.0, widget.height),
                decoration: BoxDecoration(
                  color: widget.isRecording ? activeClr : idleClr,
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: widget.isRecording && widget.audioLevel > 0.25
                      ? [
                          BoxShadow(
                            color: activeClr.withValues(alpha: 0.35),
                            blurRadius: 4,
                            spreadRadius: 0.5,
                          ),
                        ]
                      : null,
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
