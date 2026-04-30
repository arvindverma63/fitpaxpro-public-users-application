import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt_exp;
import 'package:intl/intl.dart';

import '../models/video_model.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import 'single_video_player_screen.dart';

class AllVideosScreen extends StatefulWidget {
  const AllVideosScreen({super.key});

  @override
  State<AllVideosScreen> createState() => _AllVideosScreenState();
}

class _AllVideosScreenState extends State<AllVideosScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<GymVideo> _allVideos = [];
  List<GymVideo> _filteredVideos = [];

  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchVideos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchVideos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final videos = await _apiService.fetchAllVideos();
      if (mounted) {
        setState(() {
          _allVideos = videos;
          _filteredVideos = videos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _runSearchFilter(String enteredKeyword) {
    setState(() {
      _filteredVideos = _allVideos.where((video) =>
      video.title.toLowerCase().contains(enteredKeyword.toLowerCase()) ||
          video.gymName.toLowerCase().contains(enteredKeyword.toLowerCase()) ||
          video.city.toLowerCase().contains(enteredKeyword.toLowerCase())
      ).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBg,
        elevation: 0,
        title: const Text(
          'Discover Videos',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textMain),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchVideos,
              color: AppColors.primaryLight,
              child: _isLoading ? _buildShimmerLoading() : _buildList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _runSearchFilter,
          style: const TextStyle(color: AppColors.textMain),
          decoration: const InputDecoration(
            hintText: 'Search workouts, gyms...',
            hintStyle: TextStyle(color: AppColors.textMuted),
            prefixIcon: Icon(Icons.search_rounded, color: AppColors.textMuted),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_filteredVideos.isEmpty) {
      return const Center(child: Text("No videos found", style: TextStyle(color: Colors.white)));
    }
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 120),
      itemCount: _filteredVideos.length,
      itemBuilder: (context, index) => SmartVideoCard(video: _filteredVideos[index]),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 3,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.white10,
        highlightColor: Colors.white24,
        child: Container(
          margin: const EdgeInsets.only(bottom: 24),
          height: 280,
          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }
}

class SmartVideoCard extends StatefulWidget {
  final GymVideo video;
  const SmartVideoCard({super.key, required this.video});

  @override
  State<SmartVideoCard> createState() => _SmartVideoCardState();
}

class _SmartVideoCardState extends State<SmartVideoCard> {
  final yt_exp.YoutubeExplode _yt = yt_exp.YoutubeExplode();
  String? _liveTitle;
  String? _liveViews;
  bool _fetchingLive = true;

  @override
  void initState() {
    super.initState();
    _fetchYouTubeData();
  }

  @override
  void dispose() {
    _yt.close();
    super.dispose();
  }

  Future<void> _fetchYouTubeData() async {
    try {
      final videoId = yt_exp.VideoId.parseVideoId(widget.video.url);
      var metadata = await _yt.videos.get(videoId);
      if (mounted) {
        setState(() {
          _liveTitle = metadata.title;
          _liveViews = NumberFormat.compact().format(metadata.engagement.viewCount);
          _fetchingLive = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _fetchingLive = false);
    }
  }

  String? _getThumb(String url) {
    try {
      final id = yt_exp.VideoId.parseVideoId(url);
      return 'https://img.youtube.com/vi/$id/maxresdefault.jpg';
    } catch (e) { return null; }
  }

  @override
  Widget build(BuildContext context) {
    final thumb = _getThumb(widget.video.url);

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => SingleVideoPlayerScreen(video: widget.video))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.network(thumb ?? '', height: 200, width: double.infinity, fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(height: 200, color: Colors.black)),
                  Container(height: 200, color: Colors.black26),
                  const CircleAvatar(
                    backgroundColor: Colors.black45,
                    child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 30),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.fitness_center, color: AppColors.primaryLight, size: 14),
                      const SizedBox(width: 6),
                      Text(widget.video.gymName.toUpperCase(),
                          style: const TextStyle(color: AppColors.primaryLight, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(_liveTitle ?? widget.video.title,
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.remove_red_eye_rounded, color: AppColors.textMuted, size: 14),
                      const SizedBox(width: 4),
                      Text(_liveViews ?? '...', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      const Spacer(),
                      Text(widget.video.city, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}