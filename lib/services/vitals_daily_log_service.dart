import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/health_level.dart';
import '../models/vital_log_entry.dart';
import '../models/vital_reading.dart';

const _kMaxEntriesPerDay = 2500;

/// تخزين قراءات يومية للتقارير (مفتاح لكل يوم تقويمي محلي).
class VitalsDailyLogService {
  VitalsDailyLogService._();

  static String _dayKey(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return 'vitals_log_$y-$m-$dd';
  }

  /// تسجيل قراءة ناجحة من الجهاز (لا يُسجّل وضع «غير متصل» الوهمي بقيم صفر).
  static Future<void> appendFromReading(VitalReading r) async {
    if (r.level == HealthLevel.offline && r.spo2 == 0 && r.heartRateBpm == 0) {
      return;
    }
    final entry = VitalLogEntry.fromReading(r);
    final p = await SharedPreferences.getInstance();
    final key = _dayKey(entry.recordedAt);
    final existing = p.getString(key);
    final list = <Map<String, dynamic>>[];
    if (existing != null && existing.isNotEmpty) {
      try {
        final decoded = jsonDecode(existing);
        if (decoded is List) {
          for (final e in decoded) {
            if (e is Map<String, dynamic>) list.add(e);
          }
        }
      } catch (_) {}
    }
    list.add(entry.toJson());
    while (list.length > _kMaxEntriesPerDay) {
      list.removeAt(0);
    }
    await p.setString(key, jsonEncode(list));
  }

  static Future<List<VitalLogEntry>> loadDay(DateTime day) async {
    final p = await SharedPreferences.getInstance();
    final key = _dayKey(day);
    final raw = p.getString(key);
    if (raw == null || raw.isEmpty) return <VitalLogEntry>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <VitalLogEntry>[];
      final out = <VitalLogEntry>[];
      for (final e in decoded) {
        if (e is Map<String, dynamic>) {
          out.add(VitalLogEntry.fromJson(e));
        } else if (e is Map) {
          out.add(VitalLogEntry.fromJson(Map<String, dynamic>.from(e)));
        }
      }
      return out;
    } catch (_) {
      return <VitalLogEntry>[];
    }
  }
}
