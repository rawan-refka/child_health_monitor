import 'health_level.dart';

class VitalReading {
  const VitalReading({
    required this.spo2,
    required this.heartRateBpm,
    required this.temperatureC,
    required this.level,
    required this.receivedAt,
    this.rssiDbm,
    this.deviceName,
  });

  final double spo2;
  final int heartRateBpm;
  final double temperatureC;
  final HealthLevel level;
  final DateTime receivedAt;
  final int? rssiDbm;
  final String? deviceName;

  /// استنتاج حالة عامة من القراءات (يمكن الاعتماد على `status` القادم من ESP32 بدلها).
  static HealthLevel computeLevel({
    required double spo2,
    required int bpm,
    required double tempC,
  }) {
    if (spo2 < 92 || tempC >= 38.5 || bpm > 150 || bpm < 55) {
      return HealthLevel.alert;
    }
    if (spo2 < 95 || tempC >= 37.6 || bpm > 130 || bpm < 60) {
      return HealthLevel.watch;
    }
    return HealthLevel.ok;
  }

  factory VitalReading.fromJson(Map<String, dynamic> json) {
    final spo2 = _asDouble(json['spo2'] ?? json['SpO2']);
    final bpm = _asInt(json['bpm'] ?? json['heart_rate'] ?? json['hr']);
    final temp = _asDouble(json['temp_c'] ?? json['temperature'] ?? json['tempC']);
    final statusStr = (json['status'] as String?)?.toLowerCase();
    HealthLevel level;
    if (statusStr == 'alert' || statusStr == 'critical') {
      level = HealthLevel.alert;
    } else if (statusStr == 'watch' || statusStr == 'warning') {
      level = HealthLevel.watch;
    } else if (statusStr == 'ok' || statusStr == 'good') {
      level = HealthLevel.ok;
    } else {
      level = VitalReading.computeLevel(spo2: spo2, bpm: bpm, tempC: temp);
    }
    // وقت الاستلام: إذا أرسل الجهاز `ts` كـ millis() من التشغيل (أرقام صغيرة)
    // فاستخدامها كـ Unix يسبب تاريخًا ثابتًا (~1970) ويكسر السجل والمخططات.
    final ts = json['ts'] ?? json['timestamp_ms'] ?? json['time'];
    final DateTime at = _resolveReceivedAt(ts);

    return VitalReading(
      spo2: spo2,
      heartRateBpm: bpm,
      temperatureC: temp,
      level: level,
      receivedAt: at,
      rssiDbm: _asIntOrNull(json['rssi']),
      deviceName: json['device'] as String?,
    );
  }
}

/// Unix حقيقي بالمللي ثانية حاليًا ~1.7e12. قيم أصغر غالبًا millis من الـMCU.
DateTime _resolveReceivedAt(dynamic ts) {
  if (ts is int) {
    if (ts > 1000000000000) {
      return DateTime.fromMillisecondsSinceEpoch(ts);
    }
    return DateTime.now();
  }
  if (ts is num) {
    final v = ts.round();
    if (v > 1000000000000) {
      return DateTime.fromMillisecondsSinceEpoch(v);
    }
    return DateTime.now();
  }
  return DateTime.now();
}

double _asDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

int _asInt(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.round();
  return int.tryParse(v.toString()) ?? 0;
}

int? _asIntOrNull(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.round();
  return int.tryParse(v.toString());
}
