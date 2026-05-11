import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../services/ai_api_service.dart';
import '../services/api_service.dart';
import '../services/theme_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _baseUrlController = TextEditingController();
  final _localAiUrlController = TextEditingController();
  final _mainApiUrlController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  Future<void> _loadCurrentSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _baseUrlController.text = prefs.getString('ai_base_url') ?? AiApiService.defaultBaseUrl;
      _localAiUrlController.text = prefs.getString('ai_local_url') ?? AiApiService.defaultLocalAiUrl;
      _mainApiUrlController.text = prefs.getString('main_api_url') ?? 'https://chocolate-viper-895188.hostingersite.com/api/user-app';
    });
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ai_base_url', _baseUrlController.text.trim());
    await prefs.setString('ai_local_url', _localAiUrlController.text.trim());
    await prefs.setString('main_api_url', _mainApiUrlController.text.trim());

    // Update static fields in services
    await AiApiService.init();
    await ApiService.init();

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text('Settings saved successfully!'),
            ],
          ),
          backgroundColor: Colors.green.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(20),
        ),
      );
    }
  }

  Future<void> _resetToDefaults() async {
    setState(() {
      _baseUrlController.text = AiApiService.defaultBaseUrl;
      _localAiUrlController.text = AiApiService.defaultLocalAiUrl;
      _mainApiUrlController.text = 'https://chocolate-viper-895188.hostingersite.com/api/user-app';
    });
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('ai_base_url');
    await prefs.remove('ai_local_url');
    await prefs.remove('main_api_url');

    // Update static fields in services
    await AiApiService.init();
    await ApiService.init();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reset to default values.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('API Configuration'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            _buildUrlField(
              label: 'Main App API URL',
              controller: _mainApiUrlController,
              icon: Icons.api_rounded,
              hint: 'e.g. https://chocolate-viper-895188.hostingersite.com/api/user-app',
              description: 'Primary backend for gyms, videos, and user data.',
            ),
            const SizedBox(height: 24),
            _buildUrlField(
              label: 'Main AI Base URL',
              controller: _baseUrlController,
              icon: Icons.hub_rounded,
              hint: 'e.g. http://192.168.1.16:8000',
              description: 'Used for plan recommendations and user history.',
            ),
            const SizedBox(height: 24),
            _buildUrlField(
              label: 'Local AI URL',
              controller: _localAiUrlController,
              icon: Icons.computer_rounded,
              hint: 'e.g. http://192.168.0.16:1234/api/v1',
              description: 'Used for the Fit AI chat interface.',
            ),
            const SizedBox(height: 32),
            _buildThemeToggle(),
            const SizedBox(height: 40),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.primaryLight, size: 28),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              'Customize your AI API endpoints here. Ensure the servers are reachable from your device network.',
              style: TextStyle(color: AppColors.textMain, fontSize: 14, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrlField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    required String description,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textMain,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderColor),
          ),
          child: TextField(
            controller: controller,
            style: TextStyle(color: AppColors.textMain),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: AppColors.textMuted.withOpacity(0.5)),
              prefixIcon: Icon(icon, color: AppColors.primaryLight),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          description,
          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildThemeToggle() {
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeService.isDarkMode,
      builder: (context, isDark, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardBg : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderColor),
          ),
          child: Row(
            children: [
              Icon(
                isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                color: AppColors.primary,
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Dark Mode',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Switch(
                value: isDark,
                activeColor: AppColors.primary,
                onChanged: (val) => ThemeService.setDarkMode(val),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
            ),
            child: _isSaving
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'Save Configuration',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _resetToDefaults,
          child: Text(
            'Reset to Defaults',
            style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
