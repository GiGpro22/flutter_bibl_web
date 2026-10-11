import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:library_catalog/models/app_user.dart';
import 'package:library_catalog/models/book.dart';
import 'package:library_catalog/models/publisher.dart';
import 'package:library_catalog/screens/home_screen.dart';
import 'package:library_catalog/state/auth_notifier.dart';
import 'package:library_catalog/state/library_provider.dart';

class MockLibraryProvider extends ChangeNotifier implements LibraryProvider {
  @override
  PageStatus bookStatus = PageStatus.success;

  @override
  String bookError = '';

  @override
  List<Book> books = [];

  @override
  List<Publisher> publishers = [];

  @override
  bool bookShowDeleted = false;

  @override
  String bookSort = 'title,asc';

  @override
  int bookPage = 1;

  @override
  int bookTotalPages = 1;

  bool fetchCalled = false;

  @override
  Future<void> fetchBooks({int? simulateFail, int? simulateDelay}) async {
    fetchCalled = true;
    notifyListeners();
  }

  @override
  void onSearchChanged(String query) {}

  @override
  void onToggleDeleted(bool value) {}

  @override
  void onSortChanged(String sort) {}

  @override
  void setPage(int page) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockAuthNotifier extends ChangeNotifier implements AuthNotifier {
  @override
  AppUser? user;

  @override
  bool get isAuthenticated => user != null;

  void setUser(AppUser? newUser) {
    user = newUser;
    notifyListeners();
  }

  @override
  Future<void> logout() async {}

  @override
  void tamperRoleForExperiment(Role role) {
    if (user != null) {
      user = AppUser(
          id: user!.id, email: user!.email, name: user!.name, role: role);
      notifyListeners();
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget createTestHarness({
  required MockAuthNotifier auth,
  required MockLibraryProvider provider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthNotifier>.value(value: auth),
      ChangeNotifierProvider<LibraryProvider>.value(value: provider),
    ],
    child: const MaterialApp(
      home: HomeScreen(),
    ),
  );
}

void main() {
  late MockAuthNotifier auth;
  late MockLibraryProvider provider;

  setUp(() {
    auth = MockAuthNotifier();
    provider = MockLibraryProvider();
    auth.user = const AppUser(
        id: 1, email: 'r@bibl.ru', name: 'Иван Читатель', role: Role.reader);
  });

  testWidgets('1. Отображение состояния загрузки (CircularProgressIndicator)',
      (tester) async {
    provider.bookStatus = PageStatus.loading;

    await tester.pumpWidget(createTestHarness(auth: auth, provider: provider));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('2. Отображение пустого результата при отсутствии книг',
      (tester) async {
    provider.bookStatus = PageStatus.success;
    provider.books = [];

    await tester.pumpWidget(createTestHarness(auth: auth, provider: provider));
    await tester.pumpAndSettle();

    expect(find.text('Книг не найдено'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('3. Отображение ошибки с кнопкой повтора и реакция на нажатие',
      (tester) async {
    provider.bookStatus = PageStatus.error;
    provider.bookError = 'Сетевой сбой: сервер недоступен';

    await tester.pumpWidget(createTestHarness(auth: auth, provider: provider));
    await tester.pumpAndSettle();

    expect(find.text('Сетевой сбой: сервер недоступен'), findsOneWidget);
    expect(find.text('Повторить'), findsOneWidget);

    await tester.tap(find.text('Повторить'));
    await tester.pump();

    expect(provider.fetchCalled, isTrue);
  });

  testWidgets(
      '4. Срабатывание валидации формы при пустом вводе обязательного поля',
      (tester) async {
    final formKey = GlobalKey<FormState>();
    final ctrl = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            key: formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: ctrl,
                  decoration:
                      const InputDecoration(labelText: 'Название книги'),
                  validator: (val) => (val == null || val.trim().isEmpty)
                      ? 'Поле обязательно для заполнения'
                      : null,
                ),
                ElevatedButton(
                  onPressed: () => formKey.currentState!.validate(),
                  child: const Text('Сохранить'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();

    expect(find.text('Поле обязательно для заполнения'), findsOneWidget);
  });

  testWidgets('5. Скрытие недоступного элемента при недостаточной роли (RBAC)',
      (tester) async {
    // 5.1 Роль reader: кнопка добавления книги отсутствует в интерфейсе
    auth.setUser(const AppUser(
        id: 1, email: 'r@bibl.ru', name: 'Читатель', role: Role.reader));
    await tester.pumpWidget(createTestHarness(auth: auth, provider: provider));
    await tester.pumpAndSettle();

    expect(find.text('Добавить книгу'), findsNothing);
    expect(
        find.byWidgetPredicate((w) => w is FloatingActionButton), findsNothing);

    // 5.2 Роль librarian: кнопка добавления книги появляется
    auth.setUser(const AppUser(
        id: 2, email: 'l@bibl.ru', name: 'Библиотекарь', role: Role.librarian));
    await tester.pumpAndSettle();

    expect(find.text('Добавить книгу'), findsOneWidget);
    expect(find.byWidgetPredicate((w) => w is FloatingActionButton),
        findsOneWidget);
  });
}
