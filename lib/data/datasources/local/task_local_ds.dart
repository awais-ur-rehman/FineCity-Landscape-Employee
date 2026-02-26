import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/care_task_model.dart';

const _kCachedTasks = 'fc_cached_tasks';

/// Local data source for cached tasks.
/// Uses SharedPreferences for now; will migrate to Isar in Phase 11.
abstract class TaskLocalDataSource {
  Future<List<CareTaskModel>> getCachedTodayTasks();
  Future<void> cacheTodayTasks(List<CareTaskModel> tasks);
  Future<void> clearCachedTasks();
}

class TaskLocalDataSourceImpl implements TaskLocalDataSource {
  final SharedPreferences _prefs;

  const TaskLocalDataSourceImpl(this._prefs);

  @override
  Future<List<CareTaskModel>> getCachedTodayTasks() async {
    final jsonStr = _prefs.getString(_kCachedTasks);
    if (jsonStr == null) return [];
    try {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list
          .map((t) => CareTaskModel.fromJson(t as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> cacheTodayTasks(List<CareTaskModel> tasks) async {
    final jsonStr = jsonEncode(tasks.map((t) => t.toJson()).toList());
    await _prefs.setString(_kCachedTasks, jsonStr);
  }

  @override
  Future<void> clearCachedTasks() async {
    await _prefs.remove(_kCachedTasks);
  }
}
