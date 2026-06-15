import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/database/hive_database.dart';
import '../../../../core/network/api_client.dart';

class AuthViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  String? _token;
  String? _userName;
  String? _userEmail;

  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get token => _token;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  bool get isLoggedIn => _token != null;

  AuthViewModel() {
    _loadSession();
  }

  void _loadSession() {
    _token = HiveDatabase.settingsBox.get('token') as String?;
    _userName = HiveDatabase.settingsBox.get('userName') as String?;
    _userEmail = HiveDatabase.settingsBox.get('userEmail') as String?;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiClient.post('/auth/login', {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _token = data['token'] as String;
        _userEmail = data['email'] as String;
        _userName = data['name'] as String;

        await HiveDatabase.settingsBox.put('token', _token);
        await HiveDatabase.settingsBox.put('userName', _userName);
        await HiveDatabase.settingsBox.put('userEmail', _userEmail);

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _error = (data['error'] ?? 'Login failed') as String;
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiClient.post('/auth/register', {
        'name': name,
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _token = data['token'] as String;
        _userEmail = data['email'] as String;
        _userName = data['name'] as String;

        await HiveDatabase.settingsBox.put('token', _token);
        await HiveDatabase.settingsBox.put('userName', _userName);
        await HiveDatabase.settingsBox.put('userEmail', _userEmail);

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _error = (data['error'] ?? 'Registration failed') as String;
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    _token = null;
    _userName = null;
    _userEmail = null;
    await HiveDatabase.settingsBox.delete('token');
    await HiveDatabase.settingsBox.delete('userName');
    await HiveDatabase.settingsBox.delete('userEmail');
    await HiveDatabase.settingsBox.delete('last_sync_time');
    
    // Clear boxes on logout
    await HiveDatabase.expensesBox.clear();
    await HiveDatabase.budgetsBox.clear();
    await HiveDatabase.recurringRulesBox.clear();
    
    notifyListeners();
  }
}
