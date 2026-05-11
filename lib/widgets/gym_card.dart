import 'package:flutter/material.dart';
import '../models/gym_model.dart';
import '../theme/app_colors.dart';
import '../screens/gym_details_screen.dart'; // Add this import


class GymCard extends StatefulWidget {
  final Gym gym;

  const GymCard({super.key, required this.gym});

  @override
  State<GymCard> createState() => _GymCardState();
}

class _GymCardState extends State<GymCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to details page instead of expanding inline
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GymDetailsScreen(gymId: widget.gym.id),
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.fastOutSlowIn,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.gym.isSponsored
                ? AppColors.primary.withOpacity(0.5)
                : Colors.white10, // Subtle border for dark mode cards
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5), // Stronger shadow for depth in dark mode
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // --- TOP SECTION ---
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    bottomLeft: Radius.circular(_isExpanded ? 0 : 20),
                  ),
                  child: Image.network(
                    widget.gym.imageUrl,
                    width: 110,
                    height: 110,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _capitalize(widget.gym.name),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textMain,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (widget.gym.isVerified)
                              const Icon(Icons.verified_rounded, color: AppColors.verifiedIcon, size: 20),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.gym.address,
                          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, color: AppColors.accent, size: 18),
                                const SizedBox(width: 4),
                                Text(
                                  widget.gym.rating > 0 ? widget.gym.rating.toStringAsFixed(1) : 'New',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textMain,
                                  ),
                                ),
                              ],
                            ),
                            Icon(
                              _isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                              color: AppColors.primaryLight,
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),

            // --- BOTTOM SECTION ---
            AnimatedSize(
              duration: const Duration(milliseconds: 350),
              curve: Curves.fastOutSlowIn,
              child: _isExpanded
                  ? Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.expandedBg,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.gym.isSponsored) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: AppColors.sponsoredBg,
                            borderRadius: BorderRadius.circular(8)
                        ),
                        child: Text(
                          'SPONSORED',
                          style: TextStyle(color: AppColors.sponsoredText, fontSize: 11, fontWeight: FontWeight.bold)
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    _buildDetailRow(Icons.phone_rounded, widget.gym.phone),
                    const SizedBox(height: 10),
                    _buildDetailRow(Icons.email_rounded, widget.gym.email),
                  ],
                ),
              )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.2), // Red tinted background
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 14, color: AppColors.primaryLight),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.expandedText,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis
          ),
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 110,
      height: 110,
      color: Colors.black26, // Darker placeholder for dark mode
      child: Icon(Icons.fitness_center_rounded, color: AppColors.textMuted),
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) => word.isEmpty ? word : word[0].toUpperCase() + word.substring(1).toLowerCase()).join(' ');
  }
}