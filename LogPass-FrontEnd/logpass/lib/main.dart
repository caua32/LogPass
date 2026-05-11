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
          primary: Color(0xFF4CE0D2),
          surface: Color(0xFF102A43),
        ),
        useMaterial3: false,
      ),
      routerConfig: router,
    );
  }
}
