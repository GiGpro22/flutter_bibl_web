import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/book.dart';
import '../models/dictionary_data.dart';
import '../repositories/book_repository.dart';

class BookDetailScreen extends StatelessWidget {
  final int bookId;

  const BookDetailScreen({super.key, required this.bookId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Карточка книги'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/books'),
        ),
      ),
      body: FutureBuilder<Book?>(
        future: context.read<BookRepository>().findById(bookId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final book = snapshot.data;
          if (book == null) {
            return const Center(child: Text('Книга не найдена'));
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Card(
                margin: const EdgeInsets.all(24),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(book.title, style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 8),
                      Text('ISBN: ${book.isbn}', style: const TextStyle(color: Colors.grey)),
                      const Divider(height: 32),
                      _detailRow('Год издания', '${book.year}'),
                      _detailRow('Количество страниц', '${book.pages}'),
                      _detailRow('Издательство', DictionaryData.publishers[book.publisherId] ?? '-'),
                      _detailRow('Всего экземпляров', '${book.copiesTotal}'),
                      _detailRow('Доступно', '${book.copiesAvailable}'),
                      _detailRow('Статус', book.isDeleted ? 'В корзине (удалена)' : 'Активна'),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}
