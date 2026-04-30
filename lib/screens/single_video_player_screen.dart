import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt_explode;
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

import '../models/video_model.dart';
import '../theme/app_colors.dart';

class SingleVideoPlayerScreen extends StatefulWidget {
  final GymVideo video;

  const SingleVideoPlayerScreen({super.key, required this.video});

  @override
  State<SingleVideoPlayerScreen> createState() => _SingleVideoPlayerScreenState();
}

class _SingleVideoPlayerScreenState extends State<SingleVideoPlayerScreen> {
  late YoutubePlayerController _controller;
  final yt_explode.YoutubeExplode _yt = yt_explode.YoutubeExplode();

  String? _videoId;
  String? _liveTitle;
  String? _liveDescription;
  String? _liveViews;
  bool _isLoadingMetadata = true;

  @override
  void initState() {
    super.initState();
    _videoId = _extractVideoId(widget.video.url);

    // 1. Initialize Player
    _controller = YoutubePlayerController(
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        mute: false,
        origin: 'https://www.youtube.com',
      ),
    );

    // 2. Load Video with Delay (Fixes setSize error)
    Future.delayed(const Duration(milliseconds: 600), () {
      if (_videoId != null && mounted) {
        _controller.loadVideoById(videoId: _videoId!);
        _fetchLiveMetadata();
      }
    });
  }

  // Fetches the real Title and Description from YouTube
  Future<void> _fetchLiveMetadata() async {
    if (_videoId == null) return;
    try {
      var videoData = await _yt.videos.get(_videoId!);
      if (mounted) {
        setState(() {
          _liveTitle = videoData.title;
          _liveDescription = videoData.description;
          _liveViews = NumberFormat.compact().format(videoData.engagement.viewCount);
          _isLoadingMetadata = false;
        });
      }
    } catch (e) {
      debugPrint("Metadata Fetch Error: $e");
      if (mounted) setState(() => _isLoadingMetadata = false);
    }
  }

  String? _extractVideoId(String url) {
    try {
      final cleanUrl = url.split('?').first;
      final RegExp regExp = RegExp(r'.*(?:youtu.be\/|v\/|u\/\w\/|embed\/|watch\?v=|\&v=)([^#\&\?]*).*');
      final match = regExp.firstMatch(cleanUrl);
      return (match != null && match.groupCount >= 1) ? match.group(1) : null;
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _controller.close();
    _yt.close();
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
      ),
      body: Column(
        children: [
          // 1. VIDEO PLAYER
          SizedBox(
            width: double.infinity,
            child: YoutubePlayer(controller: _controller, backgroundColor: Colors.black),
          ),

          // 2. LIVE DATA SECTION
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title (Live or Fallback)
                  Text(
                    _liveTitle ?? widget.video.title,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  // View Count & Gym Info
                  Row(
                    children: [
                      const Icon(Icons.remove_red_eye, color: AppColors.textMuted, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        _isLoadingMetadata ? 'Loading views...' : '$_liveViews Views',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                      ),
                      const SizedBox(width: 20),
                      const Icon(Icons.fitness_center, color: AppColors.primaryLight, size: 16),
                      const SizedBox(width: 6),
                      Text(widget.video.gymName, style: const TextStyle(color: AppColors.primaryLight, fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Description Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Description', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Text(
                          _isLoadingMetadata
                              ? 'Fetching description...'
                              : (_liveDescription?.isNotEmpty == true ? _liveDescription! : 'No description provided.'),
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 14, height: 1.5),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Fallback Button
                  Center(
                    child: TextButton.icon(
                      onPressed: () => launchUrl(Uri.parse(widget.video.url), mode: LaunchMode.externalApplication),
                      icon: const Icon(Icons.open_in_new, size: 16, color: AppColors.textMuted),
                      label: const Text('Open in YouTube', style: TextStyle(color: AppColors.textMuted)),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}