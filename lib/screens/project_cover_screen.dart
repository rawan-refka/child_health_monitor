import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/breakpoints.dart';
import '../widgets/project_cover_editor.dart';

/// شاشة تعديل غلاف المشروع — تُفتح من الإعدادات فقط.
class ProjectCoverScreen extends StatelessWidget {
  const ProjectCoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wide = isWideLayout(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'تعديل معلومات الغلاف',
          style: GoogleFonts.tajawal(fontWeight: FontWeight.w800),
        ),
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
            children: const [
              ProjectCoverEditor(),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
