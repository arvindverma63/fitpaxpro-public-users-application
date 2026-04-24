import 'package:flutter/material.dart';

class PromoBanner {
  final String id;
  final String badgeText;
  final String title;
  final Color backgroundColor;
  final String imageUrl;
  final String targetLink;

  PromoBanner({
    required this.id,
    required this.badgeText,
    required this.title,
    required this.backgroundColor,
    required this.imageUrl,
    required this.targetLink,
  });

  factory PromoBanner.fromJson(Map<String, dynamic> json) {
    // Convert hex string (e.g., "#FF5733") to Flutter Color
    String hexString = json['background_color_hex'] ?? '#3730A3';
    hexString = hexString.replaceAll('#', '');
    if (hexString.length == 6) {
      hexString = 'FF$hexString'; // Add 100% opacity
    }

    // Construct full image URL
    String rawImageUrl = json['image_url'] ?? '';
    String fullImageUrl = rawImageUrl.startsWith('http')
        ? rawImageUrl
        : 'https://chocolate-viper-895188.hostingersite.com/storage/$rawImageUrl';

    return PromoBanner(
      id: json['id'] ?? '',
      badgeText: json['badge_text'] ?? 'PROMO',
      title: json['title'] ?? '',
      backgroundColor: Color(int.parse(hexString, radix: 16)),
      imageUrl: fullImageUrl,
      targetLink: json['target_link'] ?? '',
    );
  }
}