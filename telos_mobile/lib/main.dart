import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/storage/storage_service.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/task_provider.dart';
import 'core/providers/track_provider.dart';
import 'core/providers/message_provider.dart';
import 'core/providers/analytics_provider.dart';
import 'core/providers/ai_provider.dart';
import 'core/providers/rewards_provider.dart';
import 'features/auth/screens/welcome_screen.dart';
import 'features/navigation/main_scaffold.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => TrackProvider()),
        ChangeNotifierProvider(create: (_) => MessageProvider()),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
        ChangeNotifierProvider(create: (_) => AIProvider()),
        ChangeNotifierProvider(create: (_) => RewardsProvider()),
      ],
      child: const TelosApp(),
    ),
  );
}

class TelosApp extends StatefulWidget {
  const TelosApp({super.key});

  @override
  State<TelosApp> createState() => _TelosAppState();
}

class _TelosAppState extends State<TelosApp> {
  bool _isCheckingAuth = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkInitialAuth();
  }

  Future<void> _checkInitialAuth() async {
    final authProvider = context.read<AuthProvider>();
    final loggedIn = await authProvider.tryAutoLogin();
    if (mounted) {
      setState(() {
        _isAuthenticated = loggedIn;
        _isCheckingAuth = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'TELOS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home: _isCheckingAuth
          ? const Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.radar_rounded, size: 56, color: AppColors.primary),
                    SizedBox(height: 16),
                    Text(
                      'TELOS',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2),
                    ),
                    SizedBox(height: 16),
                    CircularProgressIndicator(),
                  ],
                ),
              ),
            )
          : _isAuthenticated
              ? const MainScaffold()
              : const WelcomeScreen(),
    );
  }
}
