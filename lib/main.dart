import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';

import 'route.dart';
//import 'notification_service.dart';
import 'widgets/user_session.dart';

void main() async {
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();

  //await NotificationService.init();

  final userSession = UserSession();
  await userSession.loadSession(); // 👈 Load phiên đăng nhập trước đó

  runApp(
    ChangeNotifierProvider.value(
      value: userSession,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'KoHo',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7fff00)),
        scaffoldBackgroundColor: Colors.black,
        useMaterial3: true,
      ),
      routerConfig: route.getGoRouter(), // 👈 Lấy GoRouter đã config
    );
  }
}
