import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../models/gym_model.dart';
import '../models/video_model.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';

class GymVideosScreen extends StatefulWidget {
  final Gym gym;

  const GymVideosScreen({super.key, required this.gym});

  @override
  State<GymVideosScreen> createState() => _GymVideosScreenState();
}

class _GymVideosScreenState extends State<GymVideosScreen> {
  final ApiService _apiService = ApiService();
  YoutubePlayerController? _playerController;

  List<GymVideo> _videos = [];
  bool _isLoadingData = true;
  int _currentPlayingIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchGymSpecificVideos();
  }

  Future<void> _fetchGymSpecificVideos() async {
    try {
      // Fetch videos filtered by this specific gym's ID
      final videos = await _apiService.fetchGymVideos(widget.gym.id);
      if (mounted) {
        setState(() {
          _videos = videos;
          _isLoadingData = false;
        });
        if (videos.isNotEmpty) {
          _initializePlayer(videos[0].url);
        }
      }
    } catch (e) {
      debugPrint("Error fetching gym videos: $e");
      setState(() => _isLoadingData = false);
    }
  }

  void _initializePlayer(String url) {
    String? videoId = _extractVideoId(url);
    if (videoId == null) return;

    _playerController = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        mute: false,
      ),
    );
  }

  String? _extractVideoId(String url) {
    final cleanUrl = url.split('?').first;
    final RegExp regExp = RegExp(r'.*(?:youtu.be\/|v\/|u\/\w\/|embed\/|watch\?v=|\&v=)([^#\&\?]*).*');
    final match = regExp.firstMatch(cleanUrl);
    return (match != null && match.groupCount >= 1) ? match.group(1) : null;
  }

  void _switchVideo(int index) {
    if (_currentPlayingIndex == index) return;

    final videoId = _extractVideoId(_videos[index].url);
    if (videoId != null) {
      setState(() {
        _currentPlayingIndex = index;
      });
      _playerController?.loadVideoById(videoId: videoId);
    }
  }

  @override
  void dispose() {
    _playerController?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${widget.gym.name} Gallery',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryLight))
          : _videos.isEmpty
          ? const Center(child: Text('No videos available for this gym.', style: TextStyle(color: Colors.white54)))
          : Column(
        children: [
          // 1. THE PLAYER
          if (_playerController != null)
            YoutubePlayer(
              controller: _playerController!,
              backgroundColor: Colors.black,
            ),

          // 2. GYM BRANDING & PLAYLIST
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _videos[_currentPlayingIndex].title,
                        style: const TextStyle(color: AppColors.textMain, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, color: AppColors.textMuted, size: 14),
                          const SizedBox(width: 4),
                          Text(widget.gym.address, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 30, 20, 10),
                  child: Text('All Videos', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                ...List.generate(_videos.length, (index) => _buildPlaylistItem(index)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistItem(int index) {
    final video = _videos[index];
    final isPlaying = _currentPlayingIndex == index;
    final videoId = _extractVideoId(video.url);
    final thumbnailUrl = videoId != null ? 'https://img.youtube.com/vi/$videoId/mqdefault.jpg' : '';

    return GestureDetector(
      onTap: () => _switchVideo(index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isPlaying ? AppColors.primary.withOpacity(0.1) : AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isPlaying ? AppColors.primaryLight : Colors.white10),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(thumbnailUrl, width: 100, height: 60, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(width: 100, height: 60, color: Colors.black26)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: isPlaying ? AppColors.primaryLight : AppColors.textMain, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isPlaying ? 'Now Playing' : 'Tap to watch',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}