import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/health_level.dart';
import '../models/vital_reading.dart';
import '../state/monitor_controller.dart';
import '../theme/app_theme.dart';
import '../theme/breakpoints.dart';
import '../widgets/vitals_charts_panel.dart';
import 'daily_medical_report_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late MonitorController _monitor;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _monitor = context.read<MonitorController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _monitor.startAutoRefresh();
    });
  }

  @override
  void dispose() {
    _monitor.stopAutoRefresh();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wide = isWideLayout(context);
    return Scaffold(
      body: Stack(
        children: [
          Consumer<MonitorController>(
            builder: (context, ctrl, _) {
              final reading = ctrl.lastReading;
              return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.bgTop, Color(0xFFFFF5F9), AppColors.bgBottom],
                stops: [0, 0.45, 1],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: contentMaxWidth(context)),
                  child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: wide,
                    radius: const Radius.circular(8),
                    child: CustomScrollView(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      slivers: [
                        SliverPadding(
                          padding: pagePadding(context),
                          sliver: SliverToBoxAdapter(
                            child: _DashboardChrome(
                              wide: wide,
                              onSettings: () => _openSettings(context),
                              onReport: () => _openDailyReport(context),
                              ctrl: ctrl,
                            ),
                          ),
                        ),
                        if (ctrl.lastError != null)
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                              pagePadding(context).left,
                              0,
                              pagePadding(context).right,
                              12,
                            ),
                            sliver: SliverToBoxAdapter(child: _ErrorBanner(message: ctrl.lastError!)),
                          ),
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            pagePadding(context).left,
                            4,
                            pagePadding(context).right,
                            wide ? 20 : 12,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: _HealthHero(reading: reading, isBusy: ctrl.isRefreshing, wide: wide),
                          ),
                        ),
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            pagePadding(context).left,
                            0,
                            pagePadding(context).right,
                            wide ? 8 : 4,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: _SectionTitle(
                              title: 'المؤشرات الحيوية',
                              subtitle: wide ? 'قراءات لحظية من الحساسات المربوطة بالـ ESP32' : null,
                            ),
                          ),
                        ),
                        if (wide)
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                              pagePadding(context).left,
                              12,
                              pagePadding(context).right,
                              36,
                            ),
                            sliver: SliverToBoxAdapter(
                              child: _VitalsRowDesktop(
                                reading: reading,
                              ),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                              pagePadding(context).left - 4,
                              8,
                              pagePadding(context).right - 4,
                              28,
                            ),
                            sliver: SliverGrid(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 14,
                                crossAxisSpacing: 14,
                                childAspectRatio: 1.05,
                              ),
                              delegate: SliverChildListDelegate([
                                _VitalCard(
                                  icon: Icons.bubble_chart_rounded,
                                  title: 'الأكسجة',
                                  value: reading == null ? '—' : '${reading.spo2.toStringAsFixed(0)}%',
                                  subtitle: 'SpO₂',
                                  tint: const Color(0xFFF06292),
                                ),
                                _VitalCard(
                                  icon: Icons.favorite_rounded,
                                  title: 'نبض القلب',
                                  value: reading == null ? '—' : '${reading.heartRateBpm}',
                                  subtitle: 'نبضة / دقيقة',
                                  tint: const Color(0xFFE91E63),
                                ),
                                _VitalCard(
                                  icon: Icons.thermostat_rounded,
                                  title: 'حرارة',
                                  value: reading == null ? '—' : reading.temperatureC.toStringAsFixed(1),
                                  subtitle: '°م',
                                  tint: const Color(0xFFFFB74D),
                                  wide: true,
                                ),
                                _InfoCard(reading: reading),
                              ]),
                            ),
                          ),
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            pagePadding(context).left,
                            wide ? 6 : 10,
                            pagePadding(context).right,
                            wide ? 26 : 18,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _SectionTitle(
                                  title: 'مخططات المراقبة',
                                  subtitle: wide ? 'تتبّع الحرارة ونبض القلب عبر الزمن' : null,
                                ),
                                SizedBox(height: wide ? 14 : 10),
                                VitalsChartsPanel(history: ctrl.history),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
        ],
      ),
    );
  }

  Future<void> _openSettings(BuildContext context) async {
    context.read<MonitorController>().stopAutoRefresh();
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen()));
    if (context.mounted) {
      context.read<MonitorController>().startAutoRefresh();
    }
  }

  Future<void> _openDailyReport(BuildContext context) async {
    context.read<MonitorController>().stopAutoRefresh();
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const DailyMedicalReportScreen()));
    if (context.mounted) {
      context.read<MonitorController>().startAutoRefresh();
    }
  }
}

class _DashboardChrome extends StatelessWidget {
  const _DashboardChrome({
    required this.wide,
    required this.onSettings,
    required this.onReport,
    required this.ctrl,
  });

  final bool wide;
  final VoidCallback onSettings;
  final VoidCallback onReport;
  final MonitorController ctrl;

  @override
  Widget build(BuildContext context) {
    if (wide) {
      return _DesktopTopBar(onSettings: onSettings, onReport: onReport, ctrl: ctrl);
    }
    return _MobileHeader(onSettings: onSettings, onReport: onReport, ctrl: ctrl);
  }
}

class _DesktopTopBar extends StatelessWidget {
  const _DesktopTopBar({required this.onSettings, required this.onReport, required this.ctrl});

  final VoidCallback onSettings;
  final VoidCallback onReport;
  final MonitorController ctrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.85)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.12),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(alpha: 0.15),
                  AppColors.accentSoft.withValues(alpha: 0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.outline.withValues(alpha: 0.6)),
            ),
            child: Icon(Icons.monitor_heart_rounded, color: AppColors.primaryDark, size: 30),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'رعاية الطفل',
                  style: GoogleFonts.tajawal(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.1,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'لوحة مراقبة صحية ',
                  style: GoogleFonts.tajawal(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          _ConnectionStatusPill(ctrl: ctrl),
          const SizedBox(width: 8),
          FilledButton.tonalIcon(
            onPressed: onReport,
            icon: const Icon(Icons.description_rounded, size: 20),
            label: Text('تقرير يومي', style: GoogleFonts.tajawal(fontWeight: FontWeight.w700)),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonalIcon(
            onPressed: onSettings,
            icon: const Icon(Icons.tune_rounded, size: 20),
            label: Text('الإعدادات', style: GoogleFonts.tajawal(fontWeight: FontWeight.w700)),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectionStatusPill extends StatelessWidget {
  const _ConnectionStatusPill({required this.ctrl});

  final MonitorController ctrl;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final IconData icon;
    final String label;

    if (ctrl.lastError != null) {
      bg = AppColors.warn.withValues(alpha: 0.18);
      fg = const Color(0xFF8B5A00);
      icon = Icons.cloud_off_rounded;
      label = 'غير متصل';
    } else {
      bg = AppColors.ok.withValues(alpha: 0.18);
      fg = const Color(0xFF33691E);
      icon = Icons.wifi_rounded;
      label = 'متصل';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: fg.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: fg),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.tajawal(fontSize: 14, fontWeight: FontWeight.w800, color: fg),
          ),
        ],
      ),
    );
  }
}

class _MobileHeader extends StatelessWidget {
  const _MobileHeader({required this.onSettings, required this.onReport, required this.ctrl});

  final VoidCallback onSettings;
  final VoidCallback onReport;
  final MonitorController ctrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.outline),
                boxShadow: const [
                  BoxShadow(color: AppColors.shadow, blurRadius: 18, offset: Offset(0, 8)),
                ],
              ),
              child: Icon(Icons.child_care_rounded, color: AppColors.primary, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'رعاية الطفل',
                    style: GoogleFonts.tajawal(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'مراقبة لحظية عبر WiFi ',
                    style: GoogleFonts.tajawal(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onReport,
              icon: const Icon(Icons.description_rounded),
              tooltip: 'التقرير اليومي',
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.outline),
              ),
            ),
            IconButton(
              onPressed: onSettings,
              icon: const Icon(Icons.tune_rounded),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.outline),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Align(alignment: Alignment.centerLeft, child: _ConnectionStatusPill(ctrl: ctrl)),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final wide = isWideLayout(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 22,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.tajawal(
                fontSize: wide ? 20 : 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text(
              subtitle!,
              style: GoogleFonts.tajawal(
                fontSize: 13.5,
                height: 1.4,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _VitalsRowDesktop extends StatelessWidget {
  const _VitalsRowDesktop({required this.reading});

  final VitalReading? reading;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _MetricPanel(
              icon: Icons.bubble_chart_rounded,
              label: '  نسبةالأكسجة  في الدم',
              value: reading == null ? '—' : '${reading!.spo2.toStringAsFixed(0)}%',
              unit: 'SpO₂',
              accent: const Color(0xFFF06292),
              gradient: const [Color(0xFFFFE4EC), Color(0xFFFFFDFE)],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _MetricPanel(
              icon: Icons.favorite_rounded,
              label: 'معدل نبض القلب ',
              value: reading == null ? '—' : '${reading!.heartRateBpm}',
              unit: 'نبضة / دقيقة',
              accent: const Color(0xFFE91E63),
              gradient: const [Color(0xFFFCE4EC), Color(0xFFFFFDFE)],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _MetricPanel(
              icon: Icons.thermostat_rounded,
              label: 'حرارة الجسم',
              value: reading == null ? '—' : reading!.temperatureC.toStringAsFixed(1),
              unit: '°م',
              accent: const Color(0xFFFFB74D),
              gradient: const [Color(0xFFFFF3E0), Color(0xFFFFFDFE)],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _DevicePanel(reading: reading),
          ),
        ],
      ),
    );
  }
}

class _MetricPanel extends StatelessWidget {
  const _MetricPanel({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.accent,
    required this.gradient,
  });

  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color accent;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: gradient,
        ),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.9)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent, size: 24),
              ),
              const Spacer(),
              Icon(Icons.show_chart_rounded, size: 18, color: AppColors.textSecondary.withValues(alpha: 0.35)),
            ],
          ),
          Expanded(
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.tajawal(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: GoogleFonts.tajawal(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      height: 1.0,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    unit,
                    style: GoogleFonts.tajawal(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DevicePanel extends StatelessWidget {
  const _DevicePanel({required this.reading});

  final VitalReading? reading;

  @override
  Widget build(BuildContext context) {
    final name = reading?.deviceName ?? '—';
    final rssi = reading?.rssiDbm;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: AppColors.surface,
        border: Border.all(color: AppColors.outline),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.outline.withValues(alpha: 0.7)),
                ),
                child: Icon(Icons.hub_rounded, color: AppColors.primary, size: 24),
              ),
              const Spacer(),
            ],
          ),
          Expanded(
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الجهاز',
                    style: GoogleFonts.tajawal(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.tajawal(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (rssi != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'الإشارة: $rssi dBm',
                      style: GoogleFonts.tajawal(fontSize: 12.5, color: AppColors.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.warn.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.warn.withValues(alpha: 0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.warn, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تعذّر الاتصال بالخادم',
                    style: GoogleFonts.tajawal(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: GoogleFonts.tajawal(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                      height: 1.35,
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

class _HealthHero extends StatelessWidget {
  const _HealthHero({required this.reading, required this.isBusy, required this.wide});

  final VitalReading? reading;
  final bool isBusy;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final level = reading?.level ?? HealthLevel.offline;
    return ClipRRect(
      borderRadius: BorderRadius.circular(wide ? 28 : 26),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(wide ? 28 : 22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(alpha: 0.95),
                  AppColors.primaryDark,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.28),
                  blurRadius: wide ? 36 : 28,
                  offset: Offset(0, wide ? 18 : 14),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                      ),
                      child: Icon(level.icon, color: Colors.white, size: wide ? 30 : 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'الحالة العامة',
                            style: GoogleFonts.tajawal(
                              fontSize: wide ? 15 : 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.88),
                            ),
                          ),
                          Text(
                            level.labelAr,
                            style: GoogleFonts.tajawal(
                              fontSize: wide ? 32 : 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.1,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isBusy)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: wide ? 18 : 14),
                Text(
                  level.shortHintAr,
                  style: GoogleFonts.tajawal(
                    fontSize: wide ? 15 : 13.5,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
                if (reading != null) ...[
                  SizedBox(height: wide ? 18 : 14),
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded, size: 16, color: Colors.white.withValues(alpha: 0.75)),
                      const SizedBox(width: 6),
                      Text(
                        'آخر تحديث: ${_formatTime(reading!.receivedAt)}',
                        style: GoogleFonts.tajawal(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.78),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Positioned(
            right: -20,
            top: -30,
            child: IgnorePointer(
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
          ),
          Positioned(
            left: wide ? 120 : 60,
            bottom: -40,
            child: IgnorePointer(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    final s = t.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

class _VitalCard extends StatelessWidget {
  const _VitalCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.tint,
    this.wide = false,
  });

  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color tint;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: wide
            ? Row(
                children: [
                  _iconBox(),
                  const SizedBox(width: 14),
                  Expanded(child: _textColumn(crossAxis: CrossAxisAlignment.start)),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _iconBox(),
                  const Spacer(),
                  _textColumn(),
                ],
              ),
      ),
    );
  }

  Widget _iconBox() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: tint, size: 26),
    );
  }

  Widget _textColumn({CrossAxisAlignment crossAxis = CrossAxisAlignment.start}) {
    return Column(
      crossAxisAlignment: crossAxis,
      children: [
        Text(
          title,
          style: GoogleFonts.tajawal(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.tajawal(
            fontSize: wide ? 28 : 26,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryDark,
            height: 1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: GoogleFonts.tajawal(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.reading});

  final VitalReading? reading;

  @override
  Widget build(BuildContext context) {
    final name = reading?.deviceName ?? '—';
    final rssi = reading?.rssiDbm;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.hub_rounded, color: AppColors.accentSoft),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'الجهاز',
                    style: GoogleFonts.tajawal(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.tajawal(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            if (rssi != null) ...[
              const SizedBox(height: 6),
              Text(
                'قوة الإشارة: $rssi dBm',
                style: GoogleFonts.tajawal(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
