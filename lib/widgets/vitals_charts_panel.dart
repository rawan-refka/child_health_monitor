import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/vital_reading.dart';
import '../theme/app_theme.dart';
import '../theme/breakpoints.dart';

class VitalsChartsPanel extends StatelessWidget {
  const VitalsChartsPanel({super.key, required this.history});

  final List<VitalReading> history;

  @override
  Widget build(BuildContext context) {
    final wide = isWideLayout(context);
    if (history.length < 2) {
      return _panelShell(
        context,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 22),
          child: Text(
            'ابدأ التشغيل ليظهر الرسم البياني (نحتاج أكثر من قراءة).',
            style: GoogleFonts.tajawal(fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final temp = history.map((e) => e.temperatureC).toList(growable: false);
    final bpm = history.map((e) => e.heartRateBpm.toDouble()).toList(growable: false);
    final times = history.map((e) => e.receivedAt).toList(growable: false);

    final tempMin = temp.reduce((a, b) => a < b ? a : b);
    final tempMax = temp.reduce((a, b) => a > b ? a : b);
    final bpmMin = bpm.reduce((a, b) => a < b ? a : b);
    final bpmMax = bpm.reduce((a, b) => a > b ? a : b);

    final tempRange = (tempMax - tempMin).abs();
    final bpmRange = (bpmMax - bpmMin).abs();

    final tempPad = tempRange < 0.2 ? 0.2 : tempRange * 0.25;
    final bpmPad = bpmRange < 6 ? 6.0 : bpmRange * 0.25;

    final tempMinY = (tempMin - tempPad);
    final tempMaxY = (tempMax + tempPad);
    final bpmMinY = (bpmMin - bpmPad);
    final bpmMaxY = (bpmMax + bpmPad);

    final charts = wide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _MetricChart(
                  title: 'الحرارة (°م)',
                  accent: const Color(0xFFFFB74D),
                  minY: tempMinY,
                  maxY: tempMaxY,
                  spots: _spots(temp),
                  times: times,
                  valueFormatter: (v) => v.toStringAsFixed(1),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _MetricChart(
                  title: 'نبض القلب (BPM)',
                  accent: const Color(0xFFE91E63),
                  minY: bpmMinY,
                  maxY: bpmMaxY,
                  spots: _spots(bpm),
                  times: times,
                  valueFormatter: (v) => v.toStringAsFixed(0),
                ),
              ),
            ],
          )
        : Column(
            children: [
              _MetricChart(
                title: 'الحرارة (°م)',
                accent: const Color(0xFFFFB74D),
                minY: tempMinY,
                maxY: tempMaxY,
                spots: _spots(temp),
                times: times,
                valueFormatter: (v) => v.toStringAsFixed(1),
              ),
              const SizedBox(height: 14),
              _MetricChart(
                title: 'نبض القلب (BPM)',
                accent: const Color(0xFFE91E63),
                minY: bpmMinY,
                maxY: bpmMaxY,
                spots: _spots(bpm),
                times: times,
                valueFormatter: (v) => v.toStringAsFixed(0),
              ),
            ],
          );

    return _panelShell(context, child: charts);
  }

  List<FlSpot> _spots(List<double> values) {
    return <FlSpot>[
      for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i]),
    ];
  }

  Widget _panelShell(BuildContext context, {required Widget child}) {
    final wide = isWideLayout(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            AppColors.surface,
            AppColors.surfaceMuted.withValues(alpha: 0.85),
          ],
        ),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.95)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.1),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(wide ? 22 : 18),
        child: child,
      ),
    );
  }
}

class _MetricChart extends StatelessWidget {
  const _MetricChart({
    required this.title,
    required this.accent,
    required this.minY,
    required this.maxY,
    required this.spots,
    required this.times,
    required this.valueFormatter,
  });

  final String title;
  final Color accent;
  final double minY;
  final double maxY;
  final List<FlSpot> spots;
  final List<DateTime> times;
  final String Function(double) valueFormatter;

  @override
  Widget build(BuildContext context) {
    final wide = isWideLayout(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.show_chart_rounded, color: accent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.tajawal(fontSize: wide ? 16 : 15, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            height: wide ? 200 : 190,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (spots.length - 1).toDouble(),
                minY: minY,
                maxY: maxY,
                clipData: const FlClipData.all(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: AppColors.outline.withValues(alpha: 0.55),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: AppColors.outline.withValues(alpha: 0.6)),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      getTitlesWidget: (value, meta) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Text(
                          valueFormatter(value),
                          style: GoogleFonts.tajawal(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      interval: _bottomInterval(spots.length),
                      getTitlesWidget: (value, meta) {
                        final i = value.round();
                        if (i < 0 || i >= times.length) return const SizedBox.shrink();
                        final t = times[i];
                        final label = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            label,
                            style: GoogleFonts.tajawal(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    tooltipRoundedRadius: 12,
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((s) {
                        final i = s.x.round().clamp(0, times.length - 1);
                        final t = times[i];
                        final timeStr = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';
                        return LineTooltipItem(
                          '${valueFormatter(s.y)}\n$timeStr',
                          GoogleFonts.tajawal(fontWeight: FontWeight.w800, color: AppColors.textPrimary, height: 1.25),
                        );
                      }).toList(growable: false);
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.22,
                    color: accent,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: false,
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          accent.withValues(alpha: 0.18),
                          accent.withValues(alpha: 0.02),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  double _bottomInterval(int len) {
    if (len <= 8) return 1;
    if (len <= 20) return 4;
    if (len <= 60) return 10;
    return 20;
  }
}

