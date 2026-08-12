import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'game.dart';
import 'login_page.dart';
import 'dashboard_page.dart';
import 'home_page.dart';
import 'seller_page.dart';
import 'admin_page.dart';
import 'owner_page.dart';
import 'landing.dart';
import 'theme_provider.dart';
import 'notifications_control.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp();
  
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Helper function untuk memisahkan number bugs dan group bugs
  List<Map<String, dynamic>> _getNumberBugs(List<Map<String, dynamic>> listBug) {
    return listBug.where((b) {
      final type = (b['type'] ?? b['bug_type'] ?? b['category'] ?? '').toString().toLowerCase();
      return !type.contains('group');
    }).toList();
  }

  List<Map<String, dynamic>> _getGroupBugs(List<Map<String, dynamic>> listBug) {
    return listBug.where((b) {
      final type = (b['type'] ?? b['bug_type'] ?? b['category'] ?? '').toString().toLowerCase();
      return type.contains('group');
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SXC EXEC V13 GEN 3',
        theme: ThemeData(
          brightness: themeProvider.isDarkMode
              ? Brightness.dark
              : Brightness.light,
          fontFamily: 'ShareTechMono',
          scaffoldBackgroundColor: themeProvider.backgroundColor,
          colorScheme: ColorScheme.fromSeed(
            seedColor: themeProvider.primaryColor,
            brightness: themeProvider.isDarkMode
                ? Brightness.dark
                : Brightness.light,
          ).copyWith(
            primary: themeProvider.primaryColor,
            secondary: themeProvider.accentColor,
          ),
        ),
        initialRoute: '/',
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/':
              return MaterialPageRoute(builder: (_) => LandingPage());

            case '/login':
              return MaterialPageRoute(builder: (_) => const LoginPage());

            case '/dashboard':
              final args = settings.arguments as Map<String, dynamic>;
              final listBug = List<Map<String, dynamic>>.from(args['listBug'] ?? []);
              return MaterialPageRoute(
                builder: (_) => DashboardPage(
                  username: args['username'] ?? '',
                  password: args['password'] ?? '',
                  role: args['role'] ?? 'user',
                  sessionKey: args['key'] ?? '',
                  expiredDate: args['expiredDate'] ?? '',
                  listBug: listBug,
                  news: List<Map<String, dynamic>>.from(args['news'] ?? []),
                ),
              );

            case '/home':
              final args = settings.arguments as Map<String, dynamic>;
              final listBug = List<Map<String, dynamic>>.from(args['listBug'] ?? []);
              final numberBugs = _getNumberBugs(listBug);
              final groupBugs = _getGroupBugs(listBug);
              
              return MaterialPageRoute(
                builder: (_) => HomePage(
                  username: args['username'] ?? '',
                  password: args['password'] ?? '',
                  listBug: listBug,
                  role: args['role'] ?? 'user',
                  expiredDate: args['expiredDate'] ?? '',
                  sessionKey: args['sessionKey'] ?? '',
                  // ===== HAPUS numberBugs DAN groupBugs =====
                ),
              );

            case '/seller':
              final args = settings.arguments as Map<String, dynamic>;
              return MaterialPageRoute(
                builder: (_) => SellerPage(
                  keyToken: args['keyToken'] ?? '',
                ),
              );

            case '/admin':
              final args = settings.arguments as Map<String, dynamic>;
              return MaterialPageRoute(
                builder: (_) => AdminPage(
                  sessionKey: args['sessionKey'] ?? '',
                ),
              );
              
            case '/game':
              return MaterialPageRoute(builder: (_) => const GameHubPage());

            case '/owner':
              final args = settings.arguments as Map<String, dynamic>;
              return MaterialPageRoute(
                builder: (_) => OwnerPage(
                  sessionKey: args['sessionKey'] ?? '',
                  username: args['username'] ?? '',
                  currentUserRole: args['currentUserRole'] ?? args['role'] ?? 'user',
                ),
              );

            default:
              return MaterialPageRoute(
                builder: (_) => const Scaffold(
                  body: Center(
                    child: Text('404 - Not Found'),
                  ),
                ),
              );
          }
        },
      ),
    );
  }
}