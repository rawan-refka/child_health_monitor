import 'package:flutter/material.dart';

/// عرض الشاشة الذي نعتبر فوقه واجهة «سطح مكتب / عرض».
bool isWideLayout(BuildContext context) {
  return MediaQuery.sizeOf(context).width >= 900;
}

double contentMaxWidth(BuildContext context) {
  final w = MediaQuery.sizeOf(context).width;
  if (w >= 1400) return 1280;
  if (w >= 900) return 1100;
  return w;
}

EdgeInsets pagePadding(BuildContext context) {
  final w = MediaQuery.sizeOf(context).width;
  if (w >= 1200) return const EdgeInsets.symmetric(horizontal: 48, vertical: 28);
  if (w >= 900) return const EdgeInsets.symmetric(horizontal: 32, vertical: 20);
  return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
}
