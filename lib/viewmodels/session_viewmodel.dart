import 'dart:async';
import 'package:flutter/material.dart';
import '../data/services/session_service.dart';

class SessionViewModel extends ChangeNotifier with WidgetsBindingObserver {
  final SessionService _sessionService = SessionService();

  Timer? _inactivityTimer;
  bool _isLoggedIn = false;
  String? _username;
  int _remainingSeconds = 60;
  bool _isInitialized = false;

  bool get isLoggedIn => _isLoggedIn;
  String? get username => _username;
  int get remainingSeconds => _remainingSeconds;
  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    WidgetsBinding.instance.addObserver(this);
    final session = await _sessionService.getSession();
    if (session['token'] != null && session['username'] != null) {
      _username = session['username'];
      final lastActivity = session['lastActivity'];
      if (lastActivity != null) {
        final lastTime = DateTime.tryParse(lastActivity);
        if (lastTime != null) {
          final elapsed = DateTime.now().difference(lastTime).inSeconds;
          if (elapsed >= 60) {
            await _sessionService.clearSession();
          } else {
            _isLoggedIn = true;
            _remainingSeconds = 60 - elapsed;
            _startInactivityTimer();
          }
        }
      }
    }
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> startSession(String username) async {
    await _sessionService.saveSession(username);
    _username = username;
    _isLoggedIn = true;
    _remainingSeconds = 60;
    _startInactivityTimer();
    notifyListeners();
  }

  void resetInactivityTimer() {
    if (!_isLoggedIn) return;
    _remainingSeconds = 60;
    _sessionService.updateLastActivity();
    _startInactivityTimer();
    notifyListeners();
  }

  Future<void> logout() async {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
    _isLoggedIn = false;
    _username = null;
    _remainingSeconds = 60;
    await _sessionService.clearSession();
    notifyListeners();
  }

  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _remainingSeconds--;
      if (_remainingSeconds <= 0) {
        timer.cancel();
        logout();
      } else {
        notifyListeners();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _sessionService.updateLastActivity();
    } else if (state == AppLifecycleState.resumed) {
      _checkInactivityOnResume();
    }
  }

  Future<void> _checkInactivityOnResume() async {
    final lastActivity = await _sessionService.getLastActivity();
    if (lastActivity != null && _isLoggedIn) {
      final elapsed = DateTime.now().difference(lastActivity).inSeconds;
      if (elapsed >= 60) {
        await logout();
      } else {
        _remainingSeconds = 60 - elapsed;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
