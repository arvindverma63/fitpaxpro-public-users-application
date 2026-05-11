import 'package:flutter/material.dart';
import '../../services/ai_api_service.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';

class AiProfileSheet extends StatefulWidget {
  final String sessionId;
  final Function(String goal, String diet) onProfileUpdated;

  const AiProfileSheet({
    super.key,
    required this.sessionId,
    required this.onProfileUpdated,
  });

  @override
  State<AiProfileSheet> createState() => _AiProfileSheetState();
}

class _AiProfileSheetState extends State<AiProfileSheet> {
  // Services
  final AiApiService _aiService = AiApiService();
  final ApiService _apiService = ApiService();

  // UI State
  bool _isFetching = true;
  bool _isSaving = false;

  // Profile State mapping to FastAPI Schema
  String _goal = 'maintenance';
  String _diet = 'veg'; // Changed default from 'balanced' to 'veg'
  String _gender = 'male';

  // Valid Dropdown Options (Updated with new enums)
  final List<String> _validGoals = ['weight_loss', 'muscle_gain', 'maintenance'];
  final List<String> _validDiets = ['veg', 'non_veg', 'eggitarian', 'vegan', 'keto', 'paleo'];
  final List<String> _validGenders = ['male', 'female', 'other'];

  // Text Controllers
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _medicalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _medicalController.dispose();
    super.dispose();
  }

  // --- HITS: GET /profile (Main Backend) ---
  Future<void> _fetchProfile() async {
    // Fetches the comprehensive profile.
    // Notice how clean it is now since ApiService handles the SharedPrefs token internally!
    final fullProfileResponse = await _apiService.getFullProfile();

    if (mounted) {
      setState(() {
        if (fullProfileResponse != null && fullProfileResponse['profile'] != null) {
          final profile = fullProfileResponse['profile'];

          // Safely assign dropdown values
          String apiGoal = profile['goal_type'] ?? 'maintenance';
          _goal = _validGoals.contains(apiGoal) ? apiGoal : 'maintenance';

          String apiDiet = profile['diet_type'] ?? 'balanced';
          _diet = _validDiets.contains(apiDiet) ? apiDiet : 'balanced';

          String apiGender = profile['gender'] ?? 'male';
          _gender = _validGenders.contains(apiGender) ? apiGender : 'male';

          // Assign text fields
          _weightController.text = profile['current_weight']?.toString() ?? '';
          _heightController.text = profile['height']?.toString() ?? '';
          _medicalController.text = profile['medical_conditions'] ?? '';
        }
        _isFetching = false;
      });
    }
  }
// --- HITS: POST /profile (Main Backend) ---
  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    // Parse weight and height safely
    double? weight = double.tryParse(_weightController.text.trim());
    double? height = double.tryParse(_heightController.text.trim());

    // Map UI data to match your Laravel API parameters exactly
    Map<String, dynamic> updatePayload = {
      "goal_type": _goal,
      "diet_type": _diet,
      "gender": _gender,
    };

    if (weight != null) updatePayload["current_weight"] = weight;
    if (height != null) updatePayload["height"] = height;

    // Add medical history if not empty
    String medicalText = _medicalController.text.trim();
    if (medicalText.isNotEmpty) {
      updatePayload["medical_conditions"] = medicalText;
    }

    // 1. Send data to your Main Backend API
    bool success = await _apiService.updateProfile(updatePayload);

    // 2. (Optional) Log measurements history as well
    if (success && weight != null) {
      await _apiService.logMeasurements({"weight": weight});
    }

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context); // Close the bottom sheet

      // Show result to user
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                success
                    ? 'Profile Updated Successfully!'
                    : 'Failed to update profile. Please try again.',
                style: const TextStyle(fontWeight: FontWeight.bold)
            ),
            backgroundColor: success ? Colors.green : Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          )
      );

      if (success) {
        // Trigger the chat message update in the main screen
        widget.onProfileUpdated(_goal, _diet);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // GestureDetector dismisses the keyboard when tapping outside of a text field
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Padding(
        padding: EdgeInsets.only(
          // This ensures the bottom sheet moves up when the keyboard appears
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24, right: 24, top: 24,
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handlebar at the top
              Center(
                  child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: AppColors.borderColor, borderRadius: BorderRadius.circular(2))
                  )
              ),
              const SizedBox(height: 24),
              Text('AI Optimization Profile', style: TextStyle(color: AppColors.textMain, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('The AI uses these metrics to accurately calculate your calories and suggest safe exercises.', style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.4)),
              const SizedBox(height: 24),

              // Show loader while fetching data
              if (_isFetching)
                const Center(child: Padding(padding: EdgeInsets.all(40.0), child: CircularProgressIndicator(color: AppColors.primaryLight)))
              else ...[

                // --- ROW 1: GOAL & GENDER ---
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Goal', style: TextStyle(color: AppColors.primaryLight, fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          _buildDropdown(
                            value: _goal,
                            items: _validGoals,
                            onChanged: (v) => setState(() => _goal = v!),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Gender', style: TextStyle(color: AppColors.primaryLight, fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          _buildDropdown(
                            value: _gender,
                            items: _validGenders,
                            onChanged: (v) => setState(() => _gender = v!),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // --- ROW 2: DIET ---
                const Text('Diet Preference', style: TextStyle(color: AppColors.primaryLight, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildDropdown(
                  value: _diet,
                  items: _validDiets,
                  onChanged: (v) => setState(() => _diet = v!),
                ),
                const SizedBox(height: 16),

                // --- ROW 3: WEIGHT & HEIGHT ---
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Weight (kg)', style: TextStyle(color: AppColors.primaryLight, fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          _buildTextField(_weightController, 'e.g. 75', isNumber: true),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Height (cm)', style: TextStyle(color: AppColors.primaryLight, fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          _buildTextField(_heightController, 'e.g. 180', isNumber: true),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // --- ROW 4: MEDICAL HISTORY ---
                const Text('Medical History / Injuries', style: TextStyle(color: AppColors.primaryLight, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildTextField(_medicalController, 'e.g. Bad lower back, asthma...', isNumber: false),

                const SizedBox(height: 32),

                // --- SAVE BUTTON ---
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                    ),
                    onPressed: _isSaving ? null : _saveProfile,
                    child: _isSaving
                        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : const Text('Update AI Brain', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 24), // Extra padding at the bottom
              ]
            ],
          ),
        ),
      ),
    );
  }

  // --- UI HELPERS ---

  Widget _buildDropdown({required String value, required List<String> items, required Function(String?) onChanged}) {
    // Extra safety measure: Fallback if the initial value isn't in the list
    if (!items.contains(value)) value = items.first;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderColor)
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: AppColors.cardBg,
          style: TextStyle(color: AppColors.textMain, fontSize: 14),
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMuted),
          // Replaces underscores with spaces and capitalizes for UI display
          items: items.map((v) => DropdownMenuItem(value: v, child: Text(v.replaceAll('_', ' ').toUpperCase(), style: TextStyle(color: AppColors.textMain)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {required bool isNumber}) {
    return Container(
      decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderColor)
      ),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        style: TextStyle(color: AppColors.textMain, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}