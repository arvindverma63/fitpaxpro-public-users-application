import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';

class ProfileInfoScreen extends StatefulWidget {
  const ProfileInfoScreen({super.key});

  @override
  State<ProfileInfoScreen> createState() => _ProfileInfoScreenState();
}

class _ProfileInfoScreenState extends State<ProfileInfoScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  // Options Lists (Match Backend)
  final List<String> _goalOptions = ['weight_loss', 'weight_gain', 'muscle_building', 'endurance', 'maintenance', 'general_fitness'];
  final List<String> _activityOptions = ['sedentary', 'lightly_active', 'moderately_active', 'very_active', 'extra_active'];
  final List<String> _dietOptions = ['veg', 'non_veg', 'vegan', 'keto', 'paleo', 'pescatarian'];
  final List<String> _genderOptions = ['male', 'female', 'other'];

  // Account Info
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // Physical Stats
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _currentWeightController = TextEditingController();
  final TextEditingController _targetWeightController = TextEditingController();
  final TextEditingController _bloodGroupController = TextEditingController();

  // Goals & Lifestyle (with default safe values)
  String _selectedGender = 'male';
  String _selectedGoal = 'weight_gain';
  String _selectedActivity = 'sedentary';
  String _selectedDiet = 'veg';
  bool _isPublic = true;

  // Medical Info
  final TextEditingController _medicalController = TextEditingController();
  final TextEditingController _allergiesController = TextEditingController();
  final TextEditingController _limitationsController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  String _ensureValidValue(String? value, List<String> options) {
    if (value == null || !options.contains(value)) {
      return options.first;
    }
    return value;
  }

  Future<void> _loadProfile() async {
    final data = await _apiService.getFullProfile();
    if (mounted && data != null) {
      final profile = data['profile'] ?? {};
      setState(() {
        // Account info
        _nameController.text = data['name'] ?? '';
        _emailController.text = data['email'] ?? '';
        _phoneController.text = data['phone'] ?? '';

        // Physical stats
        _ageController.text = (profile['age'] ?? '').toString();
        _heightController.text = (profile['height'] ?? '').toString();
        _currentWeightController.text = (profile['current_weight'] ?? '').toString();
        _targetWeightController.text = (profile['target_weight'] ?? '').toString();
        _bloodGroupController.text = profile['blood_group'] ?? '';

        // Selections (Safeguarded against unexpected API values)
        _selectedGender = _ensureValidValue(profile['gender'], _genderOptions);
        _selectedGoal = _ensureValidValue(profile['goal_type'], _goalOptions);
        _selectedActivity = _ensureValidValue(profile['activity_level'], _activityOptions);
        _selectedDiet = _ensureValidValue(profile['diet_type'], _dietOptions);
        
        _isPublic = profile['is_public'] ?? true;

        // Medical
        _medicalController.text = profile['medical_conditions'] ?? '';
        _allergiesController.text = profile['allergies'] ?? '';
        _limitationsController.text = profile['physical_limitations'] ?? '';

        _isLoading = false;
      });
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final Map<String, dynamic> updateData = {
      'name': _nameController.text,
      'phone': _phoneController.text,
      'gender': _selectedGender,
      'age': int.tryParse(_ageController.text),
      'current_weight': _currentWeightController.text,
      'target_weight': _targetWeightController.text,
      'height': _heightController.text,
      'goal_type': _selectedGoal,
      'activity_level': _selectedActivity,
      'blood_group': _bloodGroupController.text,
      'diet_type': _selectedDiet,
      'medical_conditions': _medicalController.text,
      'allergies': _allergiesController.text,
      'physical_limitations': _limitationsController.text,
      'is_public': _isPublic,
    };

    final success = await _apiService.updateProfile(updateData);

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated successfully!', style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile.', style: const TextStyle(color: Colors.white)),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _currentWeightController.dispose();
    _targetWeightController.dispose();
    _bloodGroupController.dispose();
    _medicalController.dispose();
    _allergiesController.dispose();
    _limitationsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text('Profile Details', style: TextStyle(color: AppColors.textMain, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textMain, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryLight))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Account Information'),
                    const SizedBox(height: 16),
                    _buildTextField(label: 'Full Name', controller: _nameController, icon: Icons.person_outline_rounded),
                    const SizedBox(height: 16),
                    _buildTextField(label: 'Email', controller: _emailController, icon: Icons.email_outlined, readOnly: true),
                    const SizedBox(height: 16),
                    _buildTextField(label: 'Phone', controller: _phoneController, icon: Icons.phone_android_rounded),
                    
                    const SizedBox(height: 32),
                    _buildSectionHeader('Physical Attributes'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(label: 'Age', controller: _ageController, icon: Icons.cake_outlined, keyboardType: TextInputType.number)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildDropdown(label: 'Gender', value: _selectedGender, items: _genderOptions, onChanged: (v) => setState(() => _selectedGender = v!))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(label: 'Height (cm)', controller: _heightController, icon: Icons.height, keyboardType: TextInputType.number)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextField(label: 'Blood Group', controller: _bloodGroupController, icon: Icons.bloodtype_outlined)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(label: 'Weight (kg)', controller: _currentWeightController, icon: Icons.monitor_weight_outlined, keyboardType: TextInputType.number)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextField(label: 'Target (kg)', controller: _targetWeightController, icon: Icons.flag_outlined, keyboardType: TextInputType.number)),
                      ],
                    ),

                    const SizedBox(height: 32),
                    _buildSectionHeader('Goal & Lifestyle'),
                    const SizedBox(height: 16),
                    _buildDropdown(label: 'Fitness Goal', value: _selectedGoal, items: _goalOptions, onChanged: (v) => setState(() => _selectedGoal = v!)),
                    const SizedBox(height: 16),
                    _buildDropdown(label: 'Activity Level', value: _selectedActivity, items: _activityOptions, onChanged: (v) => setState(() => _selectedActivity = v!)),
                    const SizedBox(height: 16),
                    _buildDropdown(label: 'Diet Type', value: _selectedDiet, items: _dietOptions, onChanged: (v) => setState(() => _selectedDiet = v!)),

                    const SizedBox(height: 32),
                    _buildSectionHeader('Medical Information'),
                    const SizedBox(height: 16),
                    _buildTextField(label: 'Medical Conditions', controller: _medicalController, icon: Icons.medical_services_outlined),
                    const SizedBox(height: 16),
                    _buildTextField(label: 'Allergies', controller: _allergiesController, icon: Icons.warning_amber_rounded),
                    const SizedBox(height: 16),
                    _buildTextField(label: 'Physical Limitations', controller: _limitationsController, icon: Icons.accessible_forward_rounded),

                    const SizedBox(height: 32),
                    _buildPrivacyToggle(),
                    
                    const SizedBox(height: 40),
                    _buildSaveButton(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: AppColors.primaryLight, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Container(width: 40, height: 2, decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(1))),
      ],
    );
  }

  Widget _buildTextField({required String label, required TextEditingController controller, required IconData icon, bool readOnly = false, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderColor)),
          child: TextFormField(
            controller: controller,
            readOnly: readOnly,
            keyboardType: keyboardType,
            style: TextStyle(color: readOnly ? AppColors.textMuted : AppColors.textMain, fontSize: 14, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppColors.primaryLight, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({required String label, required String value, required List<String> items, required Function(String?) onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderColor)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: AppColors.cardBg,
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMuted),
              items: items.map((i) => DropdownMenuItem(
                value: i, 
                child: Text(
                  i.replaceAll('_', ' ').toUpperCase(), 
                  style: TextStyle(color: AppColors.textMain, fontSize: 13, fontWeight: FontWeight.w600)
                )
              )).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacyToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderColor)),
      child: Row(
        children: [
          Icon(Icons.lock_outline_rounded, color: AppColors.primaryLight),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Public Profile', style: TextStyle(color: AppColors.textMain, fontWeight: FontWeight.bold)),
              Text('Allow others to see your stats', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ]),
          ),
          Switch(value: _isPublic, onChanged: (v) => setState(() => _isPublic = v), activeColor: AppColors.primaryLight),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 8,
          shadowColor: AppColors.primary.withOpacity(0.4),
        ),
        child: _isSaving
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('Save Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
