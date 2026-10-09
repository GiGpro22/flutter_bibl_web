import 'package:go_router/go_router.dart';
import 'core/permissions.dart';
import 'screens/admin_users_screen.dart';
import 'screens/book_details_screen.dart';
import 'screens/book_form_screen.dart';
import 'screens/forbidden_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/manage_loans_screen.dart';
import 'screens/my_loans_screen.dart';
import 'screens/register_screen.dart';
import 'state/auth_notifier.dart';
import 'widgets/inactivity_watcher.dart';

GoRouter createRouter(AuthNotifier auth) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    refreshListenable: auth,
    initialLocation: '/',
    redirect: (context, state) {
      if (!auth.isKnown) return null;

      final loggedIn = auth.isAuthenticated;
      final target = state.matchedLocation;
      final isPublic = target == '/login' || target == '/register';

      if (!loggedIn && !isPublic) {
        return '/login?from=${Uri.encodeComponent(state.uri.toString())}';
      }
      if (loggedIn && isPublic) return '/';

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (c, s) => const HomeScreen(),
        routes: [
          GoRoute(
            path: 'books/new',
            builder: (c, s) => const BookFormScreen(),
            redirect: (context, state) => canManageBooks(auth.user) ? null : '/forbidden',
          ),
          GoRoute(
            path: 'books/:id',
            builder: (c, s) => BookDetailsScreen(id: int.tryParse(s.pathParameters['id'] ?? '') ?? 0),
          ),
          GoRoute(
            path: 'books/:id/edit',
            builder: (c, s) => BookFormScreen(id: int.tryParse(s.pathParameters['id'] ?? '')),
            redirect: (context, state) => canManageBooks(auth.user) ? null : '/forbidden',
          ),
        ],
      ),
      GoRoute(
        path: '/login',
        builder: (c, s) => LoginScreen(from: s.uri.queryParameters['from']),
      ),
      GoRoute(
        path: '/register',
        builder: (c, s) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/my-loans',
        builder: (c, s) => const MyLoansScreen(),
        redirect: (context, state) => canViewMyLoans(auth.user) ? null : '/forbidden',
      ),
      GoRoute(
        path: '/manage-loans',
        builder: (c, s) => const ManageLoansScreen(),
        redirect: (context, state) => canManageLoans(auth.user) ? null : '/forbidden',
      ),
      GoRoute(
        path: '/admin/users',
        builder: (c, s) => const AdminUsersScreen(),
        redirect: (context, state) => canManageUsers(auth.user) ? null : '/forbidden',
      ),
      GoRoute(
        path: '/forbidden',
        builder: (c, s) => const ForbiddenScreen(),
      ),
    ],
  );
}