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

    // 1. Initialize Player with the ID immediately if available
    _controller = YoutubePlayerController.fromVideoId(
      videoId: _videoId ?? '',
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        mute: false,
        enableJavaScript: true,
      ),
    );

    if (_videoId != null) {
      _fetchLiveMetadata();
    }
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
    if (url.isEmpty) return null;
    try {
      // Improved robust extraction
      final RegExp regExp = RegExp(
        r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
        caseSensitive: false,
      );
      final match = regExp.firstMatch(url);
      return match?.group(1);
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
        backgroundColor: AppColors.scaffoldBg, // Changed from black for consistency
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textMain, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Video Player', style: TextStyle(color: AppColors.textMain, fontSize: 16)),
      ),
      body: Column(
        children: [
          // 1. VIDEO PLAYER
          if (_videoId != null)
            SizedBox(
              width: double.infinity,
              child: YoutubePlayer(controller: _controller, backgroundColor: Colors.black),
            )
          else
            Container(
              height: 200,
              width: double.infinity,
              color: Colors.black12,
              child: const Center(child: Text("Invalid Video ID", style: TextStyle(color: Colors.red))),
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
                    style: TextStyle(color: AppColors.textMain, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  // View Count & Gym Info
                  Row(
                    children: [
                      Icon(Icons.remove_red_eye, color: AppColors.textMuted, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        _isLoadingMetadata ? 'Loading views...' : '$_liveViews Views',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                      ),
                      const SizedBox(width: 20),
                      Icon(Icons.fitness_center, color: AppColors.primaryLight, size: 16),
                      const SizedBox(width: 6),
                      Text(widget.video.gymName, style: TextStyle(color: AppColors.primaryLight, fontSize: 13, fontWeight: FontWeight.bold)),
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
                      border: Border.all(color: AppColors.borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Description', style: TextStyle(color: AppColors.textMain, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Text(
                          _isLoadingMetadata
                              ? 'Fetching description...'
                              : (_liveDescription?.isNotEmpty == true ? _liveDescription! : 'No description provided.'),
                          style: TextStyle(color: AppColors.textMuted, fontSize: 14, height: 1.5),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Fallback Button
                  Center(
                    child: TextButton.icon(
                      onPressed: () => launchUrl(Uri.parse(widget.video.url), mode: LaunchMode.externalApplication),
                      icon: Icon(Icons.open_in_new, size: 16, color: AppColors.textMuted),
                      label: Text('Open in YouTube', style: TextStyle(color: AppColors.textMuted)),
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