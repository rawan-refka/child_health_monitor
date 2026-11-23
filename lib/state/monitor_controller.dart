import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/health_level.dart';
import '../models/vital_reading.dart';
import '../services/esp32_vitals_client.dart';
import '../services/vitals_daily_log_service.dart';

const _kPrefBaseUrl = 'esp32_base_url';
const _kDefaultUrl = '192.168.4.1';

class MonitorController extends ChangeNotifier {
  MonitorController({Esp32VitalsClient? client}) : _client = client ?? Esp32VitalsClient();

  final Esp32VitalsClient _client;
  Timer? _timer;
  SharedPreferences? _prefs;

  String baseUrl = _kDefaultUrl;
  VitalReading? lastReading;
  String? lastError;
  bool isRefreshing = false;

  final List<VitalReading> _history = <VitalReading>[];
  List<VitalReading> get history => List.unmodifiable(_history);

  Future<void> loadPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    baseUrl = _prefs!.getString(_kPrefBaseUrl) ?? _kDefaultUrl;
    notifyListeners();
  }

  Future<void> setBaseUrl(String url) async {
    baseUrl = url.trim().isEmpty ? _kDefaultUrl : url.trim();
    await _prefs?.setString(_kPrefBaseUrl, baseUrl);
    notifyListeners();
  }

  void startAutoRefresh({Duration interval = const Duration(milliseconds: 1800)}) {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => refresh());
    unawaited(refresh());
  }

  void stopAutoRefresh() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> refresh() async {
    // لا نُلغي الطلبات إذا السابقة بطيئة — وإلا يُفوّت التايمر تحديثات كثيرة.
    isRefreshing = true;
    notifyListeners();

    try {
      final reading = await _client.fetchVitals(baseUrl);
      lastReading = reading;
      lastError = null;
      _pushHistory(lastReading);
      unawaited(VitalsDailyLogService.appendFromReading(reading));
    } catch (e) {
      lastError = e.toString();
      lastReading ??= VitalReading(
        spo2: 0,
        heartRateBpm: 0,
        temperatureC: 0,
        level: HealthLevel.offline,
        receivedAt: DateTime.now(),
      );
    } finally {
      isRefreshing = false;
      notifyListeners();
    }
  }

  void _pushHistory(VitalReading? reading) {
    if (reading == null) return;
    _history.add(reading);
    const maxPoints = 120;
    if (_history.length > maxPoints) {
      _history.removeRange(0, _history.length - maxPoints);
    }
  }

  @override
  void dispose() {
    stopAutoRefresh();
    _client.close();
    super.dispose();
  }
}
