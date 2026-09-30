import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/author.dart';
import '../repositories/author_repository.dart';

class AuthorDetailScreen extends StatelessWidget {
  final int authorId;

  const AuthorDetailScreen({super.key, required this.authorId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Карточка автора'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/authors'),
        ),
      ),
      body: FutureBuilder<Author?>(
        future: context.read<AuthorRepository>().findById(authorId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final author = snapshot.data;
          if (author == null) {
            return const Center(child: Text('Автор не найден'));
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
                      Text(author.name, style: Theme.of(context).textTheme.headlineMedium),
                      const Divider(height: 32),
                      _detailRow('Страна', author.country),
                      _detailRow('Год рождения', '${author.birthYear}'),
                      _detailRow('Статус', author.isDeleted ? 'Удалён' : 'Активен'),
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
