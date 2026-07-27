class PostModel {
  final String id;
  final String userId;
  final String title;
  final String content;
  final List<String> images;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? authorEmail;

  PostModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.images,
    required this.createdAt,
    this.updatedAt,
    this.authorEmail,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      images: (json['images'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      authorEmail: json['author_email'] as String?,
    );
  }

  Map<String, dynamic> toInsertJson({required String userId}) => {
        'user_id': userId,
        'title': title,
        'content': content,
        'images': images,
      };

  Map<String, dynamic> toUpdateJson() => {
        'title': title,
        'content': content,
        'images': images,
        'updated_at': DateTime.now().toIso8601String(),
      };

  PostModel copyWith({
    String? title,
    String? content,
    List<String>? images,
    String? authorEmail,
  }) {
    return PostModel(
      id: id,
      userId: userId,
      title: title ?? this.title,
      content: content ?? this.content,
      images: images ?? this.images,
      createdAt: createdAt,
      updatedAt: updatedAt,
      authorEmail: authorEmail ?? this.authorEmail,
    );
  }
}