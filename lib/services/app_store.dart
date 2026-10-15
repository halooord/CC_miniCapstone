import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/training.dart';

/// Manages local app state, including persistent workouts and custom drills.
class AppStore extends ChangeNotifier {
  static const _recordsKey = 'court_iq_records_v1';
  static const _drillsKey = 'court_iq_drills_v1';
  static const _nameKey = 'court_iq_name_v1';
  static const _goalKey = 'court_iq_goal_v1';

  SharedPreferences? _prefs;
  String athleteName = 'Athlete';
  int weeklyGoal = 5;
  final List<TrainingRecord> records = [];
  final List<Drill> customDrills = [];

  List<Drill> get allDrills => [...defaultDrills, ...customDrills];
  int get totalMinutes => records.fold(0, (sum, item) => sum + item.minutes);
  int get totalSessions => records.length;
  int get weeklySessions => records.where((item) => _isThisWeek(item.completedAt)).length;
  int get weeklyMinutes => records.where((item) => _isThisWeek(item.completedAt))
      .fold(0, (sum, item) => sum + item.minutes);
  double get weeklyProgress => (weeklySessions / weeklyGoal).clamp(0.0, 1.0).toDouble();

  bool _isThisWeek(DateTime date) {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    return !date.isBefore(monday) && date.isBefore(monday.add(const Duration(days: 7)));
  }

  int sessionsOn(DateTime day) => records.where((r) =>
      r.completedAt.year == day.year && r.completedAt.month == day.month &&
      r.completedAt.day == day.day).length;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    athleteName = _prefs?.getString(_nameKey) ?? 'Athlete';
    weeklyGoal = (_prefs?.getInt(_goalKey) ?? 5).clamp(1, 7).toInt();
    try {
      final savedRecords = jsonDecode(_prefs?.getString(_recordsKey) ?? '[]') as List;
      records.addAll(savedRecords.map((x) => TrainingRecord.fromJson(Map<String, dynamic>.from(x as Map))));
      final savedDrills = jsonDecode(_prefs?.getString(_drillsKey) ?? '[]') as List;
      customDrills.addAll(savedDrills.map((x) => Drill.fromJson(Map<String, dynamic>.from(x as Map))));
      records.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    } catch (_) {
      records.clear();
      customDrills.clear();
    }
    notifyListeners();
  }

  Future<void> addSession(Drill drill) async {
    records.insert(0, TrainingRecord(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: drill.title, category: drill.category,
      minutes: drill.minutes, completedAt: DateTime.now(),
    ));
    notifyListeners();
    await _saveRecords();
  }

  Future<void> deleteSession(String id) async {
    records.removeWhere((record) => record.id == id);
    notifyListeners();
    await _saveRecords();
  }

  Future<void> saveCustomDrill(Drill drill) async {
    final index = customDrills.indexWhere((d) => d.id == drill.id);
    if (index == -1) {
      customDrills.add(drill);
    } else {
      customDrills[index] = drill;
    }
    notifyListeners();
    await _saveDrills();
  }

  Future<void> deleteCustomDrill(String id) async {
    customDrills.removeWhere((drill) => drill.id == id);
    notifyListeners();
    await _saveDrills();
  }

  Future<void> updateName(String newName) async {
    athleteName = newName.trim();
    notifyListeners();
    await _prefs?.setString(_nameKey, athleteName);
  }

  Future<void> updateWeeklyGoal(int value) async {
    weeklyGoal = value.clamp(1, 7).toInt();
    notifyListeners();
    await _prefs?.setInt(_goalKey, weeklyGoal);
  }

  Future<void> clearUserData() async {
    records.clear();
    customDrills.clear();
    notifyListeners();
    await Future.wait([_saveRecords(), _saveDrills()]);
  }

  Future<void> _saveRecords() async {
    await _prefs?.setString(_recordsKey,
      jsonEncode(records.map((r) => r.toJson()).toList()));
  }

  Future<void> _saveDrills() async {
    await _prefs?.setString(_drillsKey,
      jsonEncode(customDrills.map((d) => d.toJson()).toList()));
  }
}
