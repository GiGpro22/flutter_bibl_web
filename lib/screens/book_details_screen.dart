import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/permissions.dart';
import '../models/book.dart';
import '../models/publisher.dart';
import '../state/auth_notifier.dart';
import '../state/library_provider.dart';

class BookDetailsScreen extends StatelessWidget {
  final int id;
  const BookDetailsScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LibraryProvider>();
    final auth = context.watch<AuthNotifier>();

    final book = provider.books.cast<Book?>().firstWhere(
          (b) => b?.id == id,
          orElse: () => null,
        );

    if (book == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Карточка книги')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.menu_book, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Книга не найдена или была удалена', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () => context.go('/'),
                child: const Text('Вернуться в каталог'),
              ),
            ],
          ),
        ),
      );
    }

    final publisher = provider.publishers.cast<Publisher?>().firstWhere(
          (p) => p?.id == book.publisherId,
          orElse: () => null,
        );
    final bookAuthors = provider.authors.where((a) => book.authorIds.contains(a.id)).toList();
    final bookGenres = provider.genres.where((g) => book.genreIds.contains(g.id)).toList();
    final hasCopies = book.copiesAvailable > 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(book.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Назад в каталог',
          onPressed: () => context.go('/'),
        ),
        actions: [
          if (canManageBooks(auth.user))
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Редактировать',
              onPressed: () => context.go('/books/${book.id}/edit'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 80,
                          height: 110,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.auto_stories,
                            size: 48,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                book.title,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'ISBN: ${book.isbn}',
                                style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
                              ),
                              const SizedBox(height: 8),
                              Chip(
                                avatar: Icon(
                                  hasCopies ? Icons.check_circle : Icons.remove_circle,
                                  color: hasCopies ? Colors.green.shade800 : Colors.red.shade800,
                                  size: 18,
                                ),
                                label: Text(
                                  hasCopies
                                      ? 'В наличии: ${book.copiesAvailable} из ${book.copiesTotal} экз.'
                                      : 'Нет доступных экземпляров (всего ${book.copiesTotal})',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: hasCopies ? Colors.green.shade900 : Colors.red.shade900,
                                  ),
                                ),
                                backgroundColor: hasCopies ? Colors.green.shade50 : Colors.red.shade50,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 36),
                    _buildInfoSection(
                      context,
                      title: 'Авторы произведения',
                      child: bookAuthors.isEmpty
                          ? const Text('Не указаны')
                          : Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: bookAuthors
                                  .map((a) => Chip(
                                        avatar: const Icon(Icons.person, size: 16),
                                        label: Text('${a.name} (${a.country})'),
                                      ))
                                  .toList(),
                            ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoSection(
                      context,
                      title: 'Жанры',
                      child: bookGenres.isEmpty
                          ? const Text('Не указаны')
                          : Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: bookGenres
                                  .map((g) => Chip(
                                        avatar: const Icon(Icons.category, size: 16),
                                        label: Text(g.name),
                                      ))
                                  .toList(),
                            ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoSection(
                      context,
                      title: 'Издательство и публикация',
                      child: Text(
                        publisher != null
                            ? '${publisher.name} (г. ${publisher.city}), ${book.year > 0 ? '${book.year} г.' : 'год не указан'}'
                            : 'Издательство: ID ${book.publisherId}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoSection(
                      context,
                      title: 'Параметры издания',
                      child: Text(
                        'Количество страниц: ${book.pages > 0 ? book.pages : 'не указано'}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => context.go('/'),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('В каталог'),
                        ),
                        const SizedBox(width: 12),
                        if (canManageBooks(auth.user))
                          FilledButton.icon(
                            onPressed: () => context.go('/books/${book.id}/edit'),
                            icon: const Icon(Icons.edit),
                            label: const Text('Редактировать'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, {required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}