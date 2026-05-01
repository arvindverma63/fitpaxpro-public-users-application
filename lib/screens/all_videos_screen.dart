import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/ai_api_service.dart';
import '../theme/app_colors.dart';

class AllVideosScreen extends StatefulWidget {
  const AllVideosScreen({super.key});

  @override
  State<AllVideosScreen> createState() => _AllVideosScreenState();
}

class _AllVideosScreenState extends State<AllVideosScreen> {
  final AiApiService _aiService = AiApiService();
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _exercises = [];
  bool _isLoading = true;
  String _selectedMuscle = 'All';

  final List<String> _muscleGroups = [
    'All', 'Pectorals', 'Lats', 'Glutes', 'Calves', 'Delts', 'Biceps', 'Triceps', 'Forearms', 'Abs'
  ];

  @override
  void initState() {
    super.initState();
    _fetchExercises();
  }

  Future<void> _fetchExercises({String query = ''}) async {
    setState(() => _isLoading = true);

    final String? muscleQuery = _selectedMuscle == 'All' ? null : _selectedMuscle.toLowerCase();

    // Fetch 50 results from your FastAPI backend
    final results = await _aiService.searchExercises(
      query: query.isNotEmpty ? query : null,
      muscle: muscleQuery,
      limit: 50,
    );

    if (mounted) {
      setState(() {
        _exercises = results ?? [];
        _isLoading = false;
      });
    }
  }

  String _buildImageUrl(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '${AiApiService.baseUrl}$path'; // Formats: http://192.168.1.16:8000/exercise-gif/...
  }

  // --- EXERCISE DETAILS MODAL ---
  void _showExerciseDetails(Map<String, dynamic> exercise) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.scaffoldBg,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (context) {
          return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              expand: false,
              builder: (_, controller) {
                return SingleChildScrollView(
                  controller: controller,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Handle Bar
                      Center(
                          child: Container(
                              margin: const EdgeInsets.only(top: 12, bottom: 20),
                              width: 40, height: 4,
                              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))
                          )
                      ),

                      // GIF Animation
                      Container(
                        height: 250,
                        width: double.infinity,
                        color: Colors.black26,
                        child: CachedNetworkImage(
                          imageUrl: _buildImageUrl(exercise['gif_url'] ?? ''),
                          fit: BoxFit.contain,
                          placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: AppColors.primaryLight)),
                          errorWidget: (context, url, error) => const Icon(Icons.fitness_center, color: Colors.white24, size: 60),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(exercise['name'].toString().toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 8),

                            // Tags
                            Row(
                              children: [
                                _buildTag('Target: ${exercise['muscles']}', AppColors.primaryLight),
                                const SizedBox(width: 8),
                                if (exercise['category'] != null)
                                  _buildTag(exercise['category'], AppColors.accent),
                              ],
                            ),

                            const SizedBox(height: 24),
                            const Text('Instructions', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            Text(
                              exercise['instruction'] ?? 'No instructions provided.',
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 15, height: 1.5),
                            ),

                            const SizedBox(height: 24),
                            const Text('Muscle Engagement', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),

                            // Secondary Muscles
                            if (exercise['secondaryMuscles'] != null && (exercise['secondaryMuscles'] as List).isNotEmpty) ...[
                              const Text('Secondary Muscles:', style: TextStyle(color: AppColors.textMain, fontSize: 14)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8, runSpacing: 8,
                                children: (exercise['secondaryMuscles'] as List).map((m) => Chip(
                                  label: Text(m.toString(), style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                  backgroundColor: AppColors.cardBg,
                                  side: const BorderSide(color: Colors.white10),
                                )).toList(),
                              )
                            ]
                          ],
                        ),
                      )
                    ],
                  ),
                );
              }
          );
        }
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withOpacity(0.5))),
      child: Text(text.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: AppColors.cardBg,
        elevation: 0,
        title: const Text('Discover Exercises', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
      ),
      body: Column(
        children: [
          // --- SEARCH BAR ---
          Container(
            color: AppColors.cardBg,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Container(
              decoration: BoxDecoration(color: AppColors.scaffoldBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search by name or equipment...',
                  hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 15),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward_rounded, color: AppColors.primaryLight),
                    onPressed: () => _fetchExercises(query: _searchController.text),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onSubmitted: (val) => _fetchExercises(query: val),
              ),
            ),
          ),

          // --- MUSCLE FILTER CHIPS ---
          Container(
            height: 50,
            color: AppColors.cardBg,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _muscleGroups.length,
              itemBuilder: (context, index) {
                final muscle = _muscleGroups[index];
                final isSelected = _selectedMuscle == muscle;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0, bottom: 10),
                  child: ChoiceChip(
                    label: Text(muscle, style: TextStyle(color: isSelected ? Colors.white : AppColors.textMuted, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    selected: isSelected,
                    selectedColor: AppColors.primaryLight,
                    backgroundColor: AppColors.scaffoldBg,
                    side: BorderSide(color: isSelected ? AppColors.primaryLight : Colors.white10),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedMuscle = muscle);
                        _fetchExercises(query: _searchController.text);
                      }
                    },
                  ),
                );
              },
            ),
          ),

          // --- RESULTS GRID ---
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryLight))
                : _exercises.isEmpty
                ? const Center(child: Text("No exercises found.", style: TextStyle(color: AppColors.textMuted)))
                : GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _exercises.length,
              itemBuilder: (context, index) {
                final ex = _exercises[index];
                return GestureDetector(
                  onTap: () => _showExerciseDetails(ex),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // IMAGE
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            child: CachedNetworkImage(
                              imageUrl: _buildImageUrl(ex['gif_url'] ?? ''),
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                              errorWidget: (context, url, error) => Container(color: Colors.black26, child: const Icon(Icons.image_not_supported, color: Colors.white24)),
                            ),
                          ),
                        ),
                        // TEXT INFO
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ex['name'].toString().toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Target: ${ex['muscles'] ?? 'Full Body'}',
                                style: const TextStyle(color: AppColors.primaryLight, fontSize: 10, fontWeight: FontWeight.w600),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}