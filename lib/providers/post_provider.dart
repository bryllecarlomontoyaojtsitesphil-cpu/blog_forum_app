import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';
import '../services/supabase_service.dart';
import '../utils/constants.dart';
import 'dart:math';

class PostProvider extends ChangeNotifier {
  final PostService _service = PostService();

  List<PostModel> posts = [];
  bool isLoading = false;
  bool isLoadingMore = false;
  bool hasMore = true;
  String? errorMessage;
  int _page = 0;

  Future<void> fetchInitial() async {
  _page = 0;
  hasMore = true;
  isLoading = true;
  errorMessage = null;
  notifyListeners();

  try {
    final result = await _service.fetchPosts(page: _page);
    result.shuffle(Random());
    posts = result;
    hasMore = result.length == AppConstants.postsPageSize;
    _page++;
  } catch (e) {
    errorMessage = e.toString();
  }

  isLoading = false;
  notifyListeners();
}

  Future<void> fetchMore() async {
    if (isLoadingMore || !hasMore) return;
    isLoadingMore = true;
    notifyListeners();

    try {
      final result = await _service.fetchPosts(page: _page);
      posts.addAll(result);
      hasMore = result.length == AppConstants.postsPageSize;
      _page++;
    } catch (e) {
      errorMessage = e.toString();
    }

    isLoadingMore = false;
    notifyListeners();
  }

  /// Uploads [newImages] and creates the post. Returns the created post,
  /// or null on failure (see [errorMessage]).
  Future<PostModel?> createPost({
    required String userId,
    required String title,
    required String content,
    required List<XFile> newImages,
  }) async {
    try {
      final urls = await SupabaseService.uploadImages(
        bucket: AppConstants.postImagesBucket,
        files: newImages,
      );
      final post = await _service.createPost(
        userId: userId,
        title: title,
        content: content,
        images: urls,
      );
      posts.insert(0, post);
      notifyListeners();
      return post;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Updates a post: uploads any newly-picked images, deletes any images
  /// the user removed, and merges the final image list.
  Future<PostModel?> updatePost({
    required PostModel original,
    required String title,
    required String content,
    required List<String> keptExistingImages,
    required List<XFile> newImages,
  }) async {
    try {
      final removedImages = original.images
          .where((url) => !keptExistingImages.contains(url))
          .toList();

      if (removedImages.isNotEmpty) {
        await SupabaseService.deleteImages(
          bucket: AppConstants.postImagesBucket,
          urls: removedImages,
        );
      }

      final uploadedUrls = await SupabaseService.uploadImages(
        bucket: AppConstants.postImagesBucket,
        files: newImages,
      );

      final finalImages = [...keptExistingImages, ...uploadedUrls];

      final updated = await _service.updatePost(
        id: original.id,
        title: title,
        content: content,
        images: finalImages,
      );

      final idx = posts.indexWhere((p) => p.id == updated.id);
      if (idx != -1) posts[idx] = updated;
      notifyListeners();
      return updated;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> deletePost(PostModel post) async {
    try {
      if (post.images.isNotEmpty) {
        await SupabaseService.deleteImages(
          bucket: AppConstants.postImagesBucket,
          urls: post.images,
        );
      }
      await _service.deletePost(post.id);
      posts.removeWhere((p) => p.id == post.id);
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
