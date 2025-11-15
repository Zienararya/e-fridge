import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:efridge/view/mainPage.dart';
import 'database.dart';
import 'services/auth_service.dart';
import 'view/login_page.dart';
import 'services/push_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inisialisasi Supabase
  await SupabaseService.init();

  // 2. Cek status login
  final loggedIn = await AuthService.isLoggedIn();

  // 3. Jika user sudah login, aktifkan FCM (token registration + handlers)
  if (loggedIn) {
    await PushService.initAndRegister();
  }
  //    Kita tidak lagi memakai realtime/local fetch agar tidak double notif.

  // 6. Jalankan aplikasi
  runApp(MyApp(initialRoute: loggedIn ? '/' : '/login'));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.initialRoute = '/'});
  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return AdaptiveTheme(
      light: ThemeData.light(useMaterial3: true),
      dark: ThemeData.dark(useMaterial3: true),
      initial: AdaptiveThemeMode.system,
      builder: (theme, darkTheme) => MaterialApp(
        theme: theme,
        darkTheme: darkTheme,
        debugShowCheckedModeBanner: false,
        initialRoute: initialRoute,
        routes: {
          '/': (_) => const Mainpage(),
          '/login': (_) => const LoginPage(),
        },
      ),
    );
  }
}
