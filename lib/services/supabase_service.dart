import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Thin wrapper around the Supabase client plus reusable storage helpers
/// used by both posts and comments (multi-image upload/delete).
class SupabaseService {
  SupabaseService._();

  static SupabaseClient get client => Supabase.instance.client;

  static const _uuid = Uuid();

  /// Uploads a list of picked images to [bucket] under a folder named
  /// after the current user's id, and returns their public URLs.
  static Future<List<String>> uploadImages({
    required String bucket,
    required List<XFile> files,
  }) async {
    final userId = client.auth.currentUser?.id ?? 'anonymous';
    final urls = <String>[];

    for (final file in files) {
      final bytes = await file.readAsBytes();
      final ext = _extensionFromName(file.name);
      final path = '$userId/${_uuid.v4()}.$ext';

      await client.storage.from(bucket).uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      urls.add(client.storage.from(bucket).getPublicUrl(path));
    }

    return urls;
  }

  /// Deletes a single image given its public URL.
  static Future<void> deleteImage({
    required String bucket,
    required String url,
  }) async {
    final path = _pathFromPublicUrl(bucket: bucket, url: url);
    if (path == null) return;
    await client.storage.from(bucket).remove([path]);
  }

  /// Deletes multiple images given their public URLs (best-effort).
  static Future<void> deleteImages({
    required String bucket,
    required List<String> urls,
  }) async {
    final paths = urls
        .map((u) => _pathFromPublicUrl(bucket: bucket, url: u))
        .whereType<String>()
        .toList();
    if (paths.isEmpty) return;
    await client.storage.from(bucket).remove(paths);
  }

  static String _extensionFromName(String name) {
    final parts = name.split('.');
    if (parts.length > 1 && parts.last.length <= 5) return parts.last;
    return 'jpg';
  }

  static String? _pathFromPublicUrl({
    required String bucket,
    required String url,
  }) {
    // Public URLs look like:
    // https://xxx.supabase.co/storage/v1/object/public/<bucket>/<path>
    final marker = '/object/public/$bucket/';
    final idx = url.indexOf(marker);
    if (idx == -1) return null;
    return url.substring(idx + marker.length);
  }
}
