import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';



class GymGalleryCarousel extends StatefulWidget {
  final List<String> images;

  const GymGalleryCarousel({super.key, required this.images});

  @override
  State<GymGalleryCarousel> createState() => _GymGalleryCarouselState();
}

class _GymGalleryCarouselState extends State<GymGalleryCarousel> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return Container(
        color: AppColors.cardBg,
        child: const Center(
          child: Icon(Icons.fitness_center_rounded, color: Colors.white24, size: 60),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. The Swipable Images
        PageView.builder(
          controller: _pageController,
          physics: const BouncingScrollPhysics(), // Gives a nice bounce effect at the ends
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          itemCount: widget.images.length,
          itemBuilder: (context, index) {
            return Image.network(
              widget.images[index],
              fit: BoxFit.cover,
              errorBuilder: (ctx, err, stack) => Container(
                color: AppColors.cardBg,
                child: const Icon(Icons.broken_image_rounded, color: Colors.white24, size: 50),
              ),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: AppColors.cardBg,
                  child: const Center(
                    child: CircularProgressIndicator(color: AppColors.primaryLight, strokeWidth: 2),
                  ),
                );
              },
            );
          },
        ),

        // 2. The Gradient Overlay (Wrapped in IgnorePointer!)
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                    Colors.black.withOpacity(0.8)
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
        ),

        // 3. Modern Pill Counter (e.g., "1 / 5")
        Positioned(
          bottom: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24, width: 0.5),
            ),
            child: Text(
              '${_currentIndex + 1} / ${widget.images.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ),

        // 4. Interactive Dot Indicators
        Positioned(
          bottom: 22,
          left: 0,
          right: 0,
          child: IgnorePointer( // Also ignore pointer here just in case
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.images.length,
                    (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  height: 6,
                  width: _currentIndex == index ? 20 : 6,
                  decoration: BoxDecoration(
                    color: _currentIndex == index ? AppColors.primaryLight : Colors.white54,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}