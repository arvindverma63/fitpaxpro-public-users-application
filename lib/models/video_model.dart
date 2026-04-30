class GymVideo {
  final String id;
  final String gymId;
  final String gymName; // NEW
  final String city;    // NEW
  final String title;
  final String url;
  final bool isMainVideo;
  bool isLiked;
  int likesCount;
  int commentsCount;

  GymVideo({
    required this.id, required this.gymId, required this.gymName, required this.city,
    required this.title, required this.url, required this.isMainVideo,
    this.isLiked = false, this.likesCount = 0, this.commentsCount = 0,
  });

  factory GymVideo.fromJson(Map<String, dynamic> json) {
    return GymVideo(
      id: json['id']?.toString() ?? '',
      gymId: json['gym_id']?.toString() ?? '',
      gymName: json['gym_name'] ?? 'Unknown Gym', // Catching the gym name
      city: json['gym_details']?['city'] ?? '',   // Catching the city
      title: json['video_title'] ?? json['title'] ?? 'Gym Video',
      url: json['video_url'] ?? json['url'] ?? json['file_path'] ?? '',
      isMainVideo: json['is_main_video'] == 1 || json['is_main_video'] == true,
      isLiked: json['is_liked'] == 1 || json['is_liked'] == true,
      likesCount: int.tryParse(json['likes_count']?.toString() ?? '0') ?? 0,
      commentsCount: int.tryParse(json['comments_count']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gym_id': gymId,
      'gym_name': gymName,
      'video_title': title,
      'video_url': url,
      'likes_count': likesCount,
      'comments_count': commentsCount,
      'is_liked': isLiked,
      'gym_details': {'city': city},
    };
  }
}