import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/ai_api_service.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../models/video_model.dart';
import 'single_video_player_screen.dart';

class AllVideosScreen extends StatefulWidget {
  const AllVideosScreen({super.key});

  @override
  State<AllVideosScreen> createState() => _AllVideosScreenState();
}

class _AllVideosScreenState extends State<AllVideosScreen> {
  final AiApiService _aiService = AiApiService();
  final ApiService _apiService = ApiService();

  // Exercise State
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _exercises = [];
  bool _isLoadingExercises = true;
  
  // Filters
  String _selectedMuscle = 'All';
  String _selectedCategory = 'All';
  String _selectedDifficulty = 'All';
  
  final List<String> _muscleGroups = [
    'All', 'Chest', 'Back', 'Shoulders', 'Biceps', 'Triceps', 'Legs', 'Abs', 'Glutes'
  ];
  final List<String> _categories = [
    'All', 'Strength', 'Cardio', 'Yoga', 'Stretching', 'Poses'
  ];
  final List<String> _difficulties = [
    'All', 'Beginner', 'Intermediate', 'Advanced'
  ];

  // Video State
  List<GymVideo> _videos = [];
  bool _isLoadingVideos = true;

  @override
  void initState() {
    super.initState();
    _fetchVideos();
    _fetchExercises();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- FETCH DATA ---

  Future<void> _fetchVideos() async {
    setState(() => _isLoadingVideos = true);
    debugPrint('🌐 [Discover] Fetching videos from: ${ApiService.baseUrl}/gym/videos');
    try {
      final videos = await _apiService.fetchAllVideos();
      if (mounted) {
        setState(() {
          _videos = videos;
          _isLoadingVideos = false;
        });
      }
    } catch (e) {
      debugPrint('🚨 [Discover] Video Fetch Error: $e');
      if (mounted) setState(() => _isLoadingVideos = false);
    }
  }

  Future<void> _fetchExercises({String? query}) async {
    setState(() => _isLoadingExercises = true);
    try {
      final results = await _apiService.fetchExercises(
        search: query ?? _searchController.text,
        muscleGroup: _selectedMuscle,
        category: _selectedCategory,
        difficulty: _selectedDifficulty,
      );
      if (mounted) {
        setState(() {
          _exercises = results;
          _isLoadingExercises = false;
        });
      }
    } catch (e) {
      debugPrint('🚨 [Discover] Exercise Fetch Error: $e');
      if (mounted) setState(() => _isLoadingExercises = false);
    }
  }

  String _buildExerciseImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return 'https://chocolate-viper-895188.hostingersite.com/storage/$path';
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBg,
        appBar: AppBar(
          backgroundColor: AppColors.scaffoldBg,
          elevation: 0,
          scrolledUnderElevation: 0,
          toolbarHeight: 80,
          title: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Discover'.toUpperCase(),
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  'Workouts & Exercises',
                  style: TextStyle(
                    color: AppColors.textMain,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ],
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.borderColor),
              ),
              child: TabBar(
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(26),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textMuted,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                tabs: const [
                  Tab(text: 'VIDEOS'),
                  Tab(text: 'EXERCISES'),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildVideosTab(),
            _buildExercisesTab(),
          ],
        ),
      ),
    );
  }

  // --- VIDEOS TAB ---

  Widget _buildVideosTab() {
    if (_isLoadingVideos) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryLight));
    }

    if (_videos.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchVideos,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(child: Text("No videos found.", style: TextStyle(color: AppColors.textMuted))),
          ),
        ),
      );
    }

    final mainVideos = _videos.where((v) => v.isMainVideo).toList();
    final otherVideos = _videos.where((v) => !v.isMainVideo).toList();

    return RefreshIndicator(
      onRefresh: _fetchVideos,
      color: AppColors.primaryLight,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (mainVideos.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildFeaturedSection(mainVideos),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final video = otherVideos.isEmpty ? _videos[index] : otherVideos[index];
                  return _buildVideoCard(video);
                },
                childCount: otherVideos.isEmpty ? _videos.length : otherVideos.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedSection(List<GymVideo> featured) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Text(
            'FEATURED WORKOUTS',
            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.5),
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: featured.length,
            itemBuilder: (context, index) => _buildFeaturedCard(featured[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedCard(GymVideo video) {
    final youtubeId = _extractVideoId(video.url);
    final thumb = youtubeId != null ? 'https://img.youtube.com/vi/$youtubeId/maxresdefault.jpg' : '';

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SingleVideoPlayerScreen(video: video))),
      child: Container(
        width: 300,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          image: DecorationImage(image: CachedNetworkImageProvider(thumb), fit: BoxFit.cover),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(6)),
                child: const Text('NEW', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              Text(video.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text('${video.gymName} • ${video.city}', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoCard(GymVideo video) {
    String? youtubeId = _extractVideoId(video.url);
    String thumbnailUrl = youtubeId != null ? 'https://img.youtube.com/vi/$youtubeId/mqdefault.jpg' : '';

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SingleVideoPlayerScreen(video: video))),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderColor),
          boxShadow: [
            if (!AppColors.isDark)
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: thumbnailUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: AppColors.borderColor.withOpacity(0.1)),
                errorWidget: (context, url, error) => Container(color: Colors.black26, child: const Icon(Icons.play_circle_outline, color: Colors.white24, size: 40)),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(video.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.favorite_rounded, color: AppColors.primary, size: 12),
                        const SizedBox(width: 4),
                        Text('${video.likesCount}', style: const TextStyle(color: Colors.white70, fontSize: 10)),
                        const SizedBox(width: 12),
                        const Icon(Icons.comment_rounded, color: Colors.white70, size: 12),
                        const SizedBox(width: 4),
                        Text('${video.commentsCount}', style: const TextStyle(color: Colors.white70, fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- EXERCISES TAB ---

  Widget _buildExercisesTab() {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderColor),
              boxShadow: [
                if (!AppColors.isDark)
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: AppColors.textMain),
              decoration: InputDecoration(
                hintText: 'Search exercises...',
                hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
                prefixIcon: Icon(Icons.search_rounded, color: AppColors.primaryLight),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onSubmitted: (val) => _fetchExercises(query: val),
            ),
          ),
        ),
        // Multi-Filter Row
        _buildFilterChips(),
        const SizedBox(height: 16),
        // Exercise Grid
        Expanded(
          child: _isLoadingExercises
              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryLight))
              : _exercises.isEmpty
                  ? Center(child: Text("No exercises found.", style: TextStyle(color: AppColors.textMuted)))
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.85,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: _exercises.length,
                      itemBuilder: (context, index) {
                        final ex = _exercises[index];
                        return _buildExerciseCard(ex);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return Column(
      children: [
        _buildFilterRow('Muscle', _muscleGroups, _selectedMuscle, (val) {
          setState(() => _selectedMuscle = val);
          _fetchExercises();
        }),
        const SizedBox(height: 8),
        _buildFilterRow('Category', _categories, _selectedCategory, (val) {
          setState(() => _selectedCategory = val);
          _fetchExercises();
        }),
      ],
    );
  }

  Widget _buildFilterRow(String label, List<String> options, String selectedValue, Function(String) onSelected) {
    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: options.length,
        itemBuilder: (context, index) {
          final option = options[index];
          final isSelected = selectedValue == option;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () => onSelected(option),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? AppColors.primary : AppColors.borderColor),
                ),
                alignment: Alignment.center,
                child: Text(
                  option,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textMain,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  Widget _buildExerciseCard(Map<String, dynamic> ex) {
    final name = ex['exercise_name'] ?? 'Exercise';
    final category = ex['exercise_category'] ?? 'General';
    final muscle = ex['target_muscle_group'] ?? 'Full Body';
    final image = _buildExerciseImageUrl(ex['image_path']);
    final difficulty = ex['difficulty_level'] ?? 'Beginner';

    return GestureDetector(
      onTap: () => _showExerciseDetails(ex),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.borderColor),
          boxShadow: [
            if (!AppColors.isDark)
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 6)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      child: Hero(
                        tag: 'exercise_${ex['id']}',
                        child: CachedNetworkImage(
                          imageUrl: image,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: AppColors.borderColor.withOpacity(0.1)),
                          errorWidget: (context, url, error) => Container(
                            color: AppColors.borderColor.withOpacity(0.05),
                            child: Icon(Icons.fitness_center_rounded, color: AppColors.textMuted.withOpacity(0.5), size: 32),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            difficulty.toString().toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(color: AppColors.textMain, fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          category.toString().toUpperCase(),
                          style: const TextStyle(color: AppColors.primary, fontSize: 8, fontWeight: FontWeight.w900),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          muscle,
                          style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // --- HELPERS ---

  String? _extractVideoId(String url) {
    if (url.isEmpty) return null;
    try {
      final RegExp regExp = RegExp(
        r'^.*((youtu.be\/)|(v\/)|(\/u\/\w\/)|(embed\/)|(watch\?))\??v?=?([^#\&\?]*).*',
        caseSensitive: false,
        multiLine: false,
      );
      final match = regExp.firstMatch(url);
      if (match != null && match.groupCount >= 7) {
        final id = match.group(7);
        if (id != null && id.length == 11) return id;
      }
      
      // Fallback for short links
      if (url.contains('youtu.be/')) {
        return url.split('youtu.be/').last.split('?').first;
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  void _showExerciseDetails(Map<String, dynamic> exercise) {
    final name = exercise['exercise_name'] ?? 'Exercise';
    final category = exercise['exercise_category'] ?? 'General';
    final muscle = exercise['target_muscle_group'] ?? 'Full Body';
    final image = _buildExerciseImageUrl(exercise['image_path']);
    final difficulty = exercise['difficulty_level'] ?? 'Normal';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.scaffoldBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textMuted.withOpacity(0.3), borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: CachedNetworkImage(
                  imageUrl: image,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (context, url) => Container(height: 250, color: AppColors.borderColor.withOpacity(0.1)),
                  errorWidget: (context, url, error) => Container(
                    height: 250,
                    color: AppColors.borderColor.withOpacity(0.05),
                    child: Icon(Icons.fitness_center_rounded, color: AppColors.textMuted.withOpacity(0.5), size: 64),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(name, style: TextStyle(color: AppColors.textMain, fontSize: 24, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildTag(category, AppColors.primary),
                  _buildTag(muscle, AppColors.verifiedIcon),
                  _buildTag(difficulty, AppColors.accent),
                ],
              ),
              const SizedBox(height: 32),
              Text('MUSCLE GROUPS', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1)),
              const SizedBox(height: 8),
              Text(muscle, style: TextStyle(color: AppColors.textMain, fontSize: 16, fontWeight: FontWeight.w600)),
              
              const SizedBox(height: 24),
              Text('EQUIPMENT', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1)),
              const SizedBox(height: 8),
              Text(exercise['equipment_type'] ?? 'No special equipment', style: TextStyle(color: AppColors.textMain, fontSize: 16, fontWeight: FontWeight.w600)),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withOpacity(0.5))),
      child: Text(text.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}