class CommentModel {
  final String id;
  final String postId;
  final String userId;
  final String content;
  final List<String> images;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? authorEmail;

  CommentModel({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    required this.images,
    required this.createdAt,
    this.updatedAt,
    this.authorEmail,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      userId: json['user_id'] as String,
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

  Map<String, dynamic> toInsertJson({
    required String postId,
    required String userId,
  }) =>
      {
        'post_id': postId,
        'user_id': userId,
        'content': content,
        'images': images,
      };

  Map<String, dynamic> toUpdateJson() => {
        'content': content,
        'images': images,
        'updated_at': DateTime.now().toIso8601String(),
      };

  CommentModel copyWith({
    String? content,
    List<String>? images,
    String? authorEmail,
  }) {
    return CommentModel(
      id: id,
      postId: postId,
      userId: userId,
      content: content ?? this.content,
      images: images ?? this.images,
      createdAt: createdAt,
      updatedAt: updatedAt,
      authorEmail: authorEmail ?? this.authorEmail,
    );
  }
}
