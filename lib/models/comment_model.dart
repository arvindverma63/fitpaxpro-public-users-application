class VideoComment {
  final String id;
  final String content;
  final String authorName;
  final String createdAt;

  VideoComment({required this.id, required this.content, required this.authorName, required this.createdAt});

  factory VideoComment.fromJson(Map<String, dynamic> json) {
    return VideoComment(
      id: json['id'] ?? '',
      content: json['content'] ?? '',
      // Adjust these fields based on your actual user relational data in the comment API
      authorName: json['user']?['name'] ?? 'User',
      createdAt: json['created_at'] != null ? json['created_at'].toString().split('T')[0] : 'Just now',
    );
  }
}