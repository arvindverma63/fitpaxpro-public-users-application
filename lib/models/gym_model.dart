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

  // Newly added fields for more data density
  final String status;
  final String createdAt;
  final String searchRadius;

  Gym({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.rating,
    required this.address,
    required this.phone,
    required this.email,
    required this.isSponsored,
    required this.isVerified,
    required this.description,
    this.memberCountLimit,
    required this.galleryImages,
    required this.status,
    required this.createdAt,
    required this.searchRadius,
  });

  factory Gym.fromJson(Map<String, dynamic> json) {
    List<String> extractedImages = [];
    if (json['gallery_media'] != null && json['gallery_media'] is List) {
      for (var media in json['gallery_media']) {
        if (media['file_path'] != null) extractedImages.add(media['file_path']);
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
      // New fields
      status: json['status'] ?? 'Unknown',
      createdAt: json['created_at'] != null ? json['created_at'].toString().split('T')[0] : 'N/A',
      searchRadius: json['search_radius_km']?.toString() ?? '10',
    );
  }
}