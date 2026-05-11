import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../theme/app_colors.dart';

class TypingIndicatorBubble extends StatefulWidget {
  const TypingIndicatorBubble({super.key});

  @override
  State<TypingIndicatorBubble> createState() => _TypingIndicatorBubbleState();
}

class _TypingIndicatorBubbleState extends State<TypingIndicatorBubble> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppColors.primaryLight.withOpacity(0.3), blurRadius: 8)]
            ),
            child: const CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.primaryLight,
                child: Icon(Icons.auto_awesome, size: 14, color: Colors.white)
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              border: Border.all(color: AppColors.borderColor),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                return AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final delay = index * 0.2;
                    double value = (_controller.value - delay) % 1.0;
                    if (value < 0) value += 1.0;

                    final offset = math.sin(value * math.pi * 2) * 4;
                    final opacity = 0.4 + (math.cos(value * math.pi * 2) * 0.5 + 0.5) * 0.6;

                    return Transform.translate(
                      offset: Offset(0, offset < 0 ? offset : 0),
                      child: Opacity(
                        opacity: opacity,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}