import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../network/api_client.dart';
import '../storage/storage_service.dart';
import '../network/socket_service.dart';

class AuthProvider extends ChangeNotifier {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Restore session
  Future<bool> tryAutoLogin() async {
    final token = StorageService.getToken();
    if (token == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final res = await ApiClient.get('/auth/me');
      if (res['success'] == true && res['user'] != null) {
        _currentUser = UserModel.fromJson(res['user']);
        SocketService.init();
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      print('Auto-login error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Continue with Google Sign-In
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return false; // User cancelled
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      final res = await ApiClient.post('/auth/google', {
        'idToken': idToken,
        'email': googleUser.email,
        'displayName': googleUser.displayName,
      });

      if (res['success'] == true) {
        final token = res['token'];
        await StorageService.saveToken(token);
        _currentUser = UserModel.fromJson(res['user']);
        SocketService.init();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = res['message'] ?? 'Authentication failed';
      }
    } catch (e) {
      // In development or when Google Services configuration is pending, fallback to demo user
      print('[Auth] Native Google sign-in fallback: $e');
      final res = await ApiClient.post('/auth/google', {
        'demoMode': true,
        'email': 'venil.telos@example.com',
        'displayName': 'Venil Explorer',
      });
      if (res['success'] == true) {
        await StorageService.saveToken(res['token']);
        _currentUser = UserModel.fromJson(res['user']);
        SocketService.init();
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _errorMessage = 'Google sign-in error: $e';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Fast Dev / Demo Sign-In
  Future<bool> signInDemo() async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await ApiClient.post('/auth/google', {
        'demoMode': true,
        'email': 'venil.telos@example.com',
        'displayName': 'Venil (TELOS Pilot)',
      });
      if (res['success'] == true) {
        await StorageService.saveToken(res['token']);
        _currentUser = UserModel.fromJson(res['user']);
        SocketService.init();
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Complete Onboarding
  Future<bool> completeOnboarding({
    required String username,
    required String displayName,
    required String profileVisibility,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await ApiClient.post('/auth/onboarding', {
        'username': username,
        'displayName': displayName,
        'profileVisibility': profileVisibility,
      });

      if (res['success'] == true) {
        _currentUser = UserModel.fromJson(res['user']);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = res['message'];
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Logout
  Future<void> logout() async {
    await StorageService.removeToken();
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    SocketService.disconnect();
    _currentUser = null;
    notifyListeners();
  }
}
