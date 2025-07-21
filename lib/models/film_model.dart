class Film {
  final int id;
  final String title;
  final String img;
  final String description;
  final String createdAt;
  final List<String> categories;

  Film({
    required this.id,
    required this.title,
    required this.img,
    required this.description,
    required this.createdAt,
    required this.categories,
  });

  factory Film.fromJson(Map<String, dynamic> json) {
    return Film(
      id: json['id'],
      title: json['title'],
      img: json['img'] ?? '',
      description: json['description'],
      createdAt: json['created_at'],
      categories: List<String>.from(json['categories'] ?? []),
    );
  }
}
