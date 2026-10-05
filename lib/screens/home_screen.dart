import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../state/library_provider.dart';
import '../models/publisher.dart';
import '../widgets/entity_toolbar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LibraryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Библиотека (ПР4: REST API + Dio)'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.bug_report),
            tooltip: 'Тестирование состояний сети',
            onSelected: (val) {
              if (val == 'delay') provider.fetchBooks(simulateDelay: 1500);
              if (val == 'fail500') provider.fetchBooks(simulateFail: 500);
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'delay', child: Text('Задержка 1.5с (?__delay=1500)')),
              PopupMenuItem(value: 'fail500', child: Text('Сбой сервера 500 (?__fail=500)')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => provider.fetchBooks(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/books/new'),
        icon: const Icon(Icons.add),
        label: const Text('Добавить книгу'),
      ),
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
          Expanded(child: _buildBody(context, provider)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, LibraryProvider provider) {
    return switch (provider.bookStatus) {
      PageStatus.loading => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Загрузка данных с сервера...'),
          ],
        ),
      ),
      PageStatus.empty => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('Книги не найдены', style: TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: () => provider.fetchBooks(), child: const Text('Обновить')),
          ],
        ),
      ),
      PageStatus.error => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 12),
              Text(provider.bookError, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => provider.fetchBooks(),
                icon: const Icon(Icons.refresh),
                label: const Text('Повторить попытку'),
              ),
            ],
          ),
        ),
      ),
      PageStatus.success => ListView.builder(
        itemCount: provider.books.length,
        itemBuilder: (ctx, i) {
          final b = provider.books[i];
          final pub = provider.publishers.cast<Publisher?>().firstWhere((p) => p?.id == b.publisherId, orElse: () => null);
          return ListTile(
            title: Text(b.title, style: TextStyle(decoration: b.isDeleted ? TextDecoration.lineThrough : null)),
            subtitle: Text('ISBN: ${b.isbn} | Изд-во: ${pub?.name ?? "ID: ${b.publisherId}"} | Экз: ${b.copiesAvailable}/${b.copiesTotal}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!b.isDeleted)
                  IconButton(icon: const Icon(Icons.edit), onPressed: () => context.go('/books/${b.id}/edit')),
                if (!b.isDeleted)
                  IconButton(icon: const Icon(Icons.delete_outline, color: Colors.orange), onPressed: () => provider.softDeleteBook(b.id)),
                if (b.isDeleted)
                  IconButton(icon: const Icon(Icons.restore, color: Colors.green), onPressed: () => provider.restoreBook(b.id)),
                if (b.isDeleted)
                  IconButton(icon: const Icon(Icons.delete_forever, color: Colors.red), onPressed: () => provider.hardDeleteBook(b.id)),
              ],
            ),
          );
        },
      ),
    };
  }
}
