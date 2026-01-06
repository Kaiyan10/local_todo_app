import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'category_model.dart' as model;


class SettingsService extends ChangeNotifier {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  late SharedPreferences _prefs;
  bool _initialized = false;

  List<String> _contexts = [
    '@Agenda', // For items to discuss in meetings
    '@Boss',
    '@DevTeam',
    '@DesignTeam',
    '@Product', // For strategy/planning
    '@DeepWork',
    '@Quick', // < 15 min
    '@Office',
    '@Home',
  ];

  List<model.Category> _categories = [];
  final Uuid _uuid = const Uuid();

  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();

    // Load contexts
    final savedContexts = _prefs.getStringList('custom_contexts');
    if (savedContexts != null) {
      _contexts = savedContexts;
    }

    // Load categories
    final savedCategories = _prefs.getString('custom_categories');
    if (savedCategories != null) {
      final List<dynamic> jsonList = jsonDecode(savedCategories);
      _categories = jsonList.map((j) => model.Category.fromJson(j)).toList();
    } else {
      // Default initialization
      _categories = List.from(model.SystemCategories.initialCategories);
    }

    _initialized = true;
    notifyListeners();
  }



  // --- Contexts ---

  List<String> get contexts => List.unmodifiable(_contexts);

  Future<void> addContext(String context) async {
    if (!_contexts.contains(context)) {
      _contexts.add(context);
      await _prefs.setStringList('custom_contexts', _contexts);
      notifyListeners();
    }
  }

  Future<void> removeContext(String context) async {
    if (_contexts.contains(context)) {
      _contexts.remove(context);
      await _prefs.setStringList('custom_contexts', _contexts);
      notifyListeners();
    }
  }

  // --- Categories ---

  // --- Categories ---

  List<model.Category> get categories => List.unmodifiable(_categories);

  String getCategoryName(String id) {
    final cat = _categories.firstWhere(
      (c) => c.id == id,
      orElse: () => model.Category(id: id, name: id, isSystem: false),
    );
    return cat.name;
  }

  Future<void> addCategory(String name) async {
    final newCategory = model.Category(
      id: _uuid.v4(),
      name: name,
      isSystem: false,
    );
    _categories.add(newCategory);
    await _saveCategories();
    notifyListeners();
  }

  Future<void> updateCategory(String id, String newName) async {
    final index = _categories.indexWhere((c) => c.id == id);
    if (index != -1) {
      final old = _categories[index];
      _categories[index] = model.Category(
        id: old.id,
        name: newName,
        isSystem: old.isSystem,
      );
      await _saveCategories();
      notifyListeners();
    }
  }

  Future<void> deleteCategory(String id) async {
    final index = _categories.indexWhere((c) => c.id == id);
    if (index != -1 && !_categories[index].isSystem) {
      _categories.removeAt(index);
      await _saveCategories();
      notifyListeners();
    }
  }

  Future<void> _saveCategories() async {
    final jsonList = _categories.map((c) => c.toJson()).toList();
    await _prefs.setString('custom_categories', jsonEncode(jsonList));
  }
}
