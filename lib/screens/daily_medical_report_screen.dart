import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/daily_report_stats.dart';
import '../models/health_level.dart';
import '../models/vital_log_entry.dart';
import '../services/daily_report_pdf_service.dart';
import '../services/vitals_daily_log_service.dart';
import '../state/child_profile_controller.dart';
import '../theme/app_theme.dart';
import '../theme/breakpoints.dart';

class DailyMedicalReportScreen extends StatefulWidget {
  const DailyMedicalReportScreen({super.key});

  @override
  State<DailyMedicalReportScreen> createState() => _DailyMedicalReportScreenState();
}

class _DailyMedicalReportScreenState extends State<DailyMedicalReportScreen> {
  late DateTime _selectedDay;
  Future<DailyReportStats>? _loadFuture;

  @override
  void initState() {
    super.initState();
    _selectedDay = _dateOnly(DateTime.now());
    _reload();
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  void _reload() {
    setState(() {
      _loadFuture = _loadStats(_selectedDay);
    });
  }

  Future<DailyReportStats> _loadStats(DateTime day) async {
    final entries = await VitalsDailyLogService.loadDay(day);
    return DailyReportStats.fromEntries(entries);
  }

  void _shiftDay(int delta) {
    final n = _selectedDay.add(Duration(days: delta));
    final today = _dateOnly(DateTime.now());
    if (n.isAfter(today)) return;
    setState(() {
      _selectedDay = n;
      _reload();
    });
  }

  @override
  Widget build(BuildContext context) {
    final wide = isWideLayout(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('التقرير الطبي اليومي', style: GoogleFonts.tajawal(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            tooltip: 'تصدير PDF (عربي)',
            icon: const Icon(Icons.picture_as_pdf_rounded),
            onPressed: () async {
              final profile = context.read<ChildProfileController>();
              final messenger = ScaffoldMessenger.of(context);
              final nav = Navigator.of(context, rootNavigator: true);
              final entries = await VitalsDailyLogService.loadDay(_selectedDay);
              final stats = DailyReportStats.fromEntries(entries);
              if (!context.mounted) return;
              showDialog<void>(
                context: context,
                barrierDismissible: false,
                builder: (ctx) => PopScope(
                  canPop: false,
                  child: Material(
                    color: Colors.black26,
                    child: Center(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(width: 20),
                              Text('جاري إنشاء PDF...', style: GoogleFonts.tajawal(fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
              try {
                final bytes = await DailyReportPdfService.build(
                  stats: stats,
                  profile: profile,
                  day: _selectedDay,
                );
                final name = DailyReportPdfService.fileNameForDay(_selectedDay);
                final dir = await getTemporaryDirectory();
                final filePath = p.join(dir.path, name);
                final f = File(filePath);
                await f.writeAsBytes(bytes);
                await Share.shareXFiles(
                  <XFile>[
                    XFile(filePath, mimeType: 'application/pdf', name: name),
                  ],
                  subject: 'تقرير مراقبة حيوية — $name',
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('تعذّر إنشاء PDF: $e', style: GoogleFonts.tajawal())),
                );
              } finally {
                if (context.mounted) nav.pop();
              }
            },
          ),
          IconButton(
            tooltip: 'نسخ نص التقرير',
            icon: const Icon(Icons.copy_rounded),
            onPressed: () async {
              final profile = context.read<ChildProfileController>();
              final entries = await VitalsDailyLogService.loadDay(_selectedDay);
              final stats = DailyReportStats.fromEntries(entries);
              if (!context.mounted) return;
              final text = _buildReportPlainText(stats: stats, profile: profile, day: _selectedDay);
              await Clipboard.setData(ClipboardData(text: text));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('تم النسخ', style: GoogleFonts.tajawal())),
                );
              }
            },
          ),
          IconButton(
            tooltip: 'مشاركة',
            icon: const Icon(Icons.share_rounded),
            onPressed: () async {
              final profile = context.read<ChildProfileController>();
              final entries = await VitalsDailyLogService.loadDay(_selectedDay);
              final stats = DailyReportStats.fromEntries(entries);
              if (!context.mounted) return;
              final text = _buildReportPlainText(stats: stats, profile: profile, day: _selectedDay);
              await Share.share(text, subject: 'تقرير مراقبة حيوية — ${_fmtDay(_selectedDay)}');
            },
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: wide ? 760 : double.infinity),
          child: FutureBuilder<DailyReportStats>(
            future: _loadFuture,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('تعذر تحميل التقرير: ${snap.error}', style: GoogleFonts.tajawal()),
                  ),
                );
              }
              final stats = snap.data ?? DailyReportStats.fromEntries(<VitalLogEntry>[]);
              return RefreshIndicator(
                onRefresh: () async {
                  final f = _loadStats(_selectedDay);
                  setState(() => _loadFuture = f);
                  await f;
                },
                child: ListView(
                  padding: pagePadding(context).copyWith(bottom: 32),
                  children: [
                    _DateSelectorBar(
                      label: _fmtDay(_selectedDay),
                      canGoNext: _selectedDay.isBefore(_dateOnly(DateTime.now())),
                      onPrev: () => _shiftDay(-1),
                      onNext: () => _shiftDay(1),
                    ),
                    const SizedBox(height: 16),
                    _ReportHeaderCard(day: _selectedDay),
                    const SizedBox(height: 14),
                    Consumer<ChildProfileController>(
                      builder: (context, profile, _) => _ChildIdentityCard(profile: profile),
                    ),
                    const SizedBox(height: 14),
                    if (!stats.hasData)
                      _EmptyDayCard()
                    else ...[
                      _SummaryStatsCard(stats: stats),
                      const SizedBox(height: 14),
                      _LevelDistributionCard(stats: stats),
                      const SizedBox(height: 14),
                      _TimeRangeCard(stats: stats),
                    ],
                    const SizedBox(height: 20),
                    _DisclaimerCard(),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  String _fmtDay(DateTime d) {
    try {
      return DateFormat('EEEE، d MMMM y', 'ar').format(d);
    } catch (_) {
      return '${d.year}/${d.month}/${d.day}';
    }
  }

  String _buildReportPlainText({
    required DailyReportStats stats,
    required ChildProfileController profile,
    required DateTime day,
  }) {
    final buf = StringBuffer();
    buf.writeln('══ تقرير مراقبة حيوية يومي ══');
    buf.writeln(_fmtDay(day));
    buf.writeln('');
    buf.writeln('— بيانات الطفل —');
    buf.writeln('الاسم: ${profile.childName.isEmpty ? "—" : profile.childName}');
    buf.writeln('العمر / العمر الإجمالي: ${profile.ageLabel.isEmpty ? "—" : profile.ageLabel}');
    buf.writeln('ولي الأمر / المرافق: ${profile.guardianLine.isEmpty ? "—" : profile.guardianLine}');
    buf.writeln('رقم ملف / معرّف: ${profile.medicalIdLine.isEmpty ? "—" : profile.medicalIdLine}');
    if (profile.medicalNotes.isNotEmpty) {
      buf.writeln('ملاحظات طبية/دوائية: ${profile.medicalNotes}');
    }
    buf.writeln('');
    if (!stats.hasData) {
      buf.writeln('لا توجد قراءات مسجّلة لهذا اليوم.');
      buf.writeln(_disclaimerText());
      return buf.toString();
    }
    buf.writeln('— ملخص القياسات —');
    buf.writeln('عدد القراءات المسجّلة: ${stats.entries.length}');
    buf.writeln(
      'SpO₂: ${_fmtOpt(stats.spo2Min)} – ${_fmtOpt(stats.spo2Max)} (متوسط ${_fmtOpt(stats.spo2Avg)}) %',
    );
    buf.writeln(
      'نبض القلب: ${_fmtIntOpt(stats.bpmMin)} – ${_fmtIntOpt(stats.bpmMax)} (متوسط ${_fmtOpt(stats.bpmAvg)}) نبضة/دقيقة',
    );
    buf.writeln(
      'الحرارة: ${_fmtOpt(stats.tempMin)} – ${_fmtOpt(stats.tempMax)} (متوسط ${_fmtOpt(stats.tempAvg)}) °م',
    );
    buf.writeln('');
    buf.writeln('— توزيع الحالة العامة —');
    buf.writeln('مستقر: ${stats.countOk} | مراقبة: ${stats.countWatch} | تنبيه: ${stats.countAlert} | غير متصل: ${stats.countOffline}');
    buf.writeln('');
    buf.writeln('— الفترة الزمنية للقياسات —');
    buf.writeln('أول قراءة: ${_fmtTime(stats.firstAt)}');
    buf.writeln('آخر قراءة: ${_fmtTime(stats.lastAt)}');
    buf.writeln('');
    buf.writeln(_disclaimerText());
    return buf.toString();
  }

  String _fmtOpt(double? v) => v == null ? '—' : v.toStringAsFixed(1);
  String _fmtIntOpt(int? v) => v == null ? '—' : '$v';
  String _fmtTime(DateTime? t) => t == null ? '—' : DateFormat('HH:mm:ss', 'ar').format(t);

  String _disclaimerText() =>
      'إخلاء مسؤولية: هذا التقرير مبني على قراءات جهاز استشعار ولا يغني عن الفحص الطبي أو تشخيص طبيب. في الحالات الطارئة اتصل بخدمات الطوارئ.';
}

class _DateSelectorBar extends StatelessWidget {
  const _DateSelectorBar({
    required this.label,
    required this.canGoNext,
    required this.onPrev,
    required this.onNext,
  });

  final String label;
  final bool canGoNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_right_rounded)),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.tajawal(fontWeight: FontWeight.w800, fontSize: 15),
              ),
            ),
            IconButton(
              onPressed: canGoNext ? onNext : null,
              icon: const Icon(Icons.chevron_left_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportHeaderCard extends StatelessWidget {
  const _ReportHeaderCard({required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [AppColors.primary.withValues(alpha: 0.92), AppColors.primaryDark],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'تقرير مراقبة حيوية',
            style: GoogleFonts.tajawal(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'ملخص يومي للأكسجة ونبض القلب وحرارة الجسم (حسب التسجيل في التطبيق)',
            style: GoogleFonts.tajawal(
              fontSize: 13,
              height: 1.45,
              color: Colors.white.withValues(alpha: 0.92),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChildIdentityCard extends StatelessWidget {
  const _ChildIdentityCard({required this.profile});

  final ChildProfileController profile;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.badge_rounded, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'هوية الطفل والمرافق',
                  style: GoogleFonts.tajawal(fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _kv('اسم الطفل', profile.childName.isEmpty ? '—' : profile.childName),
            _kv('العمر / وصف عمر', profile.ageLabel.isEmpty ? '—' : profile.ageLabel),
            _kv('ولي الأمر / المرافق', profile.guardianLine.isEmpty ? '—' : profile.guardianLine),
            _kv('رقم ملف / معرّف', profile.medicalIdLine.isEmpty ? '—' : profile.medicalIdLine),
            if (profile.medicalNotes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'ملاحظات طبية / دوائية',
                style: GoogleFonts.tajawal(fontWeight: FontWeight.w700, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(profile.medicalNotes, style: GoogleFonts.tajawal(height: 1.4)),
            ],
            const SizedBox(height: 8),
            Text(
              'عدّل هذه البيانات من الإعدادات ← بيانات الطفل للتقارير',
              style: GoogleFonts.tajawal(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(k, style: GoogleFonts.tajawal(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(v, style: GoogleFonts.tajawal(fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}

class _EmptyDayCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.analytics_outlined, size: 48, color: AppColors.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(
              'لا توجد قراءات مسجّلة لهذا اليوم',
              textAlign: TextAlign.center,
              style: GoogleFonts.tajawal(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'يتم تسجيل القراءات تلقائياً عند نجاح الاتصال بالجهاز. تأكد من تشغيل الـESP واتصال الهاتف بنفس الشبكة.',
              textAlign: TextAlign.center,
              style: GoogleFonts.tajawal(fontSize: 13, height: 1.45, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryStatsCard extends StatelessWidget {
  const _SummaryStatsCard({required this.stats});

  final DailyReportStats stats;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ملخص القياسات',
              style: GoogleFonts.tajawal(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'إحصاءات من جميع النقاط المسجّلة لهذا اليوم',
              style: GoogleFonts.tajawal(fontSize: 12.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            _statRow('عدد القراءات', '${stats.entries.length}', Icons.dataset_rounded),
            _statRow(
              'SpO₂ (%)',
              _rangeAvg(stats.spo2Min, stats.spo2Max, stats.spo2Avg, decimals: 1),
              Icons.bubble_chart_rounded,
              color: const Color(0xFFF06292),
            ),
            _statRow(
              'نبض القلب (نبضة/دقيقة)',
              _rangeAvgInt(stats.bpmMin, stats.bpmMax, stats.bpmAvg),
              Icons.favorite_rounded,
              color: const Color(0xFFE91E63),
            ),
            _statRow(
              'حرارة الجسم (°م)',
              _rangeAvg(stats.tempMin, stats.tempMax, stats.tempAvg, decimals: 1),
              Icons.thermostat_rounded,
              color: const Color(0xFFFFB74D),
            ),
          ],
        ),
      ),
    );
  }

  String _rangeAvg(double? min, double? max, double? avg, {int decimals = 1}) {
    if (min == null || max == null || avg == null) return '—';
    return '${min.toStringAsFixed(decimals)} – ${max.toStringAsFixed(decimals)} · معدل ${avg.toStringAsFixed(decimals)}';
  }

  String _rangeAvgInt(int? min, int? max, double? avg) {
    if (min == null || max == null || avg == null) return '—';
    return '$min – $max · معدل ${avg.toStringAsFixed(1)}';
  }

  Widget _statRow(String title, String value, IconData icon, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (color ?? AppColors.primary).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color ?? AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.tajawal(fontWeight: FontWeight.w700, fontSize: 13.5)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.tajawal(fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelDistributionCard extends StatelessWidget {
  const _LevelDistributionCard({required this.stats});

  final DailyReportStats stats;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'توزيع الحالة العامة',
              style: GoogleFonts.tajawal(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip(HealthLevel.ok.labelAr, stats.countOk, AppColors.ok),
                _chip(HealthLevel.watch.labelAr, stats.countWatch, AppColors.warn),
                _chip(HealthLevel.alert.labelAr, stats.countAlert, AppColors.alert),
                _chip(HealthLevel.offline.labelAr, stats.countOffline, AppColors.textSecondary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, int n, Color c) {
    return Chip(
      label: Text('$label: $n', style: GoogleFonts.tajawal(fontWeight: FontWeight.w800)),
      backgroundColor: c.withValues(alpha: 0.14),
      side: BorderSide(color: c.withValues(alpha: 0.35)),
    );
  }
}

class _TimeRangeCard extends StatelessWidget {
  const _TimeRangeCard({required this.stats});

  final DailyReportStats stats;

  @override
  Widget build(BuildContext context) {
    final f = DateFormat('HH:mm:ss');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الفترة الزمنية',
              style: GoogleFonts.tajawal(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              'أول قراءة: ${stats.firstAt != null ? f.format(stats.firstAt!) : "—"}',
              style: GoogleFonts.tajawal(fontWeight: FontWeight.w600),
            ),
            Text(
              'آخر قراءة: ${stats.lastAt != null ? f.format(stats.lastAt!) : "—"}',
              style: GoogleFonts.tajawal(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _DisclaimerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.warn.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.medical_information_outlined, color: AppColors.warn),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'إخلاء مسؤولية: هذا التقرير مبني على قراءات جهاز استشعار وتطبيق مراقبة منزلية؛ لا يُعد تشخيصاً طبياً ولا يغني عن مراجعة مختص. في الطوارئ أو عند تدهور الحالة يُنصح بالاتصال بخدمات الطوارئ.',
                style: GoogleFonts.tajawal(fontSize: 12.5, height: 1.45, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
