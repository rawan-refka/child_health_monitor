import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../state/project_credits_controller.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';

/// شاشة البداية قبل الدخول للوحة التحكم — تعرض بيانات الغلاف من الإعدادات.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<ProjectCreditsController>(
        builder: (context, credits, _) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF852957),
                  AppColors.primaryDark,
                  AppColors.primary,
                  Color(0xFFF8BBD0),
                ],
                stops: [0.0, 0.25, 0.55, 1.0],
              ),
            ),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight - 40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 32,
                                  offset: const Offset(0, 16),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.child_care_rounded,
                              size: 72,
                              color: Colors.white.withValues(alpha: 0.95),
                            ),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            credits.projectTitle,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.tajawal(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.15,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            credits.projectTagline,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.tajawal(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.88),
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 28,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _CreditRow(
                                  icon: Icons.school_rounded,
                                  label: 'الطالبات / الفريق',
                                  value: credits.studentsLine,
                                ),
                                const Divider(height: 28),
                                _CreditRow(
                                  icon: Icons.person_outline_rounded,
                                  label: 'الإشراف',
                                  value: credits.supervisorLine,
                                ),
                                const Divider(height: 28),
                                _CreditRow(
                                  icon: Icons.account_balance_rounded,
                                  label: 'الجامعة',
                                  value: credits.universityAr,
                                  valueEnglish: credits.universityEn,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: () {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute<void>(builder: (_) => const DashboardScreen()),
                                );
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.primaryDark,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 2,
                              ),
                              child: Text(
                                'استمرار',
                                style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CreditRow extends StatelessWidget {
  const _CreditRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueEnglish,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? valueEnglish;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primaryDark, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.tajawal(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.tajawal(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  height: 1.35,
                ),
              ),
              if (valueEnglish != null && valueEnglish!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  valueEnglish!,
                  style: GoogleFonts.tajawal(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
