import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_theme.dart';
import 'home_page.dart';
import 'images.dart';
import 'lock_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ImageStore.init();
  runApp(const KasebbashiApp());
}

class KasebbashiApp extends StatelessWidget {
  const KasebbashiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'کاسب‌باشی',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      builder: (context, child) =>
          AppLockGate(child: child ?? const SizedBox.shrink()),
      locale: const Locale('fa'),
      supportedLocales: const [Locale('fa')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }
}
