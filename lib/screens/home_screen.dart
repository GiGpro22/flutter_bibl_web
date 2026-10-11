import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/breakpoints.dart';
import '../core/permissions.dart';
import '../models/app_user.dart';
import '../models/book.dart';
import '../models/publisher.dart';
import '../state/auth_notifier.dart';
import '../state/library_provider.dart';
import '../widgets/entity_toolbar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final provider = context.watch<LibraryProvider>();
    final user = auth.user;
    final screenSize = screenSizeOf(context);

    // Определение уникального экрана для роли
    final roleScreen = switch (user?.role) {
      Role.reader => (
          route: '/my-loans',
          label: 'Мои книги',
          icon: Icons.bookmark
        ),
      Role.librarian => (
          route: '/manage-loans',
          label: 'Журнал',
          icon: Icons.assignment
        ),
      Role.admin => (
          route: '/admin/users',
          label: 'Пользователи',
          icon: Icons.manage_accounts
        ),
      _ => null,
    };

    final fab = canManageBooks(user)
        ? FloatingActionButton.extended(
            onPressed: () => context.go('/books/new'),
            icon: const Icon(Icons.add),
            label: const Text('Добавить книгу'),
            tooltip: 'Добавить новое издание в фонд',
          )
        : null;

    final appBarActions = [
      PopupMenuButton<String>(
        icon: const Icon(Icons.security),
        tooltip: 'Эксперимент №17 (Проверка клиентской защиты)',
        onSelected: (val) {
          if (val == 'tamper_admin') {
            auth.tamperRoleForExperiment(Role.admin);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Внимание: клиентская роль подменена на Администратора! Кнопки появились.'),
              ),
            );
          }
        },
        itemBuilder: (ctx) => const [
          PopupMenuItem(
            value: 'tamper_admin',
            child: Text('Подменить роль на Admin (Эксперимент №17)'),
          ),
        ],
      ),
      IconButton(
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        icon: const Icon(Icons.logout),
        tooltip: 'Выход',
        onPressed: () => auth.logout(),
      ),
    ];

    // Основное содержимое с ограничением ширины на 1920 px
    final content = Center(
      child: ConstrainedBox(
        constraints:
            const BoxConstraints(maxWidth: Breakpoints.contentMaxWidth),
        child: Column(
          children: [
            EntityToolbar(
              searchHint: 'Поиск книги на сервере...',
              onSearch: (q) => provider.onSearchChanged(q),
              showDeleted: provider.bookShowDeleted,
              onToggleDeleted: (val) => provider.onToggleDeleted(val),
              sortOrder: provider.bookSort.contains('asc') ? 'asc' : 'desc',
              onSortChanged: (s) => provider
                  .onSortChanged(s == 'asc' ? 'title,asc' : 'title,desc'),
              page: provider.bookPage,
              totalPages: provider.bookTotalPages,
              onPrevPage: () => provider.setPage(provider.bookPage - 1),
              onNextPage: () => provider.setPage(provider.bookPage + 1),
            ),
            Expanded(child: _buildBody(context, provider, user, screenSize)),
          ],
        ),
      ),
    );

    // 1. Узкое окно (360): навигация снизу
    if (screenSize == ScreenSize.compact) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Библиотека (${user?.role.label ?? ""})',
            overflow: TextOverflow.ellipsis,
          ),
          actions: appBarActions,
        ),
        floatingActionButton: fab,
        body: content,
        bottomNavigationBar: roleScreen != null
            ? NavigationBar(
                selectedIndex: 0,
                onDestinationSelected: (idx) {
                  if (idx == 1) context.go(roleScreen.route);
                },
                destinations: [
                  const NavigationDestination(
                      icon: Icon(Icons.menu_book), label: 'Каталог'),
                  NavigationDestination(
                      icon: Icon(roleScreen.icon), label: roleScreen.label),
                ],
              )
            : null,
      );
    }

    // 2. Широкие экраны (768, 1280, 1920): NavigationRail слева
    final isRailExtended = screenSize == ScreenSize.expanded ||
        screenSize == ScreenSize.extraLarge;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Библиотека | ${user?.name ?? ""} (${user?.role.label ?? ""})',
          overflow: TextOverflow.ellipsis,
        ),
        actions: appBarActions,
      ),
      floatingActionButton: fab,
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: 0,
            onDestinationSelected: (idx) {
              if (idx == 1 && roleScreen != null) context.go(roleScreen.route);
            },
            extended: isRailExtended,
            labelType: isRailExtended
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.all,
            destinations: [
              const NavigationRailDestination(
                icon: Icon(Icons.menu_book),
                label: Text('Каталог'),
              ),
              if (roleScreen != null)
                NavigationRailDestination(
                  icon: Icon(roleScreen.icon),
                  label: Text(roleScreen.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: content),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, LibraryProvider provider,
      AppUser? user, ScreenSize screenSize) {
    if (provider.bookStatus == PageStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.bookStatus == PageStatus.error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(provider.bookError, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => provider.fetchBooks(),
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }
    if (provider.books.isEmpty) {
      return const Center(
        child: Text('Книг не найдено',
            style: TextStyle(fontSize: 16, color: Colors.grey)),
      );
    }

    // 1280 и 1920: Таблица DataTable с двумерным скроллом
    if (screenSize == ScreenSize.expanded ||
        screenSize == ScreenSize.extraLarge) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Название')),
                    DataColumn(label: Text('ISBN')),
                    DataColumn(label: Text('Издательство')),
                    DataColumn(label: Text('Статус')),
                    DataColumn(label: Text('Действия')),
                  ],
                  rows: provider.books.map((b) {
                    final pub = provider.publishers
                        .cast<Publisher?>()
                        .firstWhere((p) => p?.id == b.publisherId,
                            orElse: () => null);
                    return DataRow(
                      cells: [
                        DataCell(
                          InkWell(
                            onTap: () => context.go('/books/${b.id}'),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 320),
                              child: Text(
                                b.title,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  decoration: b.isDeleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: b.isDeleted ? Colors.grey : null,
                                ),
                              ),
                            ),
                          ),
                        ),
                        DataCell(Text(b.isbn)),
                        DataCell(Text(pub?.name ?? "ID: ${b.publisherId}")),
                        DataCell(
                          b.isDeleted
                              ? const Chip(
                                  visualDensity: VisualDensity.compact,
                                  label: Text('В корзине',
                                      style: TextStyle(
                                          color: Colors.red, fontSize: 11)),
                                  backgroundColor: Color(0xFFFFEBEE),
                                )
                              : const Chip(
                                  visualDensity: VisualDensity.compact,
                                  label: Text('Активна',
                                      style: TextStyle(
                                          color: Colors.green, fontSize: 11)),
                                  backgroundColor: Color(0xFFE8F5E9),
                                ),
                        ),
                        DataCell(_buildActions(context, b, user, provider)),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          );
        },
      );
    }

    // 768: Сетка карточек в 2 колонки
    if (screenSize == ScreenSize.medium) {
      return GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisExtent: 150,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: provider.books.length,
        itemBuilder: (ctx, i) {
          final b = provider.books[i];
          final pub = provider.publishers
              .cast<Publisher?>()
              .firstWhere((p) => p?.id == b.publisherId, orElse: () => null);
          return _buildBookCard(context, b, pub, user, provider);
        },
      );
    }

    // 360 (Compact): Список карточек в 1 колонку
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      itemCount: provider.books.length,
      itemBuilder: (ctx, i) {
        final b = provider.books[i];
        final pub = provider.publishers
            .cast<Publisher?>()
            .firstWhere((p) => p?.id == b.publisherId, orElse: () => null);
        return _buildBookCard(context, b, pub, user, provider);
      },
    );
  }

  Widget _buildBookCard(BuildContext context, Book b, Publisher? pub,
      AppUser? user, LibraryProvider provider) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.menu_book, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () => context.go('/books/${b.id}'),
                        child: Text(
                          b.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            decoration:
                                b.isDeleted ? TextDecoration.lineThrough : null,
                            color: b.isDeleted ? Colors.grey : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ISBN: ${b.isbn}',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade700),
                      ),
                      Text(
                        'Изд-во: ${pub?.name ?? "ID: ${b.publisherId}"}',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                if (b.isDeleted)
                  const Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text('В корзине',
                        style: TextStyle(color: Colors.red, fontSize: 11)),
                    backgroundColor: Color(0xFFFFEBEE),
                  )
                else
                  const Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text('Активна',
                        style: TextStyle(color: Colors.green, fontSize: 11)),
                    backgroundColor: Color(0xFFE8F5E9),
                  ),
                const Spacer(),
                _buildActions(context, b, user, provider),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(
      BuildContext context, Book b, AppUser? user, LibraryProvider provider) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!b.isDeleted && canManageBooks(user))
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.edit, size: 20),
            tooltip: 'Редактировать',
            onPressed: () => context.go('/books/${b.id}/edit'),
          ),
        if (!b.isDeleted && canManageBooks(user))
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.delete_outline,
                size: 20, color: Colors.orange),
            tooltip: 'В корзину',
            onPressed: () async {
              try {
                await provider.softDeleteBook(b.id);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        backgroundColor: Colors.red.shade800,
                        content: Text('$e')),
                  );
                }
              }
            },
          ),
        if (b.isDeleted && canRestore(user))
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.restore, size: 20, color: Colors.green),
            tooltip: 'Восстановить',
            onPressed: () => provider.restoreBook(b.id),
          ),
        if (b.isDeleted && canHardDelete(user))
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.delete_forever, size: 20, color: Colors.red),
            tooltip: 'Удалить навсегда (только серверный Admin)',
            onPressed: () async {
              try {
                await provider.hardDeleteBook(b.id);
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      backgroundColor: Colors.red.shade800,
                      content: Text('$e')),
                );
              }
            },
          ),
      ],
    );
  }
}
