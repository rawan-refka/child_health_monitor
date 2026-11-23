import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../state/child_profile_controller.dart';
import '../state/monitor_controller.dart';
import '../theme/app_theme.dart';
import '../theme/breakpoints.dart';
import 'project_cover_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    final c = context.read<MonitorController>();
    _urlController = TextEditingController(text: c.baseUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wide = isWideLayout(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: wide ? 720 : double.infinity),
          child: ListView(
            padding: pagePadding(context),
            children: [
          _CoverSettingsEntry(wide: wide),
          SizedBox(height: wide ? 28 : 22),
          Text(
            'اتصال ESP32',
            style: GoogleFonts.tajawal(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'أدخل عنوان IP الذي يطبعه الـ ESP32 على المنفذ 80. المسار المتوقع: /vitals',
            style: GoogleFonts.tajawal(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _urlController,
            textDirection: TextDirection.ltr,
            decoration: const InputDecoration(
              labelText: 'العنوان (مثال: 192.168.1.80)',
              prefixIcon: Icon(Icons.link_rounded),
            ),
            onSubmitted: (_) => _saveUrl(context),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => _saveUrl(context),
            icon: const Icon(Icons.save_rounded),
            label: const Text('حفظ العنوان'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'بيانات الطفل للتقارير الطبية',
            style: GoogleFonts.tajawal(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'تُستخدم في «التقرير اليومي» ومشاركة النص — لا تُرسل تلقائياً لأي جهة.',
            style: GoogleFonts.tajawal(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 14),
          const _ChildProfileFields(),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: EdgeInsets.all(wide ? 22 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'صيغة JSON المتوقعة من /vitals',
                        style: GoogleFonts.tajawal(fontWeight: FontWeight.w800, fontSize: wide ? 15 : 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SelectableText(
                    '''
{
  "spo2": 98,
  "bpm": 92,
  "temp_c": 36.7,
  "status": "ok",
  "rssi": -52,
  "device": "child_unit_1"
}''',
                    style: GoogleFonts.robotoMono(fontSize: wide ? 12.5 : 11.5, height: 1.35),
                  ),
                ],
              ),
            ),
          ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveUrl(BuildContext context) async {
    await context.read<MonitorController>().setBaseUrl(_urlController.text);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم حفظ العنوان', style: GoogleFonts.tajawal())),
      );
    }
  }
}

class _ChildProfileFields extends StatefulWidget {
  const _ChildProfileFields();

  @override
  State<_ChildProfileFields> createState() => _ChildProfileFieldsState();
}

class _ChildProfileFieldsState extends State<_ChildProfileFields> {
  late final TextEditingController _name;
  late final TextEditingController _age;
  late final TextEditingController _guardian;
  late final TextEditingController _medicalId;
  late final TextEditingController _notes;

  @override
  void initState() {
    super.initState();
    final c = context.read<ChildProfileController>();
    _name = TextEditingController(text: c.childName);
    _age = TextEditingController(text: c.ageLabel);
    _guardian = TextEditingController(text: c.guardianLine);
    _medicalId = TextEditingController(text: c.medicalIdLine);
    _notes = TextEditingController(text: c.medicalNotes);
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _guardian.dispose();
    _medicalId.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _name,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'اسم الطفل',
            prefixIcon: Icon(Icons.person_rounded),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _age,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'العمر أو وصف عمر (مثال: 5 سنوات)',
            prefixIcon: Icon(Icons.cake_rounded),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _guardian,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'ولي الأمر / المرافق',
            prefixIcon: Icon(Icons.family_restroom_rounded),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _medicalId,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'رقم ملف / معرّف (اختياري)',
            prefixIcon: Icon(Icons.numbers_rounded),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notes,
          minLines: 2,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'ملاحظات طبية / دوائية (اختياري)',
            alignLabelWithHint: true,
            prefixIcon: Icon(Icons.medical_information_outlined),
          ),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: () async {
            await context.read<ChildProfileController>().save(
                  childName: _name.text,
                  ageLabel: _age.text,
                  guardianLine: _guardian.text,
                  medicalIdLine: _medicalId.text,
                  medicalNotes: _notes.text,
                );
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('تم حفظ بيانات الطفل', style: GoogleFonts.tajawal())),
              );
            }
          },
          icon: const Icon(Icons.save_rounded),
          label: const Text('حفظ بيانات التقرير'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ],
    );
  }
}

class _CoverSettingsEntry extends StatelessWidget {
  const _CoverSettingsEntry({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push<void>(
            MaterialPageRoute<void>(builder: (_) => const ProjectCoverScreen()),
          );
        },
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.outline.withValues(alpha: 0.95)),
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                AppColors.surface,
                AppColors.surfaceMuted.withValues(alpha: 0.9),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.2),
                        AppColors.accentSoft.withValues(alpha: 0.4),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.outline.withValues(alpha: 0.6)),
                  ),
                  child: Icon(Icons.menu_book_rounded, color: AppColors.primaryDark, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تعديل معلومات الغلاف',
                        style: GoogleFonts.tajawal(
                          fontSize: wide ? 18 : 17,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'العنوان، الطالبات، الإشراف، الجامعة — يظهر في شاشة البداية',
                        style: GoogleFonts.tajawal(
                          fontSize: 13,
                          height: 1.4,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: AppColors.primary, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
