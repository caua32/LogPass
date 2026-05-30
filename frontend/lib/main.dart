import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authProvider = AuthProvider();
  await authProvider.loadSession();
  final router = buildRouter(authProvider);

  runApp(
    ChangeNotifierProvider.value(
      value: authProvider,
      child: LogPassApp(router: router),
    ),
  );
}

class _SmoothPageTransition extends PageTransitionsBuilder {
  const _SmoothPageTransition();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

class LogPassApp extends StatelessWidget {
  final dynamic router;
  const LogPassApp({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'LogPass',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF0A1929),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF44CABD),
          surface: Color(0xFF102A43),
        ),
        useMaterial3: false,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: _SmoothPageTransition(),
            TargetPlatform.iOS: _SmoothPageTransition(),
            TargetPlatform.fuchsia: _SmoothPageTransition(),
          },
        ),
      ),
      routerConfig: router,
    );
  }
}
