import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/permissions.dart';
import '../models/app_user.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: Text('Библиотека | ${user?.name ?? ""} (${user?.role.label ?? ""})'),
        actions: [
          // Эксклюзивные кнопки в шапке в зависимости от роли
                    if (canManageLoans(user))
            FilledButton.tonalIcon(
              icon: const Icon(Icons.assignment),
              label: const Text('Журнал выдач'),
              onPressed: () => context.go('/manage-loans'),
            ),
          if (canManageUsers(user))
            FilledButton.tonalIcon(
              icon: const Icon(Icons.manage_accounts),
              label: const Text('Пользователи'),
              onPressed: () => context.go('/admin/users'),
            ),
          if (canViewMyLoans(user))
            FilledButton.tonalIcon(
              icon: const Icon(Icons.bookmark),
              label: const Text('Мои книги'),
              onPressed: () => context.go('/my-loans'),
            ),

          // Меню Эксперимента №17 (проверка клиентской защиты)
          PopupMenuButton<String>(
            icon: const Icon(Icons.security),
            tooltip: 'Эксперимент №17 (Проверка клиентской защиты)',
            onSelected: (val) {
              if (val == 'tamper_admin') {
                auth.tamperRoleForExperiment(Role.admin);
                if (!context.mounted) return; ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Внимание: клиентская роль подменена на Администратора! Кнопки появились.')),
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
            icon: const Icon(Icons.logout),
            tooltip: 'Выход',
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      floatingActionButton: canManageBooks(user)
          ? FloatingActionButton.extended(
              onPressed: () => context.go('/books/new'),
              icon: const Icon(Icons.add),
              label: const Text('Добавить книгу'),
            )
          : null,
      body: Column(
        children: [
          EntityToolbar(
            searchHint: 'Поиск книги на сервере...',
            onSearch: (q) => provider.onSearchChanged(q),
            showDeleted: provider.bookShowDeleted,
            onToggleDeleted: (val) => provider.onToggleDeleted(val),
            sortOrder: provider.bookSort.contains('asc') ? 'asc' : 'desc',
            onSortChanged: (s) => provider.onSortChanged(s == 'asc' ? 'title,asc' : 'title,desc'),
            page: provider.bookPage,
            totalPages: provider.bookTotalPages,
            onPrevPage: () => provider.setPage(provider.bookPage - 1),
            onNextPage: () => provider.setPage(provider.bookPage + 1),
          ),
          Expanded(child: _buildBody(context, provider, user)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, LibraryProvider provider, AppUser? user) {
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
            FilledButton(onPressed: () => provider.fetchBooks(), child: const Text('Повторить')),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: provider.books.length,
      itemBuilder: (ctx, i) {
        final b = provider.books[i];
        final pub = provider.publishers.cast<Publisher?>().firstWhere((p) => p?.id == b.publisherId, orElse: () => null);
        return ListTile(
          title: Text(b.title, style: TextStyle(decoration: b.isDeleted ? TextDecoration.lineThrough : null)),
          subtitle: Text('ISBN: ${b.isbn} | Изд-во: ${pub?.name ?? "ID: ${b.publisherId}"}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!b.isDeleted && canManageBooks(user))
                IconButton(icon: const Icon(Icons.edit), onPressed: () => context.go('/books/${b.id}/edit')),
              if (!b.isDeleted && canManageBooks(user))
                IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.orange),
                onPressed: () async {
                  try {
                    await provider.softDeleteBook(b.id);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(backgroundColor: Colors.red.shade800, content: Text('$e')),
                      );
                    }
                  }
                },
              ),
              if (b.isDeleted && canRestore(user))
                IconButton(icon: const Icon(Icons.restore, color: Colors.green), onPressed: () => provider.restoreBook(b.id)),
              // Кнопка физического удаления: доступна админу (или при подмене роли в эксперименте №17)
              if (b.isDeleted && canHardDelete(user))
                IconButton(
                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                  tooltip: 'Удалить навсегда (только серверный Admin)',
                  onPressed: () async {
                    try {
                      await provider.hardDeleteBook(b.id);
                    } catch (e) {
                      if (!context.mounted) return; ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(backgroundColor: Colors.red.shade800, content: Text('$e')),
                      );
                    }
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}



