import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../services/supabase_service.dart';
import '../utils/constants.dart';
import '../models/profile_model.dart';

/// Holds auth state and doubles as a [ChangeNotifier] that go_router can
/// listen to (via `refreshListenable`) so routes re-evaluate on login/logout.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final ProfileService _profileService = ProfileService();
  StreamSubscription<AuthState>? _authSub;

  bool isLoading = false;
  bool isUpdatingProfile = false;
  String? errorMessage;
  ProfileModel? currentProfile;

  AuthProvider() {
    // Re-notify listeners (including the router) whenever auth state changes.
    _authSub = _authService.onAuthStateChange.listen((_) async {
      await _loadProfile();
      notifyListeners();
    });
    _loadProfile();
  }

  User? get currentUser => _authService.currentUser;
  bool get isLoggedIn => currentUser != null;

  Future<void> _loadProfile() async {
    final user = currentUser;
    if (user == null) {
      currentProfile = null;
      return;
    }
    try {
      currentProfile = await _profileService.fetchProfile(user.id);
    } catch (_) {
      currentProfile = null;
    }
  }

  Future<bool> register({required String email, required String password}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final error = await _authService.signUp(email: email, password: password);
    if (error == null) await _loadProfile();

    isLoading = false;
    errorMessage = error;
    notifyListeners();
    return error == null;
  }

  Future<bool> login({required String email, required String password}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final error = await _authService.signIn(email: email, password: password);
    if (error == null) await _loadProfile();

    isLoading = false;
    errorMessage = error;
    notifyListeners();
    return error == null;
  }

  Future<void> logout() async {
    await _authService.signOut();
    currentProfile = null;
    notifyListeners();
  }

  /// Updates the display name. Returns true on success.
  Future<bool> updateDisplayName(String username) async {
    final user = currentUser;
    if (user == null) return false;

    isUpdatingProfile = true;
    errorMessage = null;
    notifyListeners();

    try {
      currentProfile = await _profileService.updateProfile(
        userId: user.id,
        username: username,
      );
      isUpdatingProfile = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      isUpdatingProfile = false;
      notifyListeners();
      return false;
    }
  }

  /// Uploads [file] as the new avatar, updates the profile row, and removes
  /// the previous avatar image (best-effort). Returns true on success.
  Future<bool> uploadAvatar(XFile file) async {
    final user = currentUser;
    if (user == null) return false;

    isUpdatingProfile = true;
    errorMessage = null;
    notifyListeners();

    final previousUrl = currentProfile?.avatarUrl;

    try {
      final urls = await SupabaseService.uploadImages(
        bucket: AppConstants.avatarsBucket,
        files: [file],
      );
      final newUrl = urls.first;

      currentProfile = await _profileService.updateProfile(
        userId: user.id,
        avatarUrl: newUrl,
      );

      if (previousUrl != null && previousUrl.isNotEmpty) {
        await SupabaseService.deleteImage(
          bucket: AppConstants.avatarsBucket,
          url: previousUrl,
        );
      }

      isUpdatingProfile = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      isUpdatingProfile = false;
      notifyListeners();
      return false;
    }
  }

  /// Removes the current avatar. Returns true on success.
  Future<bool> deleteAvatar() async {
    final user = currentUser;
    if (user == null) return false;

    final previousUrl = currentProfile?.avatarUrl;
    if (previousUrl == null || previousUrl.isEmpty) return true;

    isUpdatingProfile = true;
    errorMessage = null;
    notifyListeners();

    try {
      currentProfile = await _profileService.updateProfile(
        userId: user.id,
        clearAvatar: true,
      );

      await SupabaseService.deleteImage(
        bucket: AppConstants.avatarsBucket,
        url: previousUrl,
      );

      isUpdatingProfile = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      isUpdatingProfile = false;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}