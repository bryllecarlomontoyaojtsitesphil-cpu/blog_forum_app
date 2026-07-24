import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/comment_model.dart';
import '../services/comment_service.dart';
import '../services/supabase_service.dart';
import '../utils/constants.dart';

class CommentProvider extends ChangeNotifier {
  final CommentService _service = CommentService();

  List<CommentModel> comments = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> fetchComments(String postId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      comments = await _service.fetchComments(postId);
    } catch (e) {
      errorMessage = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  Future<bool> addComment({
    required String postId,
    required String userId,
    required String content,
    required List<XFile> images,
  }) async {
    try {
      final urls = await SupabaseService.uploadImages(
        bucket: AppConstants.commentImagesBucket,
        files: images,
      );
      final comment = await _service.addComment(
        postId: postId,
        userId: userId,
        content: content,
        images: urls,
      );
      comments.add(comment);
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateComment({
    required CommentModel original,
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
          bucket: AppConstants.commentImagesBucket,
          urls: removedImages,
        );
      }

      final uploadedUrls = await SupabaseService.uploadImages(
        bucket: AppConstants.commentImagesBucket,
        files: newImages,
      );

      final finalImages = [...keptExistingImages, ...uploadedUrls];

      final updated = await _service.updateComment(
        id: original.id,
        content: content,
        images: finalImages,
      );

      final idx = comments.indexWhere((c) => c.id == updated.id);
      if (idx != -1) comments[idx] = updated;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteComment(CommentModel comment) async {
    try {
      if (comment.images.isNotEmpty) {
        await SupabaseService.deleteImages(
          bucket: AppConstants.commentImagesBucket,
          urls: comment.images,
        );
      }
      await _service.deleteComment(comment.id);
      comments.removeWhere((c) => c.id == comment.id);
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
