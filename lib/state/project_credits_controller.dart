import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kTitle = 'proj_title';
const _kTagline = 'proj_tagline';
const _kStudents = 'proj_students';
const _kSupervisor = 'proj_supervisor';
const _kUniAr = 'proj_uni_ar';
const _kUniEn = 'proj_uni_en';

/// بيانات غلاف المشروع (العنوان، الطالبات، الإشراف، الجامعة) — تظهر في السبلاش وتُحرَّر من الإعدادات.
class ProjectCreditsController extends ChangeNotifier {
  ProjectCreditsController();

  String projectTitle = 'رعاية الطفل';
  String projectTagline = 'تطبيق مراقبة صحة الأطفال — WiFi · ESP32';
  String studentsLine = 'ماريا · روان';
  String supervisorLine = 'إشراف: د. [اسم الدكتور]';
  String universityAr = 'الجامعة الدولية للعلوم والتكنولوجيا';
  String universityEn = 'IUST';

  Future<void> loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    projectTitle = p.getString(_kTitle) ?? projectTitle;
    projectTagline = p.getString(_kTagline) ?? projectTagline;
    studentsLine = p.getString(_kStudents) ?? studentsLine;
    supervisorLine = p.getString(_kSupervisor) ?? supervisorLine;
    universityAr = p.getString(_kUniAr) ?? universityAr;
    universityEn = p.getString(_kUniEn) ?? universityEn;
    notifyListeners();
  }

  Future<void> save({
    required String projectTitle,
    required String projectTagline,
    required String studentsLine,
    required String supervisorLine,
    required String universityAr,
    required String universityEn,
  }) async {
    final p = await SharedPreferences.getInstance();
    this.projectTitle = projectTitle.trim().isEmpty ? 'رعاية الطفل' : projectTitle.trim();
    this.projectTagline = projectTagline.trim();
    this.studentsLine = studentsLine.trim();
    this.supervisorLine = supervisorLine.trim();
    this.universityAr = universityAr.trim();
    this.universityEn = universityEn.trim();

    await p.setString(_kTitle, this.projectTitle);
    await p.setString(_kTagline, this.projectTagline);
    await p.setString(_kStudents, this.studentsLine);
    await p.setString(_kSupervisor, this.supervisorLine);
    await p.setString(_kUniAr, this.universityAr);
    await p.setString(_kUniEn, this.universityEn);
    notifyListeners();
  }
}
