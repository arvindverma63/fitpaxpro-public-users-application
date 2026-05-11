import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../services/theme_service.dart';
import 'settings_screen.dart';
import 'profile_info_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String? token;

  const ProfileScreen({super.key, this.token});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  String _firstName = '';
  String? _profileImageUrl;
  bool _isLoading = true;

  bool get _isLoggedIn => widget.token != null && widget.token!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (_isLoggedIn) {
      _loadProfile();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _loadProfile() async {
    final userData = await _apiService.fetchUserProfile(widget.token!);
    if (mounted && userData != null) {
      setState(() {
        _firstName = userData['first_name'] ?? 'User';
        _profileImageUrl = userData['profile_image'];
        _isLoading = false;
      });
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  if (_isLoggedIn) _buildUserCard() else _buildGuestCard(),
                  const SizedBox(height: 30),
                  _buildSectionHeader('Account Settings'),
                  const SizedBox(height: 10),
                  _buildSettingsList(),
                  const SizedBox(height: 30),
                  _buildSectionHeader('Preferences'),
                  const SizedBox(height: 10),
                  _buildPreferencesList(),
                  const SizedBox(height: 100), // Added bottom padding for navigation bar
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      backgroundColor: AppColors.scaffoldBg,
      elevation: 0,
      centerTitle: true,
      title: Text(
        'Profile',
        style: TextStyle(
          color: AppColors.textMain,
          fontWeight: FontWeight.w900,
          fontSize: 22,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildUserCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.cardBg, AppColors.cardBg.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryLight.withOpacity(0.5), width: 2),
            ),
            child: CircleAvatar(
              radius: 35,
              backgroundColor: Colors.black26,
              backgroundImage: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                  ? CachedNetworkImageProvider(
                      _profileImageUrl!.startsWith('http')
                          ? _profileImageUrl!
                          : 'https://chocolate-viper-895188.hostingersite.com/storage/$_profileImageUrl',
                    ) as ImageProvider
                  : null,
              child: (_profileImageUrl == null || _profileImageUrl!.isEmpty)
                  ? Icon(Icons.person_rounded, size: 35, color: AppColors.textMuted)
                  : null,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, $_firstName!',
                  style: TextStyle(
                    color: AppColors.textMain,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'FitPax Pro Member',
                  style: TextStyle(
                    color: AppColors.primaryLight,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: [
          Icon(Icons.account_circle_outlined, size: 60, color: AppColors.textMuted),
          const SizedBox(height: 15),
          Text(
            'Unlock Your Potential',
            style: TextStyle(color: AppColors.textMain, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Sign in to track your progress and access personalized AI training.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 14),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Login / Sign Up', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: AppColors.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildSettingsList() {
    return Column(
      children: [
        _buildSettingItem(
          icon: Icons.settings_applications_rounded,
          title: 'API Configuration',
          subtitle: 'Configure backend and AI URLs',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ),
        ),
        _buildSettingItem(
          icon: Icons.person_outline_rounded,
          title: 'Personal Info',
          subtitle: 'Update your profile details',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfileInfoScreen()),
          ),
        ),
        _buildSettingItem(
          icon: Icons.notifications_none_rounded,
          title: 'Notifications',
          subtitle: 'Manage your alerts',
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildPreferencesList() {
    return Column(
      children: [
        _buildSettingItem(
          icon: Icons.language_rounded,
          title: 'Language',
          subtitle: 'Choose your preferred language',
          onTap: () {},
        ),
        _buildThemeToggleItem(),
        _buildSettingItem(
          icon: Icons.help_outline_rounded,
          title: 'Help & Support',
          subtitle: 'Get assistance and FAQs',
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildThemeToggleItem() {
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeService.isDarkMode,
      builder: (context, isDark, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderColor),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                color: AppColors.primaryLight,
                size: 24,
              ),
            ),
            title: Text(
              'Dark Mode',
              style: TextStyle(color: AppColors.textMain, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Text(
              isDark ? 'Currently using dark theme' : 'Currently using light theme',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            trailing: Switch(
              value: isDark,
              activeColor: AppColors.primaryLight,
              onChanged: (val) => ThemeService.setDarkMode(val),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primaryLight, size: 24),
        ),
        title: Text(
          title,
          style: TextStyle(color: AppColors.textMain, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
        trailing: Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
      ),
    );
  }
}
