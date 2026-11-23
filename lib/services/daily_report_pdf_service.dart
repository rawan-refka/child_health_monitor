import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/daily_report_stats.dart';
import '../models/health_level.dart';
import '../state/child_profile_controller.dart';

/// يبني PDF بتنسيق A4، اتجاه RTL، وخط عربي (Noto Naskh Arabic) من Google Fonts.
class DailyReportPdfService {
  DailyReportPdfService._();

  static String _fmtDay(DateTime d) {
    try {
      return DateFormat('EEEE، d MMMM y', 'ar').format(d);
    } catch (_) {
      return '${d.year}/${d.month}/${d.day}';
    }
  }

  static String _fmtOpt(double? v) => v == null ? '—' : v.toStringAsFixed(1);
  static String _fmtIntOpt(int? v) => v == null ? '—' : '$v';
  static String _fmtTime(DateTime? t) => t == null ? '—' : DateFormat('HH:mm:ss', 'ar').format(t);

  static String _disclaimer() =>
      'إخلاء مسؤولية: هذا التقرير مبني على قراءات جهاز استشعار وتطبيق مراقبة منزلية؛ لا يُعد تشخيصاً طبياً ولا يغني عن مراجعة مختص. في الطوارئ اتصل بخدمات الطوارئ.';

  static Future<Uint8List> build({
    required DailyReportStats stats,
    required ChildProfileController profile,
    required DateTime day,
  }) async {
    final base = await PdfGoogleFonts.notoNaskhArabicRegular();
    final bold = await PdfGoogleFonts.notoNaskhArabicBold();

    final titleStyle = pw.TextStyle(font: bold, fontSize: 18);
    final h2 = pw.TextStyle(font: bold, fontSize: 13);
    final body = pw.TextStyle(font: base, fontSize: 11);
    final small = pw.TextStyle(font: base, fontSize: 9.5, color: PdfColors.grey700);

    pw.Widget row(String label, String value) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 3),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 2,
              child: pw.Text(label, style: h2, textDirection: pw.TextDirection.rtl),
            ),
            pw.Expanded(
              flex: 3,
              child: pw.Text(value, style: body, textDirection: pw.TextDirection.rtl),
            ),
          ],
        ),
      );
    }

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: base, bold: bold),
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        textDirection: pw.TextDirection.rtl,
        build: (context) => [
          pw.Text('تقرير مراقبة حيوية يومي', style: titleStyle, textAlign: pw.TextAlign.center),
          pw.SizedBox(height: 6),
          pw.Text(_fmtDay(day), style: body, textAlign: pw.TextAlign.center),
          pw.SizedBox(height: 16),
          pw.Divider(thickness: 0.7, color: PdfColors.grey400),
          pw.SizedBox(height: 8),
          pw.Text('بيانات الطفل والمرافق', style: h2),
          pw.SizedBox(height: 6),
          row('اسم الطفل', profile.childName.isEmpty ? '—' : profile.childName),
          row('العمر', profile.ageLabel.isEmpty ? '—' : profile.ageLabel),
          row('ولي الأمر / المرافق', profile.guardianLine.isEmpty ? '—' : profile.guardianLine),
          row('رقم ملف / معرّف', profile.medicalIdLine.isEmpty ? '—' : profile.medicalIdLine),
          if (profile.medicalNotes.isNotEmpty)
            row('ملاحظات طبية / دوائية', profile.medicalNotes),
          pw.SizedBox(height: 14),
          pw.Divider(thickness: 0.7, color: PdfColors.grey400),
          pw.SizedBox(height: 8),
          if (!stats.hasData) ...[
            pw.Text('لا توجد قراءات مسجّلة لهذا اليوم.', style: body),
          ] else ...[
            pw.Text('ملخص القياسات', style: h2),
            pw.SizedBox(height: 6),
            row('عدد القراءات', '${stats.entries.length}'),
            row(
              'الأكسجة SpO₂ (%)',
              '${_fmtOpt(stats.spo2Min)} – ${_fmtOpt(stats.spo2Max)} (متوسط ${_fmtOpt(stats.spo2Avg)})',
            ),
            row(
              'نبض القلب (نبضة/دقيقة)',
              '${_fmtIntOpt(stats.bpmMin)} – ${_fmtIntOpt(stats.bpmMax)} (متوسط ${_fmtOpt(stats.bpmAvg)})',
            ),
            row(
              'حرارة الجسم (°م)',
              '${_fmtOpt(stats.tempMin)} – ${_fmtOpt(stats.tempMax)} (متوسط ${_fmtOpt(stats.tempAvg)})',
            ),
            pw.SizedBox(height: 10),
            pw.Text('توزيع الحالة العامة', style: h2),
            pw.SizedBox(height: 6),
            row(HealthLevel.ok.labelAr, '${stats.countOk}'),
            row(HealthLevel.watch.labelAr, '${stats.countWatch}'),
            row(HealthLevel.alert.labelAr, '${stats.countAlert}'),
            row(HealthLevel.offline.labelAr, '${stats.countOffline}'),
            pw.SizedBox(height: 10),
            pw.Text('الفترة الزمنية للقياسات', style: h2),
            pw.SizedBox(height: 6),
            row('أول قراءة', _fmtTime(stats.firstAt)),
            row('آخر قراءة', _fmtTime(stats.lastAt)),
          ],
          pw.SizedBox(height: 16),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.amber50,
              border: pw.Border.all(color: PdfColors.amber300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Text(_disclaimer(), style: small, textDirection: pw.TextDirection.rtl),
          ),
        ],
      ),
    );

    return doc.save();
  }

  static String fileNameForDay(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return 'child_vitals_report_$y-$m-$dd.pdf';
  }
}
