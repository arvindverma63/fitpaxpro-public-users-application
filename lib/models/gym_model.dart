class Gym {
  final String id;
  final String name;
  final String imageUrl;
  final double rating;
  final String address;
  final String phone;
  final String email;
  final bool isSponsored;
  final bool isVerified;
  final String description;
  final int? memberCountLimit;
  final List<String> galleryImages;
  final String status;
  final String createdAt;
  final String searchRadius;

  // NEW: List to hold YouTube URLs
  final List<String> youtubeLinks;

  Gym({
    required this.id, required this.name, required this.imageUrl, required this.rating,
    required this.address, required this.phone, required this.email, required this.isSponsored,
    required this.isVerified, required this.description, this.memberCountLimit,
    required this.galleryImages, required this.status, required this.createdAt,
    required this.searchRadius, required this.youtubeLinks,
  });

  factory Gym.fromJson(Map<String, dynamic> json) {
    List<String> extractedImages = [];
    List<String> extractedVideos = [];

    // Extract images & videos from gallery_media
    if (json['gallery_media'] != null && json['gallery_media'] is List) {
      for (var media in json['gallery_media']) {
        if (media['file_path'] != null) {
          // Check if it is a youtube video to avoid crashing Image.network
          if (media['file_type'] == 'youtube' || media['file_path'].toString().contains('youtu')) {
            extractedVideos.add(media['file_path']);
          } else {
            extractedImages.add(media['file_path']);
          }
        }
      }
    }

    // Extract from specific youtube_video_links array
    if (json['youtube_video_links'] != null && json['youtube_video_links'] is List) {
      for (var video in json['youtube_video_links']) {
        if (video['url'] != null) extractedVideos.add(video['url']);
      }
    }

    String mainImage = 'https://via.placeholder.com/400?text=No+Image';
    if (json['image_url'] != null && json['image_url'].toString().isNotEmpty) {
      mainImage = json['image_url'];
      if (!extractedImages.contains(mainImage)) extractedImages.insert(0, mainImage);
    } else if (extractedImages.isNotEmpty) {
      mainImage = extractedImages[0];
    }

    return Gym(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown Gym',
      imageUrl: mainImage,
      rating: double.tryParse(json['rating_avg']?.toString() ?? '0.0') ?? 0.0,
      address: json['address'] ?? 'Address not available',
      phone: json['phone'] ?? 'N/A',
      email: json['email'] ?? 'N/A',
      isSponsored: json['is_sponsored'] == true,
      isVerified: json['is_verified'] == true,
      description: json['description'] ?? 'No description provided.',
      memberCountLimit: json['member_count_limit'],
      galleryImages: extractedImages,
      status: json['status'] ?? 'Unknown',
      createdAt: json['created_at'] != null ? json['created_at'].toString().split('T')[0] : 'N/A',
      searchRadius: json['search_radius_km']?.toString() ?? '10',

      // Remove duplicates from the video list
      youtubeLinks: extractedVideos.toSet().toList(),
    );
  }
}