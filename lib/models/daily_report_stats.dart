import 'dart:math' as math;

import 'health_level.dart';
import 'vital_log_entry.dart';

/// إحصاءات يوم واحد من سجل القراءات.
class DailyReportStats {
  const DailyReportStats({
    required this.entries,
    required this.countOk,
    required this.countWatch,
    required this.countAlert,
    required this.countOffline,
    this.spo2Min,
    this.spo2Max,
    this.spo2Avg,
    this.bpmMin,
    this.bpmMax,
    this.bpmAvg,
    this.tempMin,
    this.tempMax,
    this.tempAvg,
    this.firstAt,
    this.lastAt,
  });

  final List<VitalLogEntry> entries;
  final int countOk;
  final int countWatch;
  final int countAlert;
  final int countOffline;

  final double? spo2Min;
  final double? spo2Max;
  final double? spo2Avg;
  final int? bpmMin;
  final int? bpmMax;
  final double? bpmAvg;
  final double? tempMin;
  final double? tempMax;
  final double? tempAvg;
  final DateTime? firstAt;
  final DateTime? lastAt;

  bool get hasData => entries.isNotEmpty;

  static DailyReportStats fromEntries(List<VitalLogEntry> raw) {
    final entries = List<VitalLogEntry>.from(raw)..sort((a, b) => a.recordedAtMs.compareTo(b.recordedAtMs));
    if (entries.isEmpty) {
      return DailyReportStats(
        entries: entries,
        countOk: 0,
        countWatch: 0,
        countAlert: 0,
        countOffline: 0,
      );
    }

    var ok = 0, watch = 0, alert = 0, offline = 0;
    final spo2s = <double>[];
    final bpms = <int>[];
    final temps = <double>[];

    for (final e in entries) {
      switch (e.level) {
        case HealthLevel.ok:
          ok++;
        case HealthLevel.watch:
          watch++;
        case HealthLevel.alert:
          alert++;
        case HealthLevel.offline:
          offline++;
      }
      if (e.level != HealthLevel.offline || (e.spo2 > 0 && e.heartRateBpm > 0)) {
        spo2s.add(e.spo2);
        bpms.add(e.heartRateBpm);
        temps.add(e.temperatureC);
      }
    }

    double? avg(List<num> xs) => xs.isEmpty ? null : xs.reduce((a, b) => a + b) / xs.length;

    return DailyReportStats(
      entries: entries,
      countOk: ok,
      countWatch: watch,
      countAlert: alert,
      countOffline: offline,
      spo2Min: spo2s.isEmpty ? null : spo2s.reduce(math.min),
      spo2Max: spo2s.isEmpty ? null : spo2s.reduce(math.max),
      spo2Avg: avg(spo2s),
      bpmMin: bpms.isEmpty ? null : bpms.reduce(math.min),
      bpmMax: bpms.isEmpty ? null : bpms.reduce(math.max),
      bpmAvg: bpms.isEmpty ? null : avg(bpms),
      tempMin: temps.isEmpty ? null : temps.reduce(math.min),
      tempMax: temps.isEmpty ? null : temps.reduce(math.max),
      tempAvg: avg(temps),
      firstAt: entries.first.recordedAt,
      lastAt: entries.last.recordedAt,
    );
  }
}
