import 'package:flutter/material.dart';
import '../../services/ai_api_service.dart';
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
  final AiApiService _aiService = AiApiService();

  bool _isFetching = true;
  bool _isSaving = false;

  // Profile State mapping to FastAPI Schema
  String _goal = 'maintenance';
  String _diet = 'balanced';
  String _gender = 'male';

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

  // --- HITS: GET /profile/{session_id} ---
  Future<void> _fetchProfile() async {
    final profileData = await _aiService.getUserProfile(widget.sessionId);
    if (mounted) {
      setState(() {
        if (profileData != null) {
          _goal = profileData['goal'] ?? 'maintenance';
          _diet = profileData['diet_type'] ?? 'balanced';
          _gender = profileData['gender'] ?? 'male';
          _weightController.text = profileData['weight']?.toString() ?? '';
          _heightController.text = profileData['height']?.toString() ?? '';
          _medicalController.text = profileData['medical_history'] ?? 'None';
        }
        _isFetching = false;
      });
    }
  }

  // --- HITS: POST /profile/{session_id} ---
  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    // Parse weight and height safely
    double? weight = double.tryParse(_weightController.text.trim());
    double? height = double.tryParse(_heightController.text.trim());

    // Send to FastAPI
    bool success = await _aiService.syncUserProfile(widget.sessionId, {
      "goal": _goal,
      "diet_type": _diet,
      "gender": _gender,
      "weight": weight,
      "height": height,
      "medical_history": _medicalController.text.trim().isEmpty ? 'None' : _medicalController.text.trim(),
    });

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'AI Profile Updated Successfully!' : 'Failed to update profile.', style: const TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: success ? Colors.green : Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          )
      );
      if (success) {
        // Trigger the chat message in the main screen
        widget.onProfileUpdated(_goal, _diet);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Wrap in a GestureDetector to dismiss keyboard when tapping outside
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom, // Moves up when keyboard opens
          left: 24, right: 24, top: 24,
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              const Text('AI Optimization Profile', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('The AI uses these metrics to accurately calculate your calories and suggest safe exercises.', style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.4)),
              const SizedBox(height: 24),

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
                            value: _goal.isEmpty ? 'maintenance' : _goal,
                            items: ['weight_loss', 'muscle_gain', 'maintenance'],
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
                            value: _gender.isEmpty ? 'male' : _gender.toLowerCase(),
                            items: ['male', 'female', 'other'],
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
                  value: _diet.isEmpty ? 'balanced' : _diet,
                  items: ['veg', 'vegan', 'keto', 'balanced', 'non_veg'],
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
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    onPressed: _isSaving ? null : _saveProfile,
                    child: _isSaving
                        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : const Text('Update AI Brain', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 24),
              ]
            ],
          ),
        ),
      ),
    );
  }

  // Helper for Dropdowns
  Widget _buildDropdown({required String value, required List<String> items, required Function(String?) onChanged}) {
    // Ensure the value exists in the list to prevent Flutter crash
    if (!items.contains(value)) value = items.first;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: AppColors.cardBg,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMuted),
          items: items.map((v) => DropdownMenuItem(value: v, child: Text(v.replaceAll('_', ' ').toUpperCase()))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // Helper for TextFields
  Widget _buildTextField(TextEditingController controller, String hint, {required bool isNumber}) {
    return Container(
      decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}