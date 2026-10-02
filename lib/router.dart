import 'package:go_router/go_router.dart';
import 'screens/home_screen.dart';
import 'screens/book_form_screen.dart';
import 'screens/author_form_screen.dart';
import 'screens/genre_form_screen.dart';
import 'screens/publisher_form_screen.dart';
import 'screens/reader_form_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
      routes: [
        // Маршруты Книг (new ОБЯЗАТЕЛЬНО перед :id)
        GoRoute(path: 'books/new', builder: (context, state) => const BookFormScreen()),
        GoRoute(
          path: 'books/:id/edit',
          builder: (context, state) => BookFormScreen(id: int.tryParse(state.pathParameters['id'] ?? '')),
        ),
        // Маршруты Авторов
        GoRoute(path: 'authors/new', builder: (context, state) => const AuthorFormScreen()),
        GoRoute(
          path: 'authors/:id/edit',
          builder: (context, state) => AuthorFormScreen(id: int.tryParse(state.pathParameters['id'] ?? '')),
        ),
        // Маршруты Жанров
        GoRoute(path: 'genres/new', builder: (context, state) => const GenreFormScreen()),
        GoRoute(
          path: 'genres/:id/edit',
          builder: (context, state) => GenreFormScreen(id: int.tryParse(state.pathParameters['id'] ?? '')),
        ),
        // Маршруты Издательств
        GoRoute(path: 'publishers/new', builder: (context, state) => const PublisherFormScreen()),
        GoRoute(
          path: 'publishers/:id/edit',
          builder: (context, state) => PublisherFormScreen(id: int.tryParse(state.pathParameters['id'] ?? '')),
        ),
        // Маршруты Читателей
        GoRoute(path: 'readers/new', builder: (context, state) => const ReaderFormScreen()),
        GoRoute(
          path: 'readers/:id/edit',
          builder: (context, state) => ReaderFormScreen(id: int.tryParse(state.pathParameters['id'] ?? '')),
        ),
      ],
    ),
  ],
);