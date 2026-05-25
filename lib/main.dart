import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/login_screen.dart';
import 'screens/queue_screen.dart';
import 'screens/live_match_screen.dart';
import 'screens/pre_match_screen.dart';
import 'screens/end_match_screen.dart';
import 'screens/offline_screen.dart';
import 'services/api.dart';
import 'theme/colors.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: C8P.ink,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: C8P.ink2,
  ));
  runApp(const Club8PoolApp());
}

class Club8PoolApp extends StatelessWidget {
  const Club8PoolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Club 8 Pool · Arbitre',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: C8P.ink,
        colorScheme: ColorScheme.fromSeed(seedColor: C8P.felt2, brightness: Brightness.dark),
      ),
      home: const _Splash(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/queue': (_) => const QueueScreen(),
        '/offline': (_) => const OfflineScreen(),
      },
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/pre':
            return MaterialPageRoute(builder: (_) => PreMatchScreen(match: settings.arguments as Map));
          case '/live':
            return MaterialPageRoute(builder: (_) => LiveMatchScreen(match: settings.arguments as Map));
          case '/end':
            return MaterialPageRoute(builder: (_) => EndMatchScreen(match: settings.arguments as Map));
        }
        return null;
      },
    );
  }
}

class _Splash extends StatefulWidget {
  const _Splash();
  @override
  State<_Splash> createState() => _SplashState();
}

class _SplashState extends State<_Splash> {
  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    final api = await ApiService.create();
    final ok = await api.isAuthenticated();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(ok ? '/queue' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: C8P.ink,
      body: Center(child: CircularProgressIndicator(color: C8P.felt2)),
    );
  }
}
