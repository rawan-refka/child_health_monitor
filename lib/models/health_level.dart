import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum HealthLevel {
  ok,
  watch,
  alert,
  offline,
}

extension HealthLevelX on HealthLevel {
  String get labelAr {
    switch (this) {
      case HealthLevel.ok:
        return 'مستقر';
      case HealthLevel.watch:
        return 'مراقبة';
      case HealthLevel.alert:
        return 'تنبيه';
      case HealthLevel.offline:
        return 'غير متصل';
    }
  }

  String get shortHintAr {
    switch (this) {
      case HealthLevel.ok:
        return 'المؤشرات ضمن المدى المريح';
      case HealthLevel.watch:
        return 'راقب القراءات أو أعد وضع الحساس';
      case HealthLevel.alert:
        return 'يُنصح بالتحقق من الطفل أو استشارة مختص';
      case HealthLevel.offline:
        return 'تأكد من تشغيل ESP32 وعنوان الشبكة';
    }
  }

  Color get color {
    switch (this) {
      case HealthLevel.ok:
        return AppColors.ok;
      case HealthLevel.watch:
        return AppColors.warn;
      case HealthLevel.alert:
        return AppColors.alert;
      case HealthLevel.offline:
        return AppColors.textSecondary;
    }
  }

  IconData get icon {
    switch (this) {
      case HealthLevel.ok:
        return Icons.verified_rounded;
      case HealthLevel.watch:
        return Icons.visibility_rounded;
      case HealthLevel.alert:
        return Icons.emergency_rounded;
      case HealthLevel.offline:
        return Icons.cloud_off_rounded;
    }
  }
}
