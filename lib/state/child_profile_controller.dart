import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kChildName = 'child_name';
const _kChildAge = 'child_age_label';
const _kGuardian = 'child_guardian';
const _kMedicalId = 'child_medical_id';
const _kNotes = 'child_medical_notes';

/// بيانات الطفل الظاهرة في التقرير الطبي اليومي.
class ChildProfileController extends ChangeNotifier {
  String childName = '';
  String ageLabel = '';
  String guardianLine = '';
  String medicalIdLine = '';
  String medicalNotes = '';

  Future<void> loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    childName = p.getString(_kChildName) ?? '';
    ageLabel = p.getString(_kChildAge) ?? '';
    guardianLine = p.getString(_kGuardian) ?? '';
    medicalIdLine = p.getString(_kMedicalId) ?? '';
    medicalNotes = p.getString(_kNotes) ?? '';
    notifyListeners();
  }

  Future<void> save({
    required String childName,
    required String ageLabel,
    required String guardianLine,
    required String medicalIdLine,
    required String medicalNotes,
  }) async {
    final p = await SharedPreferences.getInstance();
    this.childName = childName.trim();
    this.ageLabel = ageLabel.trim();
    this.guardianLine = guardianLine.trim();
    this.medicalIdLine = medicalIdLine.trim();
    this.medicalNotes = medicalNotes.trim();
    await p.setString(_kChildName, this.childName);
    await p.setString(_kChildAge, this.ageLabel);
    await p.setString(_kGuardian, this.guardianLine);
    await p.setString(_kMedicalId, this.medicalIdLine);
    await p.setString(_kNotes, this.medicalNotes);
    notifyListeners();
  }
}
