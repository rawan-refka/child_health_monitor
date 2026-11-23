import 'health_level.dart';
import 'vital_reading.dart';

/// نقطة واحدة في سجل القراءات اليومي (للتقارير والأرشفة).
class VitalLogEntry {
  const VitalLogEntry({
    required this.recordedAtMs,
    required this.spo2,
    required this.heartRateBpm,
    required this.temperatureC,
    required this.level,
    this.deviceName,
    this.rssiDbm,
  });

  final int recordedAtMs;
  final double spo2;
  final int heartRateBpm;
  final double temperatureC;
  final HealthLevel level;
  final String? deviceName;
  final int? rssiDbm;

  DateTime get recordedAt => DateTime.fromMillisecondsSinceEpoch(recordedAtMs);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'ms': recordedAtMs,
        'spo2': spo2,
        'bpm': heartRateBpm,
        'temp_c': temperatureC,
        'level': level.name,
        if (deviceName != null) 'device': deviceName,
        if (rssiDbm != null) 'rssi': rssiDbm,
      };

  factory VitalLogEntry.fromJson(Map<String, dynamic> json) {
    final levelStr = (json['level'] as String?) ?? 'offline';
    return VitalLogEntry(
      recordedAtMs: (json['ms'] as num).round(),
      spo2: (json['spo2'] as num).toDouble(),
      heartRateBpm: (json['bpm'] as num).round(),
      temperatureC: (json['temp_c'] as num).toDouble(),
      level: HealthLevel.values.firstWhere(
        (e) => e.name == levelStr,
        orElse: () => HealthLevel.offline,
      ),
      deviceName: json['device'] as String?,
      rssiDbm: json['rssi'] == null ? null : (json['rssi'] as num).round(),
    );
  }

  factory VitalLogEntry.fromReading(VitalReading r) {
    return VitalLogEntry(
      recordedAtMs: r.receivedAt.millisecondsSinceEpoch,
      spo2: r.spo2,
      heartRateBpm: r.heartRateBpm,
      temperatureC: r.temperatureC,
      level: r.level,
      deviceName: r.deviceName,
      rssiDbm: r.rssiDbm,
    );
  }
}
