import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../models/profile_model.dart';

/// Holds auth state and doubles as a [ChangeNotifier] that go_router can
/// listen to (via `refreshListenable`) so routes re-evaluate on login/logout.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  StreamSubscription<AuthState>? _authSub;

  bool isLoading = false;
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
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();
      currentProfile = ProfileModel.fromJson(data);
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

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}