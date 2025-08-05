import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service class for managing feedback forms
class FeedbackService {
  static const String _storageKey = 'feedback_forms';
  static final FeedbackService _instance = FeedbackService._internal();

  late final SharedPreferences _prefs;
  List<Map<String, dynamic>> _feedbackForms = [];

  /// Getter for feedback forms
  List<Map<String, dynamic>> get feedbackForms =>
      List.unmodifiable(_feedbackForms);

  /// Factory constructor to return the same instance (singleton)
  factory FeedbackService() {
    return _instance;
  }

  // Private constructor
  FeedbackService._internal() {
    _initPrefs();
  }

  /// Initialize SharedPreferences
  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadFormsFromPrefs();
  }

  /// Load forms from SharedPreferences
  Future<void> _loadFormsFromPrefs() async {
    try {
      final jsonString = _prefs.getString(_storageKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        _feedbackForms = jsonList
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading forms from SharedPreferences: $e');
      _feedbackForms = [];
    }
  }

  /// Save forms to SharedPreferences
  Future<bool> _saveFormsToPrefs() async {
    try {
      final jsonString = jsonEncode(_feedbackForms);
      return await _prefs.setString(_storageKey, jsonString);
    } catch (e) {
      debugPrint('Error saving forms to SharedPreferences: $e');
      return false;
    }
  }

  /// Fetches all feedback forms
  /// Returns true if successful, false otherwise
  Future<bool> initialize() async {
    try {
      // If we already have forms in memory, use those
      if (_feedbackForms.isNotEmpty) {
        return true;
      }

      // If no forms in memory, check SharedPreferences
      if (_prefs.containsKey(_storageKey)) {
        return true; // Forms already loaded in _initPrefs
      }

      // If no forms in SharedPreferences, use default forms
      _feedbackForms = [
        {
          'id': '1',
          'title': 'General Feedback',
          'description': 'Share your general feedback with us',
          'fields': [
            {'type': 'text', 'label': 'Name', 'required': true},
            {'type': 'email', 'label': 'Email', 'required': true},
            {'type': 'textarea', 'label': 'Feedback', 'required': true},
          ],
        },
        {
          'id': '2',
          'title': 'Bug Report',
          'description': 'Report any issues you\'ve encountered',
          'fields': [
            {'type': 'text', 'label': 'Page URL', 'required': true},
            {
              'type': 'textarea',
              'label': 'Describe the issue',
              'required': true,
            },
            {'type': 'text', 'label': 'Steps to reproduce', 'required': false},
          ],
        },
      ];

      // Save default forms to SharedPreferences
      return await _saveFormsToPrefs();
    } catch (e) {
      debugPrint('Error initializing feedback forms: $e');
      return false;
    }
  }

  /// Fetches a specific feedback form by ID
  /// Returns null if not found
  Map<String, dynamic>? getFormById(String id) {
    try {
      final index = _feedbackForms.indexWhere((form) => form['id'] == id);
      return index != -1
          ? Map<String, dynamic>.from(_feedbackForms[index])
          : null;
    } catch (e) {
      debugPrint('Error getting form by ID: $e');
      return null;
    }
  }

  /// Adds or updates a feedback form
  /// Returns true if successful, false otherwise
  Future<bool> saveForm(Map<String, dynamic> form) async {
    try {
      final index = _feedbackForms.indexWhere((f) => f['id'] == form['id']);

      if (index != -1) {
        _feedbackForms[index] = Map<String, dynamic>.from(form);
      } else {
        _feedbackForms.add(Map<String, dynamic>.from(form));
      }

      return await _saveFormsToPrefs();
    } catch (e) {
      debugPrint('Error saving form: $e');
      return false;
    }
  }

  /// Deletes a feedback form by ID
  /// Returns true if successful, false otherwise
  Future<bool> deleteForm(String id) async {
    try {
      final initialLength = _feedbackForms.length;
      _feedbackForms.removeWhere((form) => form['id'] == id);

      if (_feedbackForms.length < initialLength) {
        return await _saveFormsToPrefs();
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting form: $e');
      return false;
    }
  }

  /// Clears all feedback forms from storage
  /// Returns true if successful, false otherwise
  Future<bool> clearAllForms() async {
    try {
      _feedbackForms.clear();
      return await _saveFormsToPrefs();
    } catch (e) {
      debugPrint('Error clearing forms: $e');
      return false;
    }
  }
}

/// Global instance of FeedbackService
final feedbackService = FeedbackService();
