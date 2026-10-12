class ListingDraft {
  final String title;
  final String category;
  final String description;
  final String? imagePath;

  const ListingDraft({
    required this.title,
    required this.category,
    required this.description,
    this.imagePath,
  });

  // ฟังก์ชันแปลง JSON จาก Gemini AI ให้เป็น ListingDraft
  factory ListingDraft.fromJson(Map<String, dynamic> json) {
    return ListingDraft(
      title: json['title'] as String? ?? '',
      category: json['category'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imagePath: json['imagePath'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'category': category,
      'description': description,
      'imagePath': imagePath,
    };
  }
}