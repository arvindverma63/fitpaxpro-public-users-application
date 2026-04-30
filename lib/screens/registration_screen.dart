import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import 'home_screen.dart';

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
  String? _authToken; // Stores the Bearer token after OTP verification

  // Form Data State
  String name = '';
  String email = '';
  String phone = '';
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
  String? profileImagePath;

  // --- ACTIONS ---

  void _showToast(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _handleSendOtp({bool isResend = false}) async {
    if (name.isEmpty || email.isEmpty || phone.isEmpty) {
      _showToast("Please fill in all identity fields");
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Note: Updated service to return dynamic to capture otp_preview
      final response = await _apiService.sendOtp(name, email, phone);
      if (response != null) {
        setState(() => _otpSent = true);
        String msg = isResend ? "OTP Resent!" : "OTP Sent Successfully.";

        if (response is Map) {
          final Map resMap = response; // Flutter now knows this is a Map
          if (resMap.containsKey('otp_preview')) {
            msg += " (TEST OTP: ${resMap['otp_preview']})";
          }
        }
        _showToast(msg, isError: false);
      }
    } catch (e) {
      _showToast("Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _nextStep() async {
    setState(() => _isLoading = true);

    try {
      bool success = false;

      // STEP 0: IDENTITY & OTP VERIFICATION
      if (_currentStep == 0) {
        if (!_otpSent) {
          await _handleSendOtp();
          return; // Stay on page to enter OTP
        } else {
          if (otp.isEmpty) throw "Please enter the 6-digit OTP";
          final token = await _apiService.verifyOtp(email, otp);
          if (token != null) {
            _authToken = token; // Captured token for next authenticated steps
            success = true;
          } else {
            throw "Invalid OTP. Please try again.";
          }
        }
      }
      // STEP 1: PHYSICAL ATTRIBUTES (Authenticated)
      else if (_currentStep == 1) {
        if (height.isEmpty || weight.isEmpty) throw "Please enter height and weight";
        success = await _apiService.submitPhysicalAttributes({
          "gender": gender,
          "date_of_birth": dob,
          "height": double.tryParse(height) ?? 170.0,
          "current_weight": double.tryParse(weight) ?? 70.0,
          "target_weight": double.tryParse(targetWeight) ?? 65.0,
          "blood_group": bloodGroup
        }, _authToken!);
      }
      // STEP 2: GOALS & LIFESTYLE (Authenticated)
      else if (_currentStep == 2) {
        success = await _apiService.submitGoalsAndLifestyle({
          "fitness_level": fitnessLevel,
          "goal_type": goalType,
          "activity_level": "moderately_active",
          "diet_type": dietType,
          "workout_frequency_goal": 4,
          "preferred_workout_time": "morning"
        }, _authToken!);
      }
      // STEP 3: MEDICAL INTEL (Authenticated)
      else if (_currentStep == 3) {
        success = await _apiService.submitMedicalIntel({
          "medical_conditions": medicalConditions,
          "allergies": allergies,
          "physical_limitations": "None"
        }, _authToken!);
      }
      // STEP 4: VISUAL ASSETS (Authenticated)
      else if (_currentStep == 4) {
        success = await _apiService.submitVisualAssets(profileImagePath, isPublic, _authToken!);
        if (success) {
          if (!mounted) return;
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (route) => false);
          return;
        }
      }

      if (success) {
        _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);
        setState(() {
          _currentStep++;
        });
      }
    } catch (e) {
      _showToast(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
                physics: const NeverScrollableScrollPhysics(),
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

  // --- UI BUILDING BLOCKS ---

  Widget _buildStepWrapper({required String title, required String subtitle, required Widget child}) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.textMain, letterSpacing: -0.5)),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(fontSize: 15, color: AppColors.textMuted)),
          const SizedBox(height: 35),
          child,
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, Function(String) onChanged, {TextInputType? keyboardType, bool enabled = true}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
      child: TextField(
        onChanged: (v) => setState(() => onChanged(v)),
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
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withOpacity(0.2) : AppColors.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? AppColors.primaryLight : Colors.white10),
          ),
          child: Center(
            child: Text(label, style: TextStyle(color: isSelected ? AppColors.primaryLight : AppColors.textMain, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  // --- STEP PAGES ---

  Widget _buildStep1Identity() {
    return _buildStepWrapper(
      title: 'Get Started',
      subtitle: 'Create your account to start your fitness journey.',
      child: Column(
        children: [
          _buildTextField('Full Name', Icons.person_outline, (v) => name = v, enabled: !_otpSent),
          _buildTextField('Email Address', Icons.email_outlined, (v) => email = v, enabled: !_otpSent, keyboardType: TextInputType.emailAddress),
          _buildTextField('Phone Number', Icons.phone_android, (v) => phone = v, enabled: !_otpSent, keyboardType: TextInputType.phone),
          if (_otpSent) ...[
            const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(color: Colors.white10)),
            _buildTextField('6-Digit OTP', Icons.lock_clock_outlined, (v) => otp = v, keyboardType: TextInputType.number),
            TextButton(
              onPressed: _isLoading ? null : () => _handleSendOtp(isResend: true),
              child: const Text("Didn't receive code? Resend OTP", style: TextStyle(color: AppColors.primaryLight)),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildStep2Physical() {
    return _buildStepWrapper(
      title: 'Body Stats',
      subtitle: 'We use this to calculate your calories and progress.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Gender', style: TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildChoiceChip('Male', gender == 'male', () => setState(() => gender = 'male')),
              const SizedBox(width: 15),
              _buildChoiceChip('Female', gender == 'female', () => setState(() => gender = 'female')),
            ],
          ),
          const SizedBox(height: 25),
          Row(
            children: [
              Expanded(child: _buildTextField('Height (cm)', Icons.height, (v) => height = v, keyboardType: TextInputType.number)),
              const SizedBox(width: 15),
              Expanded(child: _buildTextField('Weight (kg)', Icons.monitor_weight_outlined, (v) => weight = v, keyboardType: TextInputType.number)),
            ],
          ),
          _buildTextField('Target Weight (kg)', Icons.track_changes, (v) => targetWeight = v, keyboardType: TextInputType.number),
          const SizedBox(height: 15),
          const Text('Blood Group', style: TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
            child: DropdownButton<String>(
              value: bloodGroup,
              isExpanded: true,
              underline: const SizedBox(),
              dropdownColor: AppColors.cardBg,
              style: const TextStyle(color: Colors.white),
              items: ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (v) => setState(() => bloodGroup = v!),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3Goals() => _buildStepWrapper(
    title: 'Your Goals',
    subtitle: 'What is your primary fitness objective?',
    child: Column(
      children: [
        _buildChoiceChip('Weight Loss', goalType == 'weight_loss', () => setState(() => goalType = 'weight_loss')),
        const SizedBox(height: 12),
        _buildChoiceChip('Muscle Gain', goalType == 'muscle_gain', () => setState(() => goalType = 'muscle_gain')),
        const SizedBox(height: 25),
        const Align(alignment: Alignment.centerLeft, child: Text('Diet Preference', style: TextStyle(color: AppColors.textMuted))),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildChoiceChip('Veg', dietType == 'veg', () => setState(() => dietType = 'veg')),
            const SizedBox(width: 10),
            _buildChoiceChip('Non-Veg', dietType == 'non_veg', () => setState(() => dietType = 'non_veg')),
          ],
        )
      ],
    ),
  );

  Widget _buildStep4Medical() => _buildStepWrapper(
    title: 'Medical Intel',
    subtitle: 'Safety is our priority. Any conditions we should know?',
    child: Column(
      children: [
        _buildTextField('Medical Conditions', Icons.medical_information_outlined, (v) => medicalConditions = v),
        _buildTextField('Allergies', Icons.warning_amber_rounded, (v) => allergies = v),
      ],
    ),
  );

  Widget _buildStep5Profile() => _buildStepWrapper(
    title: 'Almost Done',
    subtitle: 'Upload a profile picture to complete your setup.',
    child: Column(
      children: [
        const CircleAvatar(radius: 60, backgroundColor: AppColors.cardBg, child: Icon(Icons.camera_alt_outlined, size: 40, color: AppColors.textMuted)),
        const SizedBox(height: 40),
        SwitchListTile(
          title: const Text('Public Profile', style: TextStyle(color: Colors.white)),
          subtitle: const Text('Allow others to see your progress', style: TextStyle(color: AppColors.textMuted)),
          value: isPublic,
          activeColor: AppColors.primaryLight,
          onChanged: (v) => setState(() => isPublic = v),
        )
      ],
    ),
  );

  Widget _buildProgressBar() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 6,
          width: _currentStep >= index ? 24 : 12,
          decoration: BoxDecoration(color: _currentStep >= index ? AppColors.primaryLight : Colors.white24, borderRadius: BorderRadius.circular(4)),
        );
      }),
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(color: AppColors.cardBg, border: Border(top: BorderSide(color: Colors.white10))),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _nextStep,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          child: _isLoading
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(_currentStep == 4 ? 'Complete Registration' : (_otpSent ? 'Verify OTP' : 'Continue'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}