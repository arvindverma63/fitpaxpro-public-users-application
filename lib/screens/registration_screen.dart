import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import 'home_screen.dart'; // To navigate after success

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final ApiService _apiService = ApiService();
  final PageController _pageController = PageController();

  int _currentStep = 0;
  bool _isLoading = false;
  bool _otpSent = false;

  // Form Data State
  String name = '';     // <-- Add this
  String email = '';
  String phone = '';    // <-- Add this
  String otp = '';
  String gender = 'male';
  String dob = '1995-05-15';
  String height = '';
  String weight = '';
  String targetWeight = '';
  String bloodGroup = 'O+';
  String fitnessLevel = 'intermediate';
  String goalType = 'weight_loss';
  String dietType = 'veg';
  String medicalConditions = 'None';
  String allergies = 'None';
  bool isPublic = true;
  String? profileImagePath; // Requires image_picker to populate

  void _nextStep() async {
    setState(() => _isLoading = true);

    try {
      bool success = false;

      if (_currentStep == 0) {
        if (!_otpSent) {
          // Basic validation
          if (name.isEmpty || email.isEmpty || phone.isEmpty) {
            throw Exception('Please fill in all fields.');
          }
          // Updated API Call
          success = await _apiService.sendOtp(name, email, phone);
          if (success) setState(() => _otpSent = true);
          success = false;
        } else {
          success = await _apiService.verifyOtp(email, otp);
        }
      }
      // ... keep the rest of your _nextStep logic exactly the same
      else if (_currentStep == 1) {
        success = await _apiService.submitPhysicalAttributes({
          "gender": gender, "date_of_birth": dob, "height": double.tryParse(height) ?? 170.0,
          "current_weight": double.tryParse(weight) ?? 70.0, "target_weight": double.tryParse(targetWeight) ?? 65.0,
          "blood_group": bloodGroup
        });
      }
      else if (_currentStep == 2) {
        success = await _apiService.submitGoalsAndLifestyle({
          "fitness_level": fitnessLevel, "goal_type": goalType, "activity_level": "moderately_active",
          "diet_type": dietType, "workout_frequency_goal": 4, "preferred_workout_time": "morning"
        });
      }
      else if (_currentStep == 3) {
        success = await _apiService.submitMedicalIntel({
          "medical_conditions": medicalConditions, "allergies": allergies, "physical_limitations": "None"
        });
      }
      else if (_currentStep == 4) {
        success = await _apiService.submitVisualAssets(profileImagePath, isPublic);
        if (success) {
          if (!mounted) return;
          // Registration Complete! Go to Home Screen
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (route) => false);
          return;
        }
      }

      if (success) {
        _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);
        setState(() {
          _currentStep++;
          _otpSent = false; // Reset for next interactions if any
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.redAccent));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _currentStep > 0
            ? IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textMain, size: 20),
          onPressed: () {
            _pageController.previousPage(duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);
            setState(() => _currentStep--);
          },
        )
            : const SizedBox.shrink(),
        title: _buildProgressBar(),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // Prevent manual swiping without passing validation
                children: [
                  _buildStep1Identity(),
                  _buildStep2Physical(),
                  _buildStep3Goals(),
                  _buildStep4Medical(),
                  _buildStep5Profile(),
                ],
              ),
            ),
            _buildBottomActionBar(),
          ],
        ),
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildProgressBar() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 6,
          width: _currentStep >= index ? 24 : 12,
          decoration: BoxDecoration(
            color: _currentStep >= index ? AppColors.primaryLight : Colors.white24,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.cardBg,
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _nextStep,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: _isLoading
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(
            _currentStep == 4 ? 'Complete Registration' : (_otpSent ? 'Verify OTP' : 'Continue'),
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  // --- WIZARD PAGES ---

  Widget _buildStep1Identity() {
    return _buildStepWrapper(
      title: 'Verify Identity',
      subtitle: 'Enter your personal details to secure your account.',
      child: Column(
        children: [
          _buildTextField(
              'Full Name',
              Icons.person_rounded,
                  (v) => name = v,
              enabled: !_otpSent
          ),
          const SizedBox(height: 16),
          _buildTextField(
              'Email Address',
              Icons.email_rounded,
                  (v) => email = v,
              enabled: !_otpSent,
              keyboardType: TextInputType.emailAddress
          ),
          const SizedBox(height: 16),
          _buildTextField(
              'Phone Number',
              Icons.phone_rounded,
                  (v) => phone = v,
              enabled: !_otpSent,
              keyboardType: TextInputType.phone
          ),

          if (_otpSent) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Divider(color: Colors.white10, height: 1),
            ),
            _buildTextField(
                'Enter 6-Digit OTP',
                Icons.password_rounded,
                    (v) => otp = v,
                keyboardType: TextInputType.number
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppColors.primaryLight, size: 16),
                SizedBox(width: 8),
                Text('An OTP has been sent to your email.', style: TextStyle(color: AppColors.primaryLight, fontSize: 13)),
              ],
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildStep2Physical() {
    return _buildStepWrapper(
      title: 'Physical Attributes',
      subtitle: 'Help us customize your fitness journey.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Gender', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildChoiceChip('Male', gender == 'male', () => setState(() => gender = 'male'))),
              const SizedBox(width: 12),
              Expanded(child: _buildChoiceChip('Female', gender == 'female', () => setState(() => gender = 'female'))),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildTextField('Height (cm)', Icons.height_rounded, (v) => height = v, keyboardType: TextInputType.number)),
              const SizedBox(width: 16),
              Expanded(child: _buildTextField('Weight (kg)', Icons.monitor_weight_rounded, (v) => weight = v, keyboardType: TextInputType.number)),
            ],
          ),
          const SizedBox(height: 24),
          _buildTextField('Target Weight (kg)', Icons.track_changes_rounded, (v) => targetWeight = v, keyboardType: TextInputType.number),
        ],
      ),
    );
  }

  Widget _buildStep3Goals() {
    return _buildStepWrapper(
      title: 'Goals & Lifestyle',
      subtitle: 'What are you looking to achieve?',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Primary Goal', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildChoiceChip('Weight Loss', goalType == 'weight_loss', () => setState(() => goalType = 'weight_loss')),
              _buildChoiceChip('Muscle Gain', goalType == 'muscle_gain', () => setState(() => goalType = 'muscle_gain')),
              _buildChoiceChip('Endurance', goalType == 'endurance', () => setState(() => goalType = 'endurance')),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Diet Preference', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildChoiceChip('Vegetarian', dietType == 'veg', () => setState(() => dietType = 'veg')),
              _buildChoiceChip('Non-Veg', dietType == 'non_veg', () => setState(() => dietType = 'non_veg')),
              _buildChoiceChip('Vegan', dietType == 'vegan', () => setState(() => dietType = 'vegan')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep4Medical() {
    return _buildStepWrapper(
      title: 'Medical Intel',
      subtitle: 'Safety first. Let trainers know of any issues.',
      child: Column(
        children: [
          _buildTextField('Medical Conditions (e.g., Asthma, BP)', Icons.medical_services_rounded, (v) => medicalConditions = v, maxLines: 2),
          const SizedBox(height: 24),
          _buildTextField('Allergies', Icons.warning_rounded, (v) => allergies = v),
        ],
      ),
    );
  }

  Widget _buildStep5Profile() {
    return _buildStepWrapper(
      title: 'Profile Setup',
      subtitle: 'Make your profile stand out.',
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              // TODO: Implement image_picker logic here
            },
            child: Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryLight, width: 2),
              ),
              child: const Icon(Icons.camera_alt_rounded, color: AppColors.textMuted, size: 40),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Upload Profile Photo', style: TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold)),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(16)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Public Profile', style: TextStyle(color: AppColors.textMain, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Allow friends to find you', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
                Switch(
                  value: isPublic,
                  activeColor: AppColors.primaryLight,
                  onChanged: (val) => setState(() => isPublic = val),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // --- REUSABLE WIDGETS ---

  Widget _buildStepWrapper({required String title, required String subtitle, required Widget child}) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.textMain, letterSpacing: -0.5)),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(fontSize: 15, color: AppColors.textMuted)),
          const SizedBox(height: 40),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, Function(String) onChanged, {int maxLines = 1, TextInputType? keyboardType, bool enabled = true}) {
    return Container(
      decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
      child: TextField(
        onChanged: onChanged,
        maxLines: maxLines,
        keyboardType: keyboardType,
        enabled: enabled,
        style: TextStyle(color: enabled ? AppColors.textMain : AppColors.textMuted),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
          prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildChoiceChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.2) : AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.primaryLight : Colors.white10),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(color: isSelected ? AppColors.primaryLight : AppColors.textMain, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
      ),
    );
  }
}