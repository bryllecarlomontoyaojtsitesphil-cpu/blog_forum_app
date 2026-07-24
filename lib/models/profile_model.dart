class ProfileModel {
  final String id;
  final String? username;
  final String? avatarUrl;

  ProfileModel({required this.id, this.username, this.avatarUrl});

  String get displayName =>
      username != null && username!.trim().isNotEmpty
          ? username!
          : 'User${id.substring(0, 8)}';

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      username: json['username'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}