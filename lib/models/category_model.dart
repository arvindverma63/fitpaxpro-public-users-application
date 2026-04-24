class GymCategory {
  final String id;
  final String name;
  final String slug;
  final String iconClass;

  GymCategory({
    required this.id,
    required this.name,
    required this.slug,
    required this.iconClass
  });

  factory GymCategory.fromJson(Map<String, dynamic> json) {
    return GymCategory(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown',
      slug: json['slug'] ?? '',
      // Default to a generic app grid icon if the backend sends null
      iconClass: json['icon_class'] ?? 'mdi-apps',
    );
  }
}