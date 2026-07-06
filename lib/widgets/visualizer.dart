import 'dart:math';
import 'package:flutter/material.dart';

class AudioVisualizer extends StatefulWidget {
  final bool isPlaying;
  final Color color;
  final int barCount;
  final double height;
  final double width;

  const AudioVisualizer({
    super.key,
    required this.isPlaying,
    this.color = Colors.white,
    this.barCount = 9,
    this.height = 40.0,
    this.width = 50.0,
  });

  @override
  State<AudioVisualizer> createState() => _AudioVisualizerState();
}

class _AudioVisualizerState extends State<AudioVisualizer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<double> _amplitudes = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    // Initialize random amplitudes for each bar
    for (int i = 0; i < widget.barCount; i++) {
      _amplitudes.add(_random.nextDouble());
    }

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    if (widget.isPlaying) {
      _controller.repeat(reverse: true);
    }

    _controller.addListener(() {
      if (widget.isPlaying) {
        setState(() {
          for (int i = 0; i < widget.barCount; i++) {
            // Keep update frequency dynamic and smooth
            if (_random.nextDouble() > 0.4) {
              _amplitudes[i] = _random.nextDouble();
            }
          }
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant AudioVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        // Reset amplitudes to resting state
        setState(() {
          for (int i = 0; i < widget.barCount; i++) {
            _amplitudes[i] = 0.15;
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double barWidth = (widget.width - (widget.barCount - 1) * 2.0) / widget.barCount;
    
    return SizedBox(
      height: widget.height,
      width: widget.width,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(widget.barCount, (index) {
          final double amplitude = widget.isPlaying ? _amplitudes[index] : 0.15;
          final double currentBarHeight = max(4.0, amplitude * widget.height);
          
          return AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeInOut,
            width: barWidth,
            height: currentBarHeight,
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(barWidth / 2),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withOpacity(0.4),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
