import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../state/project_credits_controller.dart';
import '../theme/app_theme.dart';

/// محرر غلاف المشروع الأكاديمي — تصميم شبيه بالغلاف الرسمي.
class ProjectCoverEditor extends StatefulWidget {
  const ProjectCoverEditor({super.key});

  @override
  State<ProjectCoverEditor> createState() => _ProjectCoverEditorState();
}

class _ProjectCoverEditorState extends State<ProjectCoverEditor> {
  late final TextEditingController _title;
  late final TextEditingController _tagline;
  late final TextEditingController _students;
  late final TextEditingController _supervisor;
  late final TextEditingController _uniAr;
  late final TextEditingController _uniEn;

  @override
  void initState() {
    super.initState();
    final c = context.read<ProjectCreditsController>();
    _title = TextEditingController(text: c.projectTitle);
    _tagline = TextEditingController(text: c.projectTagline);
    _students = TextEditingController(text: c.studentsLine);
    _supervisor = TextEditingController(text: c.supervisorLine);
    _uniAr = TextEditingController(text: c.universityAr);
    _uniEn = TextEditingController(text: c.universityEn);
  }

  @override
  void dispose() {
    _title.dispose();
    _tagline.dispose();
    _students.dispose();
    _supervisor.dispose();
    _uniAr.dispose();
    _uniEn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            AppColors.surface,
            AppColors.surfaceMuted,
          ],
        ),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.85)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.12),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.12),
                    AppColors.accentSoft.withValues(alpha: 0.25),
                  ],
                ),
                border: Border(
                  bottom: BorderSide(color: AppColors.outline.withValues(alpha: 0.6)),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.outline),
                    ),
                    child: Icon(Icons.menu_book_rounded, color: AppColors.primaryDark, size: 30),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'غلاف المشروع الأكاديمي',
                          style: GoogleFonts.tajawal(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'يظهر في شاشة البداية كبطاقة تعريف رسمية — صياغة كاملة للعرض والتسليم.',
                          style: GoogleFonts.tajawal(
                            fontSize: 12.5,
                            height: 1.4,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _CoverField(
                    controller: _title,
                    label: 'عنوان المشروع',
                    hint: 'مثال: رعاية الطفل',
                    icon: Icons.title_rounded,
                  ),
                  const SizedBox(height: 14),
                  _CoverField(
                    controller: _tagline,
                    label: 'وصف مختصر / سطر فرعي',
                    hint: 'مثال: تطبيق مراقبة صحة الأطفال — WiFi · ESP32',
                    icon: Icons.short_text_rounded,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 14),
                  _CoverField(
                    controller: _students,
                    label: 'أسماء الطالبات أو الفريق',
                    hint: 'مثال: ماريا · روان',
                    icon: Icons.groups_rounded,
                  ),
                  const SizedBox(height: 14),
                  _CoverField(
                    controller: _supervisor,
                    label: 'الإشراف الأكاديمي',
                    hint: 'مثال: إشراف: د. فلان الفلاني',
                    icon: Icons.badge_rounded,
                  ),
                  const SizedBox(height: 14),
                  _CoverField(
                    controller: _uniAr,
                    label: 'اسم الجامعة (عربي)',
                    hint: 'الجامعة الدولية للعلوم والتكنولوجيا',
                    icon: Icons.account_balance_rounded,
                  ),
                  const SizedBox(height: 14),
                  _CoverField(
                    controller: _uniEn,
                    label: 'الاختصار أو الاسم (إنجليزي)',
                    hint: 'IUST',
                    icon: Icons.language_rounded,
                    textDirection: TextDirection.ltr,
                  ),
                  const SizedBox(height: 22),
                  FilledButton.icon(
                    onPressed: () async {
                      final pc = context.read<ProjectCreditsController>();
                      await pc.save(
                        projectTitle: _title.text,
                        projectTagline: _tagline.text,
                        studentsLine: _students.text,
                        supervisorLine: _supervisor.text,
                        universityAr: _uniAr.text,
                        universityEn: _uniEn.text,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'تم حفظ بيانات الغلاف',
                              style: GoogleFonts.tajawal(fontWeight: FontWeight.w600),
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: Text('حفظ بيانات الغلاف', style: GoogleFonts.tajawal(fontWeight: FontWeight.w800)),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoverField extends StatelessWidget {
  const _CoverField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
    this.textDirection,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final int maxLines;
  final TextDirection? textDirection;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      textDirection: textDirection,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary, size: 22),
        alignLabelWithHint: maxLines > 1,
      ),
    );
  }
}
