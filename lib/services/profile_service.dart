import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';
import '../utils/constants.dart';
import 'supabase_service.dart';

class ProfileService {
  final SupabaseClient _client = SupabaseService.client;

  Future<ProfileModel> fetchProfile(String userId) async {
    final data = await _client
        .from(AppConstants.profilesTable)
        .select()
        .eq('id', userId)
        .single();
    return ProfileModel.fromJson(data);
  }

  /// Updates whichever fields are provided. Pass [clearAvatar] true to set
  /// avatar_url back to null (distinct from leaving it untouched).
  Future<ProfileModel> updateProfile({
    required String userId,
    String? username,
    String? avatarUrl,
    bool clearAvatar = false,
  }) async {
    final updates = <String, dynamic>{};
    if (username != null) updates['username'] = username;
    if (clearAvatar) {
      updates['avatar_url'] = null;
    } else if (avatarUrl != null) {
      updates['avatar_url'] = avatarUrl;
    }

    if (updates.isEmpty) {
      return fetchProfile(userId);
    }

    final data = await _client
        .from(AppConstants.profilesTable)
        .update(updates)
        .eq('id', userId)
        .select()
        .single();
    return ProfileModel.fromJson(data);
  }
}