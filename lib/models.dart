import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

// ============================================================================
// LOCAL STORAGE
// ============================================================================

class LocalStore {
  static const String _fileName = 'flux_flow_data.json';

  static File? _file;

  static Future<File?> _getFile() async {
    if (_file != null) return _file;

    try {
      String? basePath = Platform.environment['HOME'];

      if (basePath == null || basePath.trim().isEmpty) {
        basePath = Directory.current.path;
      }

      final Directory directory = Directory(basePath);

      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      _file = File('${directory.path}/$_fileName');
      return _file;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> read() async {
    try {
      final File? file = await _getFile();

      if (file == null || !await file.exists()) {
        return null;
      }

      final String text = await file.readAsString();

      if (text.trim().isEmpty) {
        return null;
      }

      final Object? decoded = jsonDecode(text);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> write(Map<String, dynamic> data) async {
    try {
      final File? file = await _getFile();

      if (file == null) {
        return;
      }

      await file.writeAsString(
        jsonEncode(data),
        flush: true,
      );
    } catch (_) {
      // Never allow storage failure to crash the UI.
    }
  }
}

// ============================================================================
// COLORS
// ============================================================================

const Color primaryGreen = Color(0xFF3F8F73);
const Color accentGreen = Color(0xFF59C79B);
const Color lightGreen = Color(0xFFE8F7EF);
const Color softGreen = Color(0xFFCFEADD);
const Color background = Color(0xFFF7FAF8);
const Color textDark = Color(0xFF28473E);
const Color mutedText = Color(0xFF71857E);
const Color borderColor = Color(0xFFDCE9E2);

// ============================================================================
// HABIT DATA
// ============================================================================

const List<String> habitCategories = <String>[
  'Health',
  'Fitness',
  'Learning',
  'Mindfulness',
  'Productivity',
  'Personal',
];

const List<IconData> habitIcons = <IconData>[
  Icons.spa_rounded,
  Icons.favorite_rounded,
  Icons.water_drop_rounded,
  Icons.fitness_center_rounded,
  Icons.menu_book_rounded,
  Icons.self_improvement_rounded,
  Icons.nightlight_rounded,
  Icons.directions_walk_rounded,
  Icons.bedtime_rounded,
  Icons.code_rounded,
];

const List<Color> habitColors = <Color>[
  Color(0xFF3F8F73),
  Color(0xFF72B7A0),
  Color(0xFF86A7E8),
  Color(0xFFD6A66B),
  Color(0xFFAD8BD1),
  Color(0xFFDB8D84),
];

String dateKey(DateTime date) {
  final DateTime day = DateTime(
    date.year,
    date.month,
    date.day,
  );

  final String year = day.year.toString().padLeft(4, '0');
  final String month = day.month.toString().padLeft(2, '0');
  final String datePart = day.day.toString().padLeft(2, '0');

  return '$year-$month-$datePart';
}

class Habit {
  Habit({
    required this.name,
    required this.category,
    this.iconIndex = 0,
    this.colorIndex = 0,
    Set<String>? completedDates,
  }) : completedDates = completedDates ?? <String>{};

  String name;
  String category;
  int iconIndex;
  int colorIndex;
  final Set<String> completedDates;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'category': category,
      'iconIndex': iconIndex,
      'colorIndex': colorIndex,
      'completedDates': completedDates.toList(),
    };
  }

  factory Habit.fromJson(Map<String, dynamic> json) {
    final Object? rawDates = json['completedDates'];

    final Set<String> dates = rawDates is List
        ? rawDates.map((Object? value) => value.toString()).toSet()
        : <String>{};

    final int parsedIcon = json['iconIndex'] is int
        ? json['iconIndex'] as int
        : int.tryParse('${json['iconIndex'] ?? 0}') ?? 0;

    final int parsedColor = json['colorIndex'] is int
        ? json['colorIndex'] as int
        : int.tryParse('${json['colorIndex'] ?? 0}') ?? 0;

    return Habit(
      name: '${json['name'] ?? 'Habit'}',
      category: habitCategories.contains(json['category'])
          ? '${json['category']}'
          : habitCategories.first,
      iconIndex: parsedIcon
          .clamp(0, habitIcons.length - 1)
          .toInt(),
      colorIndex: parsedColor
          .clamp(0, habitColors.length - 1)
          .toInt(),
      completedDates: dates,
    );
  }

  IconData get icon {
    final int safeIndex = iconIndex
        .clamp(0, habitIcons.length - 1)
        .toInt();

    return habitIcons[safeIndex];
  }

  Color get color {
    final int safeIndex = colorIndex
        .clamp(0, habitColors.length - 1)
        .toInt();

    return habitColors[safeIndex];
  }

  bool isCompletedOn(DateTime date) {
    return completedDates.contains(dateKey(date));
  }

  bool get doneToday {
    return isCompletedOn(DateTime.now());
  }

  void toggleToday() {
    final String key = dateKey(DateTime.now());

    if (completedDates.contains(key)) {
      completedDates.remove(key);
    } else {
      completedDates.add(key);
    }
  }

  int get currentStreak {
    DateTime day = DateTime.now();

    if (!isCompletedOn(day)) {
      day = day.subtract(const Duration(days: 1));
    }

    int streak = 0;

    while (isCompletedOn(day)) {
      streak++;
      day = day.subtract(const Duration(days: 1));

      if (streak > 3650) {
        break;
      }
    }

    return streak;
  }

  int get bestStreak {
    if (completedDates.isEmpty) {
      return 0;
    }

    final List<DateTime> dates = completedDates
        .map((String key) {
          final List<String> parts = key.split('-');

          if (parts.length != 3) {
            return null;
          }

          final int? year = int.tryParse(parts[0]);
          final int? month = int.tryParse(parts[1]);
          final int? day = int.tryParse(parts[2]);

          if (year == null || month == null || day == null) {
            return null;
          }

          return DateTime(year, month, day);
        })
        .whereType<DateTime>()
        .toList()
      ..sort();

    if (dates.isEmpty) {
      return 0;
    }

    int best = 1;
    int current = 1;

    for (int i = 1; i < dates.length; i++) {
      final int gap = dates[i]
          .difference(dates[i - 1])
          .inDays;

      if (gap == 1) {
        current++;

        if (current > best) {
          best = current;
        }
      } else {
        current = 1;
      }
    }

    return best;
  }

  int get completionsLast7Days {
    final DateTime today = DateTime.now();
    int count = 0;

    for (int i = 0; i < 7; i++) {
      if (isCompletedOn(
        today.subtract(Duration(days: i)),
      )) {
        count++;
      }
    }

    return count;
  }
}

// ============================================================================
// HABIT DRAFT
// ============================================================================

class HabitDraft {
  const HabitDraft({
    required this.name,
    required this.category,
    required this.iconIndex,
    required this.colorIndex,
  });

  final String name;
  final String category;
  final int iconIndex;
  final int colorIndex;
}
