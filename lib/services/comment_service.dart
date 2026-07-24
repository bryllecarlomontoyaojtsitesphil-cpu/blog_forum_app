import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/comment_model.dart';
import '../utils/constants.dart';
import 'supabase_service.dart';

class CommentService {
  final SupabaseClient _client = SupabaseService.client;

  Future<List<CommentModel>> fetchComments(String postId) async {
    final response = await _client
        .from(AppConstants.commentsTable)
        .select()
        .eq('post_id', postId)
        .order('created_at', ascending: true);

    return (response as List)
        .map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CommentModel> addComment({
    required String postId,
    required String userId,
    required String content,
    required List<String> images,
  }) async {
    final response = await _client
        .from(AppConstants.commentsTable)
        .insert({
          'post_id': postId,
          'user_id': userId,
          'content': content,
          'images': images,
        })
        .select()
        .single();
    return CommentModel.fromJson(response);
  }

  Future<CommentModel> updateComment({
    required String id,
    required String content,
    required List<String> images,
  }) async {
    final response = await _client
        .from(AppConstants.commentsTable)
        .update({
          'content': content,
          'images': images,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id)
        .select()
        .single();
    return CommentModel.fromJson(response);
  }

  Future<void> deleteComment(String id) async {
    await _client.from(AppConstants.commentsTable).delete().eq('id', id);
  }
}
