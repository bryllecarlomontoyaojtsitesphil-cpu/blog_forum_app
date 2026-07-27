import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';
import '../models/post_model.dart';
import '../utils/constants.dart';
import 'supabase_service.dart';

class PostService {
  final SupabaseClient _client = SupabaseService.client;

  /// Paginated fetch, newest first.
  Future<List<PostModel>> fetchPosts({
    required int page,
    int pageSize = AppConstants.postsPageSize,
  }) async {
    final from = page * pageSize;
    final to = from + pageSize - 1;

    final response = await _client
        .from(AppConstants.postsTable)
        .select()
        .order('created_at', ascending: false)
        .range(from, to);

    return _withAuthorDisplayNames(
      (response as List)
        .map((e) => PostModel.fromJson(e as Map<String, dynamic>))
      .toList(),
    );
  }

  Future<PostModel> fetchPostById(String id) async {
    final response = await _client
        .from(AppConstants.postsTable)
        .select()
        .eq('id', id)
        .single();
    final post = PostModel.fromJson(response);
    return (await _withAuthorDisplayNames([post])).first;
  }

  Future<PostModel> createPost({
    required String userId,
    required String title,
    required String content,
    required List<String> images,
  }) async {
    final response = await _client
        .from(AppConstants.postsTable)
        .insert({
          'user_id': userId,
          'title': title,
          'content': content,
          'images': images,
        })
        .select()
        .single();
    final post = PostModel.fromJson(response);
    return (await _withAuthorDisplayNames([post])).first;
  }

  Future<PostModel> updatePost({
    required String id,
    required String title,
    required String content,
    required List<String> images,
  }) async {
    final response = await _client
        .from(AppConstants.postsTable)
        .update({
          'title': title,
          'content': content,
          'images': images,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id)
        .select()
        .single();
    final post = PostModel.fromJson(response);
      return (await _withAuthorDisplayNames([post])).first;
  }

  Future<void> deletePost(String id) async {
    await _client.from(AppConstants.postsTable).delete().eq('id', id);
  }

  Future<List<PostModel>> _withAuthorDisplayNames(List<PostModel> posts) async {
    final userIds = posts.map((post) => post.userId).toSet().toList();
    if (userIds.isEmpty) return posts;

    final profileRows = await _client
        .from(AppConstants.profilesTable)
        .select()
        .inFilter('id', userIds);

    final profileById = {
      for (final row in (profileRows as List).cast<Map<String, dynamic>>())
        row['id'] as String: ProfileModel.fromJson(row).displayName,
    };

    return posts
        .map(
          (post) => post.copyWith(authorEmail: profileById[post.userId]),
        )
        .toList();
  }
}
