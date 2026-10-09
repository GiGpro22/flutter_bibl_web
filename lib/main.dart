import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/api_client.dart';
import 'router.dart';
import 'state/auth_notifier.dart';
import 'state/library_provider.dart';
import 'widgets/inactivity_watcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  final prefs = await SharedPreferences.getInstance();
  late final AuthNotifier authNotifier;

  final dio = buildDio(
    onSessionExpired: () async {
      await authNotifier.logout();
    },
  );

  authNotifier = AuthNotifier(prefs, dio);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authNotifier),
        ChangeNotifierProvider(create: (_) => LibraryProvider(dio)),
      ],
      child: const WebBiblApp(),
    ),
  );
}

class WebBiblApp extends StatefulWidget {
  const WebBiblApp({super.key});

  @override
  State<WebBiblApp> createState() => _WebBiblAppState();
}

class _WebBiblAppState extends State<WebBiblApp> {
  late final _router = createRouter(context.read<AuthNotifier>());

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();

    return InactivityWatcher(
      timeout: const Duration(minutes: 3),
      warningBefore: const Duration(seconds: 30),
      onTimeout: () {
        if (auth.isAuthenticated) {
          auth.logout();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Сессия завершена из-за отсутствия активности (3 мин)')),
          );
        }
      },
      child: MaterialApp.router(
        title: 'Библиотека (ПР5: Аутентификация)',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        routerConfig: _router,
      ),
    );
  }
}