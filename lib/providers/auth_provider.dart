import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  SupabaseClient get _client => Supabase.instance.client;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  static String _authErrorMessage(dynamic e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('invalid') &&
        (msg.contains('credential') || msg.contains('password'))) {
      return 'Invalid email or password.';
    }
    if (msg.contains('user not found') || msg.contains('wrong-password')) {
      return 'Invalid email or password.';
    }
    if (msg.contains('already registered') || msg.contains('email already')) {
      return 'This email is already registered. Try logging in.';
    }
    if (msg.contains('network')) {
      return 'Network error. Check your connection.';
    }
    return 'Authentication failed. Please try again.';
  }

  Future<bool> signIn(String email, String password, String userType) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      final user = _client.auth.currentUser;
      if (user == null) {
        _errorMessage = 'Invalid email or password.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      var profile = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      // If no profile (e.g. trigger didn't run or old signup), create from user metadata
      if (profile == null) {
        final meta = user.userMetadata ?? {};
        final name = meta['name']?.toString() ?? 'User';
        final metaUserType = meta['user_type']?.toString() ?? 'patient';
        try {
          await _client.from('profiles').upsert({
            'id': user.id,
            'email': user.email ?? email.trim(),
            'name': name,
            'user_type': metaUserType,
          }, onConflict: 'id');
          profile = await _client
              .from('profiles')
              .select()
              .eq('id', user.id)
              .maybeSingle();
        } catch (_) {
          _errorMessage = 'No profile found. Please sign up first.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
        if (profile == null) {
          _errorMessage = 'No profile found. Please sign up first.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      final profileUserType = profile['user_type']?.toString();
      if (profileUserType != userType) {
        _errorMessage =
            'Please select "${userType == 'patient' ? 'Patient' : 'Doctor'}" to match your account.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _currentUser = UserModel(
        id: user.id,
        email: user.email ?? email.trim(),
        name: profile['name']?.toString() ?? 'User',
        userType: profileUserType!,
        phone: profile['phone']?.toString(),
        profileImageUrl: profile['profile_image_url']?.toString(),
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = _authMessage(e.message);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = _authErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  static String _authMessage(String? msg) {
    if (msg == null || msg.isEmpty) return 'Authentication failed.';
    final m = msg.toLowerCase();
    if (m.contains('invalid login') || m.contains('invalid_credentials')) {
      return 'Invalid email or password.';
    }
    if (m.contains('email not confirmed') || m.contains('confirm your email')) {
      return 'Please confirm your email using the link we sent you, then try again.';
    }
    return msg;
  }

  Future<bool> signUp(
    String email,
    String password,
    String name,
    String userType,
  ) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'name': name.trim(), 'user_type': userType},
      );

      final user = _client.auth.currentUser;
      if (user == null) {
        _errorMessage = 'Sign up failed. Try again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Profile is created by Supabase trigger from user_metadata; or insert if no trigger
      try {
        await _client.from('profiles').upsert({
          'id': user.id,
          'email': email.trim(),
          'name': name.trim(),
          'user_type': userType,
        }, onConflict: 'id');
      } catch (_) {}

      _currentUser = UserModel(
        id: user.id,
        email: user.email ?? email.trim(),
        name: name.trim(),
        userType: userType,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = _authErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    _currentUser = null;
    notifyListeners();
  }

  Future<void> loadCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    try {
      final profile = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (profile == null) return;

      _currentUser = UserModel(
        id: user.id,
        email: user.email ?? '',
        name: profile['name']?.toString() ?? 'User',
        userType: profile['user_type']?.toString() ?? 'patient',
        phone: profile['phone']?.toString(),
        profileImageUrl: profile['profile_image_url']?.toString(),
      );
      notifyListeners();
    } catch (_) {
      _currentUser = null;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
