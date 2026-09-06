import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

enum TargetFrequency {
  daily,
  weekly,
  monthly,
}

class Habit {
  Habit({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.iconCodePoint,
    required this.colorValue,
    required this.createdAt,
    required this.targetValue,
    required this.targetFrequency,
    this.archived = false,
    Set<String>? completedDates,
  }) : completedDates = completedDates ?? <String>{};

  final String id;
  String name;
  String description;
  String category;
  int iconCodePoint;
  int colorValue;
  DateTime createdAt;
  int targetValue;
  TargetFrequency targetFrequency;
  bool archived;
  final Set<String> completedDates;

  bool isCompleted(DateTime date) =>
      completedDates.contains(dayKey(date));

  void toggle(DateTime date) {
    final key = dayKey(date);

    if (!completedDates.add(key)) {
      completedDates.remove(key);
    }
  }

  int currentStreak(DateTime today) {
    var cursor = dateOnly(today);
    var streak = 0;

    while (isCompleted(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return streak;
  }

  int bestStreak() {
    if (completedDates.isEmpty) return 0;

    final dates = completedDates.map(parseDayKey).toList()..sort();

    var best = 1;
    var current = 1;

    for (var i = 1; i < dates.length; i++) {
      if (dates[i].difference(dates[i - 1]).inDays == 1) {
        current++;
        if (current > best) best = current;
      } else {
        current = 1;
      }
    }

    return best;
  }

  int completionsInLastDays(DateTime today, int days) {
    var count = 0;

    for (var i = 0; i < days; i++) {
      final date = today.subtract(Duration(days: i));
      if (isCompleted(date)) count++;
    }

    return count;
  }

  int completionsForFrequency(DateTime today) {
    int daysToCheck;
    switch (targetFrequency) {
      case TargetFrequency.daily:
        daysToCheck = 1;
        break;
      case TargetFrequency.weekly:
        daysToCheck = 7;
        break;
      case TargetFrequency.monthly:
        daysToCheck = 30;
        break;
    }
    return completionsInLastDays(today, daysToCheck);
  }

  double goalProgress(DateTime today) {
    final completions = completionsForFrequency(today);
    return (completions / targetValue).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'category': category,
        'icon': iconCodePoint,
        'color': colorValue,
        'createdAt': createdAt.toIso8601String(),
        'targetValue': targetValue,
        'targetFrequency': targetFrequency.name,
        'archived': archived,
        'completedDates': completedDates.toList(growable: false),
      };

  factory Habit.fromJson(Map<String, dynamic> json) {
    final dates = json['completedDates'];
    final rawTarget = json['targetValue'] ?? json['targetPerWeek'];
    final target = rawTarget is int
        ? rawTarget
        : int.tryParse(rawTarget?.toString() ?? '') ?? 7;

    final freqString = json['targetFrequency'] ?? 'weekly';
    final frequency = TargetFrequency.values.firstWhere(
      (e) => e.name == freqString,
      orElse: () => TargetFrequency.weekly,
    );

    return Habit(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Habit',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Personal',
      iconCodePoint: _int(json['icon']),
      colorValue: _int(json['color'], fallback: 0xFF18A957),
      createdAt: DateTime.tryParse(
            json['createdAt']?.toString() ?? '',
          ) ??
          DateTime.now(),
      targetValue: target.clamp(1, 31),
      targetFrequency: frequency,
      archived: json['archived'] == true,
      completedDates: dates is List
          ? dates.map((item) => item.toString()).toSet()
          : <String>{},
    );
  }

  static int _int(dynamic value, {int fallback = 0}) =>
      value is int ? value : int.tryParse(value?.toString() ?? '') ?? fallback;

  static DateTime dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static String dayKey(DateTime value) {
    final date = dateOnly(value);

    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static DateTime parseDayKey(String value) {
    final parts = value.split('-');

    if (parts.length != 3) {
      return DateTime(1970, 1, 1);
    }

    return DateTime(
      int.tryParse(parts[0]) ?? 1970,
      int.tryParse(parts[1]) ?? 1,
      int.tryParse(parts[2]) ?? 1,
    );
  }
}

class LocalStore {
  static const habitsKey = 'fynox_fow_habits_v5';
  static const onboardingKey = 'fynox_fow_onboarding_v5';

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();
  Future<void> _writeQueue = Future<void>.value();

  Future<T> _queuedWrite<T>(Future<T> Function() action) {
    final next = _writeQueue.then((_) => action());

    _writeQueue = next.then<void>(
      (_) {},
      onError: (_, __) {},
    );

    return next;
  }

  Future<List<Habit>> loadHabits() async {
    final raw = await _prefs.getString(habitsKey);

    if (raw == null || raw.isEmpty) return <Habit>[];

    try {
      final decoded = jsonDecode(raw);

      if (decoded is! List) return <Habit>[];

      return decoded
          .whereType<Map>()
          .map(
            (item) => Habit.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .where((habit) => habit.id.isNotEmpty)
          .toList(growable: true);
    } catch (_) {
      return <Habit>[];
    }
  }

  Future<void> saveHabits(List<Habit> habits) {
    final snapshot = habits
        .map((habit) => habit.toJson())
        .toList(growable: false);

    return _queuedWrite(() => _prefs.setString(
          habitsKey,
          jsonEncode(snapshot),
        ));
  }

  Future<bool> hasSeenOnboarding() async =>
      await _prefs.getBool(onboardingKey) ?? false;

  Future<void> setSeenOnboarding() {
    return _queuedWrite(
      () => _prefs.setBool(onboardingKey, true),
    );
  }
}
