import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

/// A service for handling local data storage
class LocalStorageService extends GetxService {
  static LocalStorageService get to => Get.find();
  
  late final SharedPreferences _prefs;
  final Map<String, dynamic> _memoryCache = {};
  
  /// Initialize the storage service
  Future<LocalStorageService> init() async {
    _prefs = await SharedPreferences.getInstance();
    return this;
  }
  
  /// Save a string value
  Future<bool> saveString(String key, String value) async {
    _memoryCache[key] = value;
    return await _prefs.setString(key, value);
  }
  
  /// Get a string value
  String? getString(String key, {String? defaultValue}) {
    return _memoryCache[key] ?? _prefs.getString(key) ?? defaultValue;
  }
  
  /// Save an integer value
  Future<bool> saveInt(String key, int value) async {
    _memoryCache[key] = value;
    return await _prefs.setInt(key, value);
  }
  
  /// Get an integer value
  int? getInt(String key, {int? defaultValue}) {
    return _memoryCache[key] ?? _prefs.getInt(key) ?? defaultValue;
  }
  
  /// Save a boolean value
  Future<bool> saveBool(String key, bool value) async {
    _memoryCache[key] = value;
    return await _prefs.setBool(key, value);
  }
  
  /// Get a boolean value
  bool getBool(String key, {bool defaultValue = false}) {
    return _memoryCache[key] ?? _prefs.getBool(key) ?? defaultValue;
  }
  
  /// Save a map as JSON
  Future<bool> saveMap(String key, Map<String, dynamic> value) async {
    final jsonString = jsonEncode(value);
    _memoryCache[key] = value;
    return await _prefs.setString(key, jsonString);
  }
  
  /// Get a map from JSON
  Map<String, dynamic>? getMap(String key) {
    if (_memoryCache.containsKey(key)) {
      return _memoryCache[key];
    }
    
    final jsonString = _prefs.getString(key);
    if (jsonString == null) return null;
    
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error parsing map for key $key: $e');
      return null;
    }
  }
  
  /// Save a list as JSON
  Future<bool> saveList(String key, List<dynamic> value) async {
    final jsonString = jsonEncode(value);
    _memoryCache[key] = value;
    return await _prefs.setString(key, jsonString);
  }
  
  /// Get a list from JSON
  List<dynamic>? getList(String key) {
    if (_memoryCache.containsKey(key)) {
      return _memoryCache[key];
    }
    
    final jsonString = _prefs.getString(key);
    if (jsonString == null) return null;
    
    try {
      return jsonDecode(jsonString) as List<dynamic>;
    } catch (e) {
      debugPrint('Error parsing list for key $key: $e');
      return null;
    }
  }
  
  /// Remove a value by key
  Future<bool> remove(String key) async {
    _memoryCache.remove(key);
    return await _prefs.remove(key);
  }
  
  /// Clear all stored data
  Future<bool> clear() async {
    _memoryCache.clear();
    return await _prefs.clear();
  }
  
  /// Get the application documents directory
  Future<Directory> getDocumentsDirectory() async {
    return await getApplicationDocumentsDirectory();
  }
  
  /// Get the temporary directory
  Future<Directory> getTemporaryDirectory() async {
    return await getTemporaryDirectory();
  }
  
  /// Get the external storage directory
  Future<Directory?> getExternalStorageDirectory() async {
    return await getExternalStorageDirectory();
  }
}
