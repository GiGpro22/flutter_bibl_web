import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../state/library_provider.dart';
import '../models/publisher.dart';
import '../widgets/entity_toolbar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Параметры для каждой из 5 вкладок (поиск, корзина, сортировка, страница)
  final Map<int, String> _search = {0: '', 1: '', 2: '', 3: '', 4: ''};
  final Map<int, bool> _showDeleted = {0: false, 1: false, 2: false, 3: false, 4: false};
  final Map<int, String> _sort = {0: 'asc', 1: 'asc', 2: 'asc', 3: 'asc', 4: 'asc'};
  final Map<int, int> _page = {0: 1, 1: 1, 2: 1, 3: 1, 4: 1};
  static const int _pageSize = 5;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _confirmDeletePublisher(BuildContext context, Publisher publisher, bool hard) {
    final provider = context.read<LibraryProvider>();
    final linkedBooks = provider.getLinkedBooksCountForPublisher(publisher.id);

    if (linkedBooks > 0 && !hard) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Невозможно удалить издательство'),
          content: Text('К издательству "${publisher.name}" привязано $linkedBooks книг. Удаление заблокировано.'),
          actions: [FilledButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Понятно'))],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(hard ? 'Удалить навсегда?' : 'Переместить в корзину?'),
        content: Text('Издательство: ${publisher.name}'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Отмена')),
          FilledButton(
            onPressed: () {
              hard ? provider.hardDeletePublisher(publisher.id) : provider.softDeletePublisher(publisher.id);
              Navigator.of(ctx).pop();
            },
            child: const Text('Подтвердить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LibraryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Библиотечная система (ПР3 - Оценка 5)'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.book), text: 'Книги'),
            Tab(icon: Icon(Icons.person), text: 'Авторы'),
            Tab(icon: Icon(Icons.category), text: 'Жанры'),
            Tab(icon: Icon(Icons.business), text: 'Издательства'),
            Tab(icon: Icon(Icons.badge), text: 'Читатели'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBooksTab(context, provider),
          _buildAuthorsTab(context, provider),
          _buildGenresTab(context, provider),
          _buildPublishersTab(context, provider),
          _buildReadersTab(context, provider),
        ],
      ),
    );
  }

  // --- Вкладка Книги ---
  Widget _buildBooksTab(BuildContext context, LibraryProvider provider) {
    const tabIdx = 0;
    var list = provider.books.where((b) => _showDeleted[tabIdx]! ? b.isDeleted : !b.isDeleted).toList();

    final query = _search[tabIdx]!.toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((b) => b.title.toLowerCase().contains(query) || b.isbn.toLowerCase().contains(query)).toList();
    }

    list.sort((a, b) => _sort[tabIdx] == 'asc' ? a.title.compareTo(b.title) : b.title.compareTo(a.title));

    final totalPages = (list.length / _pageSize).ceil();
    final currentPage = _page[tabIdx]!.clamp(1, totalPages == 0 ? 1 : totalPages);
    final paged = list.skip((currentPage - 1) * _pageSize).take(_pageSize).toList();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/books/new'),
        icon: const Icon(Icons.add),
        label: const Text('Добавить книгу'),
      ),
      body: Column(
        children: [
          EntityToolbar(
            searchHint: 'Поиск книги по названию/ISBN...',
            onSearch: (q) => setState(() { _search[tabIdx] = q; _page[tabIdx] = 1; }),
            showDeleted: _showDeleted[tabIdx]!,
            onToggleDeleted: (val) => setState(() { _showDeleted[tabIdx] = val; _page[tabIdx] = 1; }),
            sortOrder: _sort[tabIdx]!,
            onSortChanged: (s) => setState(() => _sort[tabIdx] = s),
            page: currentPage,
            totalPages: totalPages,
            onPrevPage: () => setState(() => _page[tabIdx] = currentPage - 1),
            onNextPage: () => setState(() => _page[tabIdx] = currentPage + 1),
          ),
          Expanded(
            child: paged.isEmpty
                ? const Center(child: Text('Ничего не найдено'))
                : ListView.builder(
                    itemCount: paged.length,
                    itemBuilder: (ctx, i) {
                      final b = paged[i];
                      final pub = provider.publishers.cast<Publisher?>().firstWhere((p) => p?.id == b.publisherId, orElse: () => null);
                      return ListTile(
                        title: Text(b.title, style: TextStyle(decoration: b.isDeleted ? TextDecoration.lineThrough : null)),
                        subtitle: Text('ISBN: ${b.isbn} | Изд-во: ${pub?.name ?? "Не указано"}'),
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
          ),
        ],
      ),
    );
  }

  // --- Вкладка Авторы ---
  Widget _buildAuthorsTab(BuildContext context, LibraryProvider provider) {
    const tabIdx = 1;
    var list = provider.authors.where((a) => _showDeleted[tabIdx]! ? a.isDeleted : !a.isDeleted).toList();

    final query = _search[tabIdx]!.toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((a) => a.name.toLowerCase().contains(query) || a.country.toLowerCase().contains(query)).toList();
    }

    list.sort((a, b) => _sort[tabIdx] == 'asc' ? a.name.compareTo(b.name) : b.name.compareTo(a.name));

    final totalPages = (list.length / _pageSize).ceil();
    final currentPage = _page[tabIdx]!.clamp(1, totalPages == 0 ? 1 : totalPages);
    final paged = list.skip((currentPage - 1) * _pageSize).take(_pageSize).toList();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/authors/new'),
        icon: const Icon(Icons.add),
        label: const Text('Добавить автора'),
      ),
      body: Column(
        children: [
          EntityToolbar(
            searchHint: 'Поиск автора по имени/стране...',
            onSearch: (q) => setState(() { _search[tabIdx] = q; _page[tabIdx] = 1; }),
            showDeleted: _showDeleted[tabIdx]!,
            onToggleDeleted: (val) => setState(() { _showDeleted[tabIdx] = val; _page[tabIdx] = 1; }),
            sortOrder: _sort[tabIdx]!,
            onSortChanged: (s) => setState(() => _sort[tabIdx] = s),
            page: currentPage,
            totalPages: totalPages,
            onPrevPage: () => setState(() => _page[tabIdx] = currentPage - 1),
            onNextPage: () => setState(() => _page[tabIdx] = currentPage + 1),
          ),
          Expanded(
            child: paged.isEmpty
                ? const Center(child: Text('Ничего не найдено'))
                : ListView.builder(
                    itemCount: paged.length,
                    itemBuilder: (ctx, i) {
                      final a = paged[i];
                      return ListTile(
                        title: Text(a.name, style: TextStyle(decoration: a.isDeleted ? TextDecoration.lineThrough : null)),
                        subtitle: Text('${a.country} (${a.birthYear}) - ${a.biography}', maxLines: 1),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!a.isDeleted)
                              IconButton(icon: const Icon(Icons.edit), onPressed: () => context.go('/authors/${a.id}/edit')),
                            if (!a.isDeleted)
                              IconButton(icon: const Icon(Icons.delete_outline, color: Colors.orange), onPressed: () => provider.softDeleteAuthor(a.id)),
                            if (a.isDeleted)
                              IconButton(icon: const Icon(Icons.restore, color: Colors.green), onPressed: () => provider.restoreAuthor(a.id)),
                            if (a.isDeleted)
                              IconButton(icon: const Icon(Icons.delete_forever, color: Colors.red), onPressed: () => provider.hardDeleteAuthor(a.id)),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // --- Вкладка Жанры ---
  Widget _buildGenresTab(BuildContext context, LibraryProvider provider) {
    const tabIdx = 2;
    var list = provider.genres.where((g) => _showDeleted[tabIdx]! ? g.isDeleted : !g.isDeleted).toList();

    final query = _search[tabIdx]!.toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((g) => g.name.toLowerCase().contains(query)).toList();
    }

    list.sort((a, b) => _sort[tabIdx] == 'asc' ? a.name.compareTo(b.name) : b.name.compareTo(a.name));

    final totalPages = (list.length / _pageSize).ceil();
    final currentPage = _page[tabIdx]!.clamp(1, totalPages == 0 ? 1 : totalPages);
    final paged = list.skip((currentPage - 1) * _pageSize).take(_pageSize).toList();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/genres/new'),
        icon: const Icon(Icons.add),
        label: const Text('Добавить жанр'),
      ),
      body: Column(
        children: [
          EntityToolbar(
            searchHint: 'Поиск жанра по названию...',
            onSearch: (q) => setState(() { _search[tabIdx] = q; _page[tabIdx] = 1; }),
            showDeleted: _showDeleted[tabIdx]!,
            onToggleDeleted: (val) => setState(() { _showDeleted[tabIdx] = val; _page[tabIdx] = 1; }),
            sortOrder: _sort[tabIdx]!,
            onSortChanged: (s) => setState(() => _sort[tabIdx] = s),
            page: currentPage,
            totalPages: totalPages,
            onPrevPage: () => setState(() => _page[tabIdx] = currentPage - 1),
            onNextPage: () => setState(() => _page[tabIdx] = currentPage + 1),
          ),
          Expanded(
            child: paged.isEmpty
                ? const Center(child: Text('Ничего не найдено'))
                : ListView.builder(
                    itemCount: paged.length,
                    itemBuilder: (ctx, i) {
                      final g = paged[i];
                      return ListTile(
                        title: Text(g.name, style: TextStyle(decoration: g.isDeleted ? TextDecoration.lineThrough : null)),
                        subtitle: Text(g.description),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!g.isDeleted)
                              IconButton(icon: const Icon(Icons.edit), onPressed: () => context.go('/genres/${g.id}/edit')),
                            if (!g.isDeleted)
                              IconButton(icon: const Icon(Icons.delete_outline, color: Colors.orange), onPressed: () => provider.softDeleteGenre(g.id)),
                            if (g.isDeleted)
                              IconButton(icon: const Icon(Icons.restore, color: Colors.green), onPressed: () => provider.restoreGenre(g.id)),
                            if (g.isDeleted)
                              IconButton(icon: const Icon(Icons.delete_forever, color: Colors.red), onPressed: () => provider.hardDeleteGenre(g.id)),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // --- Вкладка Издательства ---
  Widget _buildPublishersTab(BuildContext context, LibraryProvider provider) {
    const tabIdx = 3;
    var list = provider.publishers.where((p) => _showDeleted[tabIdx]! ? p.isDeleted : !p.isDeleted).toList();

    final query = _search[tabIdx]!.toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((p) => p.name.toLowerCase().contains(query) || p.city.toLowerCase().contains(query)).toList();
    }

    list.sort((a, b) => _sort[tabIdx] == 'asc' ? a.name.compareTo(b.name) : b.name.compareTo(a.name));

    final totalPages = (list.length / _pageSize).ceil();
    final currentPage = _page[tabIdx]!.clamp(1, totalPages == 0 ? 1 : totalPages);
    final paged = list.skip((currentPage - 1) * _pageSize).take(_pageSize).toList();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/publishers/new'),
        icon: const Icon(Icons.add),
        label: const Text('Добавить издательство'),
      ),
      body: Column(
        children: [
          EntityToolbar(
            searchHint: 'Поиск издательства по названию/городу...',
            onSearch: (q) => setState(() { _search[tabIdx] = q; _page[tabIdx] = 1; }),
            showDeleted: _showDeleted[tabIdx]!,
            onToggleDeleted: (val) => setState(() { _showDeleted[tabIdx] = val; _page[tabIdx] = 1; }),
            sortOrder: _sort[tabIdx]!,
            onSortChanged: (s) => setState(() => _sort[tabIdx] = s),
            page: currentPage,
            totalPages: totalPages,
            onPrevPage: () => setState(() => _page[tabIdx] = currentPage - 1),
            onNextPage: () => setState(() => _page[tabIdx] = currentPage + 1),
          ),
          Expanded(
            child: paged.isEmpty
                ? const Center(child: Text('Ничего не найдено'))
                : ListView.builder(
                    itemCount: paged.length,
                    itemBuilder: (ctx, i) {
                      final p = paged[i];
                      final linked = provider.getLinkedBooksCountForPublisher(p.id);
                      return ListTile(
                        title: Text(p.name, style: TextStyle(decoration: p.isDeleted ? TextDecoration.lineThrough : null)),
                        subtitle: Text('Город: ${p.city} | Привязано книг: $linked'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!p.isDeleted)
                              IconButton(icon: const Icon(Icons.edit), onPressed: () => context.go('/publishers/${p.id}/edit')),
                            if (!p.isDeleted)
                              IconButton(icon: const Icon(Icons.delete_outline, color: Colors.orange), onPressed: () => _confirmDeletePublisher(context, p, false)),
                            if (p.isDeleted)
                              IconButton(icon: const Icon(Icons.restore, color: Colors.green), onPressed: () => provider.restorePublisher(p.id)),
                            if (p.isDeleted)
                              IconButton(icon: const Icon(Icons.delete_forever, color: Colors.red), onPressed: () => _confirmDeletePublisher(context, p, true)),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // --- Вкладка Читатели ---
  Widget _buildReadersTab(BuildContext context, LibraryProvider provider) {
    const tabIdx = 4;
    var list = provider.readers.where((r) => _showDeleted[tabIdx]! ? r.isDeleted : !r.isDeleted).toList();

    final query = _search[tabIdx]!.toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((r) => r.fullName.toLowerCase().contains(query) || r.email.toLowerCase().contains(query)).toList();
    }

    list.sort((a, b) => _sort[tabIdx] == 'asc' ? a.fullName.compareTo(b.fullName) : b.fullName.compareTo(a.fullName));

    final totalPages = (list.length / _pageSize).ceil();
    final currentPage = _page[tabIdx]!.clamp(1, totalPages == 0 ? 1 : totalPages);
    final paged = list.skip((currentPage - 1) * _pageSize).take(_pageSize).toList();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/readers/new'),
        icon: const Icon(Icons.add),
        label: const Text('Добавить читателя'),
      ),
      body: Column(
        children: [
          EntityToolbar(
            searchHint: 'Поиск читателя по ФИО/email...',
            onSearch: (q) => setState(() { _search[tabIdx] = q; _page[tabIdx] = 1; }),
            showDeleted: _showDeleted[tabIdx]!,
            onToggleDeleted: (val) => setState(() { _showDeleted[tabIdx] = val; _page[tabIdx] = 1; }),
            sortOrder: _sort[tabIdx]!,
            onSortChanged: (s) => setState(() => _sort[tabIdx] = s),
            page: currentPage,
            totalPages: totalPages,
            onPrevPage: () => setState(() => _page[tabIdx] = currentPage - 1),
            onNextPage: () => setState(() => _page[tabIdx] = currentPage + 1),
          ),
          Expanded(
            child: paged.isEmpty
                ? const Center(child: Text('Ничего не найдено'))
                : ListView.builder(
                    itemCount: paged.length,
                    itemBuilder: (ctx, i) {
                      final r = paged[i];
                      return ListTile(
                        title: Text(r.fullName, style: TextStyle(decoration: r.isDeleted ? TextDecoration.lineThrough : null)),
                        subtitle: Text('Email: ${r.email} | Билет: ${r.card.cardNumber} (${r.card.status})'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!r.isDeleted)
                              IconButton(icon: const Icon(Icons.edit), onPressed: () => context.go('/readers/${r.id}/edit')),
                            if (!r.isDeleted)
                              IconButton(icon: const Icon(Icons.delete_outline, color: Colors.orange), onPressed: () => provider.softDeleteReader(r.id)),
                            if (r.isDeleted)
                              IconButton(icon: const Icon(Icons.restore, color: Colors.green), onPressed: () => provider.restoreReader(r.id)),
                            if (r.isDeleted)
                              IconButton(icon: const Icon(Icons.delete_forever, color: Colors.red), onPressed: () => provider.hardDeleteReader(r.id)),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}