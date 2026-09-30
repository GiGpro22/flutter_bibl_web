import 'package:go_router/go_router.dart';
import 'screens/authors_screen.dart';
import 'screens/author_detail_screen.dart';
import 'screens/books_screen.dart';
import 'screens/book_detail_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/books',
  routes: [
    GoRoute(
      path: '/books',
      builder: (context, state) => const BooksScreen(),
      routes: [
        GoRoute(
          path: ':id',
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
            return BookDetailScreen(bookId: id);
          },
        ),
      ],
    ),
    GoRoute(
      path: '/authors',
      builder: (context, state) => const AuthorsScreen(),
      routes: [
        GoRoute(
          path: ':id',
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
            return AuthorDetailScreen(authorId: id);
          },
        ),
      ],
    ),
  ],
);
