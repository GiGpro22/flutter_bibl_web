import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';

import 'core/scroll_behavior.dart';
import 'repositories/author_repository.dart';
import 'repositories/book_repository.dart';
import 'repositories/in_memory_author_repository.dart';
import 'repositories/in_memory_book_repository.dart';
import 'router.dart';
import 'state/author_list_notifier.dart';
import 'state/book_list_notifier.dart';

void main() {
  usePathUrlStrategy();
  runApp(const LibraryApp());
}

class LibraryApp extends StatelessWidget {
  const LibraryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<BookRepository>(create: (_) => InMemoryBookRepository()),
        Provider<AuthorRepository>(create: (_) => InMemoryAuthorRepository()),
        ChangeNotifierProvider<BookListNotifier>(
          create: (context) => BookListNotifier(context.read<BookRepository>())..load(),
        ),
        ChangeNotifierProvider<AuthorListNotifier>(
          create: (context) => AuthorListNotifier(context.read<AuthorRepository>())..load(),
        ),
      ],
      child: MaterialApp.router(
        title: 'Библиотечный каталог',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.indigo,
        ),
        locale: const Locale('ru'),
        supportedLocales: const [Locale('ru')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        scrollBehavior: AppScrollBehavior(),
        routerConfig: appRouter,
      ),
    );
  }
}
