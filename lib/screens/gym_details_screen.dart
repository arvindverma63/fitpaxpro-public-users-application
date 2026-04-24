import 'package:flutter/material.dart';
import '../models/gym_model.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/gym/GymGalleryCarousel.dart';
import '../widgets/pricing_bottom_sheet.dart';

class GymDetailsScreen extends StatefulWidget {
  final String gymId;

  const GymDetailsScreen({super.key, required this.gymId});

  @override
  State<GymDetailsScreen> createState() => _GymDetailsScreenState();
}

class _GymDetailsScreenState extends State<GymDetailsScreen> {
  late Future<Gym> _futureGymDetails;
  final ApiService _apiService = ApiService();
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _futureGymDetails = _apiService.fetchGymDetails(widget.gymId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: FutureBuilder<Gym>(
        future: _futureGymDetails,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryLight));
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No data found.', style: TextStyle(color: Colors.white)));
          }

          final gym = snapshot.data!;
          return Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    _buildGalleryHeader(gym),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildCompactTitle(gym),
                            const SizedBox(height: 16),
                            _buildQuickStatsGrid(gym),
                            const SizedBox(height: 16),
                            _buildActionRow(gym),
                            const SizedBox(height: 24),
                            _buildSectionTitle('About'),
                            const SizedBox(height: 8),
                            Text(
                              gym.description,
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 14, height: 1.5),
                            ),
                            const SizedBox(height: 24),
                            _buildContactAndInfoCard(gym),
                            const SizedBox(height: 20), // Bottom scroll padding
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
              _buildStickyBottomBar(),
            ],
          );
        },
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildGalleryHeader(Gym gym) {
    return SliverAppBar(
      expandedHeight: 300.0,
      pinned: true,
      backgroundColor: AppColors.cardBg,
      // Professional back button overlay
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: Colors.black.withOpacity(0.5),
          child: IconButton(
            icon: const Padding(
              padding: EdgeInsets.only(right: 2.0), // Visually centers the iOS arrow
              child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: GymGalleryCarousel(images: gym.galleryImages),
      ),
    );
  }


  Widget _buildCompactTitle(Gym gym) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Using Wrap ensures badges don't overflow on small devices
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (gym.isSponsored) _buildBadge('Sponsored', AppColors.sponsoredBg, AppColors.sponsoredText, null),
            if (gym.isVerified) _buildBadge('Verified', AppColors.verifiedIcon.withOpacity(0.15), AppColors.verifiedIcon, Icons.verified_rounded),
            _buildBadge(gym.status.toUpperCase(), AppColors.cardBg, AppColors.textMuted, Icons.info_outline_rounded),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          _capitalize(gym.name),
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textMain, height: 1.2),
        ),
      ],
    );
  }

  Widget _buildBadge(String text, Color bgColor, Color textColor, IconData? icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.white10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, color: textColor, size: 12), const SizedBox(width: 4)],
          Text(text, style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildQuickStatsGrid(Gym gym) {
    return Row(
      children: [
        Expanded(child: _buildStatBox(Icons.star_rounded, gym.rating > 0 ? gym.rating.toStringAsFixed(1) : 'New', 'Rating')),
        const SizedBox(width: 12),
        Expanded(child: _buildStatBox(Icons.groups_rounded, gym.memberCountLimit?.toString() ?? '∞', 'Capacity')),
        const SizedBox(width: 12),
        Expanded(child: _buildStatBox(Icons.radar_rounded, '${gym.searchRadius} km', 'Radius')),
      ],
    );
  }

  Widget _buildStatBox(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primaryLight, size: 20),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: AppColors.textMain, fontSize: 14, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildActionRow(Gym gym) {
    return Row(
      children: [
        Expanded(child: _buildIconButton(Icons.call_rounded, 'Call', AppColors.primary, Colors.white)),
        const SizedBox(width: 12),
        Expanded(child: _buildIconButton(Icons.email_rounded, 'Email', AppColors.cardBg, AppColors.textMain)),
        const SizedBox(width: 12),
        Expanded(child: _buildIconButton(Icons.directions_rounded, 'Map', AppColors.cardBg, AppColors.textMain)),
      ],
    );
  }

  Widget _buildIconButton(IconData icon, String label, Color bgColor, Color textColor) {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 16, color: textColor),
      label: Text(label, style: TextStyle(fontSize: 13, color: textColor, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.white10)),
        elevation: 0,
      ),
    );
  }

  Widget _buildContactAndInfoCard(Gym gym) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          _buildListTile(Icons.location_on_rounded, 'Address', gym.address),
          const Divider(color: Colors.white10, height: 1),
          _buildListTile(Icons.phone_rounded, 'Phone', gym.phone),
          const Divider(color: Colors.white10, height: 1),
          _buildListTile(Icons.email_rounded, 'Email', gym.email),
          const Divider(color: Colors.white10, height: 1),
          _buildListTile(Icons.calendar_month_rounded, 'Registered On', gym.createdAt),
        ],
      ),
    );
  }

  Widget _buildListTile(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.textMuted, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: AppColors.textMain, fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: const Border(top: BorderSide(color: Colors.white10)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Trigger the professional bottom sheet
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true, // Allows sheet to size itself to content
                      backgroundColor: Colors.transparent,
                      builder: (context) => PricingBottomSheet(gymId: widget.gymId),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('View Plans & Pricing', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMain));
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) => word.isEmpty ? word : word[0].toUpperCase() + word.substring(1).toLowerCase()).join(' ');
  }
}