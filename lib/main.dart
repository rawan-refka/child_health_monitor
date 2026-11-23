import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'screens/splash_screen.dart';
import 'state/child_profile_controller.dart';
import 'state/monitor_controller.dart';
import 'state/project_credits_controller.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final projectCredits = ProjectCreditsController();
  final childProfile = ChildProfileController();
  await projectCredits.loadPrefs();
  await childProfile.loadPrefs();
  runApp(ChildHealthApp(projectCredits: projectCredits, childProfile: childProfile));
}

class ChildHealthApp extends StatelessWidget {
  const ChildHealthApp({super.key, required this.projectCredits, required this.childProfile});

  final ProjectCreditsController projectCredits;
  final ChildProfileController childProfile;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: projectCredits),
        ChangeNotifierProvider.value(value: childProfile),
        ChangeNotifierProvider(create: (_) => MonitorController()..loadPrefs()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: projectCredits.projectTitle,
        theme: buildAppTheme(),
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const SplashScreen(),
      ),
    );
  }
}
