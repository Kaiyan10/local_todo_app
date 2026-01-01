import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'todo.dart';

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

  final Map<GtdCategory, String> _categoryNames = {};

  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();

    // Load contexts
    final savedContexts = _prefs.getStringList('custom_contexts');
    if (savedContexts != null) {
      _contexts = savedContexts;
    }

    // Load category names
    for (var category in GtdCategory.values) {
      final key = 'category_name_${category.name}';
      final savedName = _prefs.getString(key);
      if (savedName != null) {
        _categoryNames[category] = savedName;
      } else {
        // Default names
        _categoryNames[category] = _getDefaultCategoryName(category);
      }
    }

    _initialized = true;
    notifyListeners();
  }

  String _getDefaultCategoryName(GtdCategory category) {
    switch (category) {
      case GtdCategory.inbox:
        return 'Inbox';
      case GtdCategory.nextAction:
        return 'Next Action';
      case GtdCategory.project:
        return 'Project';
      case GtdCategory.waitingFor:
        return 'Waiting For';
      case GtdCategory.someday:
        return 'Someday/Maybe';
      case GtdCategory.reference:
        return 'Reference';
    }
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

  String getCategoryName(GtdCategory category) {
    return _categoryNames[category] ?? _getDefaultCategoryName(category);
  }

  Future<void> setCategoryName(GtdCategory category, String newName) async {
    _categoryNames[category] = newName;
    await _prefs.setString('category_name_${category.name}', newName);
    notifyListeners();
  }
}
