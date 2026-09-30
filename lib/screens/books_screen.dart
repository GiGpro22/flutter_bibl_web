import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/breakpoints.dart';
import '../models/book.dart';
import '../models/book_query.dart';
import '../models/dictionary_data.dart';
import '../state/book_list_notifier.dart';
import '../widgets/entity_table.dart';
import '../widgets/pagination_bar.dart';

class BooksScreen extends StatefulWidget {
  const BooksScreen({super.key});

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _yearFromController = TextEditingController();
  final TextEditingController _yearToController = TextEditingController();
  Timer? _debounce;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final params = GoRouterState.of(context).uri.queryParameters;
    final queryFromUrl = BookQuery.fromQueryParams(params);

    // Синхронизируем текст только тогда, когда пользователь не печатает прямо сейчас
    if (!_searchFocusNode.hasFocus && _searchController.text != queryFromUrl.search) {
      _searchController.value = TextEditingValue(
        text: queryFromUrl.search,
        selection: TextSelection.collapsed(offset: queryFromUrl.search.length),
      );
    }
    final yf = queryFromUrl.yearFrom?.toString() ?? '';
    if (_yearFromController.text != yf) _yearFromController.text = yf;
    final yt = queryFromUrl.yearTo?.toString() ?? '';
    if (_yearToController.text != yt) _yearToController.text = yt;

    final notifier = context.read<BookListNotifier>();
    if (notifier.query != queryFromUrl) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<BookListNotifier>().applyQuery(queryFromUrl);
        }
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _yearFromController.dispose();
    _yearToController.dispose();
    super.dispose();
  }

  void _updateUrl(BookQuery next) {
    final uri = Uri(path: '/books', queryParameters: next.toQueryParams());
    context.replace(uri.toString());
  }

  void _onSearchChanged(String val) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      final currentQuery = BookQuery.fromQueryParams(
        GoRouterState.of(context).uri.queryParameters,
      );
      _updateUrl(currentQuery.copyWith(search: val));
    });
  }

  void _confirmDeleteSelected(BuildContext context) {
    final notifier = context.read<BookListNotifier>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Подтверждение удаления'),
        content: Text('Удалить выбранные книги (${notifier.selected.length} шт.)?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              notifier.deleteSelected();
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<BookListNotifier>();
    final q = notifier.query;
    final compact = isCompact(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Каталог книг'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.person),
            label: const Text('Авторы'),
            onPressed: () => context.go('/authors'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 220,
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Поиск по названию/ISBN...',
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                      border: const OutlineInputBorder(),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                final cur = BookQuery.fromQueryParams(
                                  GoRouterState.of(context).uri.queryParameters,
                                );
                                _updateUrl(cur.copyWith(search: ''));
                              },
                            )
                          : null,
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),
                SizedBox(
                  width: 170,
                  child: DropdownButtonFormField<int?>(
                    value: q.genreId,
                    isDense: true,
                    decoration: const InputDecoration(labelText: 'Жанр', border: OutlineInputBorder()),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Все жанры')),
                      ...DictionaryData.genres.entries.map(
                        (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                      ),
                    ],
                    onChanged: (val) => _updateUrl(q.copyWith(genreId: val)),
                  ),
                ),
                SizedBox(
                  width: 170,
                  child: DropdownButtonFormField<int?>(
                    value: q.publisherId,
                    isDense: true,
                    decoration: const InputDecoration(labelText: 'Издательство', border: OutlineInputBorder()),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Все изд-ва')),
                      ...DictionaryData.publishers.entries.map(
                        (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                      ),
                    ],
                    onChanged: (val) => _updateUrl(q.copyWith(publisherId: val)),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _yearFromController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Год от', border: OutlineInputBorder(), isDense: true),
                    onSubmitted: (val) => _updateUrl(q.copyWith(yearFrom: int.tryParse(val))),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _yearToController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Год до', border: OutlineInputBorder(), isDense: true),
                    onSubmitted: (val) => _updateUrl(q.copyWith(yearTo: int.tryParse(val))),
                  ),
                ),
                FilterChip(
                  label: const Text('Включая удалённые'),
                  selected: q.includeDeleted,
                  onSelected: (val) => _updateUrl(q.copyWith(includeDeleted: val)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (notifier.hasSelection)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text(
                      'Выбрано: ${notifier.selected.length}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Удалить выбранные'),
                      style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
                      onPressed: () => _confirmDeleteSelected(context),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: switch (notifier.status) {
                LoadStatus.idle || LoadStatus.loading => const Center(child: CircularProgressIndicator()),
                LoadStatus.error => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 8),
                        Text(notifier.error ?? 'Произошла ошибка'),
                        const SizedBox(height: 12),
                        FilledButton(onPressed: () => notifier.load(), child: const Text('Повторить')),
                      ],
                    ),
                  ),
                LoadStatus.success when notifier.result.items.isEmpty => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.search_off, size: 48, color: Colors.grey),
                        const SizedBox(height: 8),
                        const Text('Книг по заданным фильтрам не найдено'),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => _updateUrl(const BookQuery()),
                          child: const Text('Сбросить фильтры'),
                        ),
                      ],
                    ),
                  ),
                LoadStatus.success => compact
                    ? _buildCardList(context, notifier)
                    : _buildTable(context, notifier),
              },
            ),
            PaginationBar(
              currentPage: notifier.result.page,
              pageSize: notifier.result.size,
              totalItems: notifier.result.total,
              onPageChanged: (page) => _updateUrl(q.copyWith(page: page)),
              onPageSizeChanged: (size) => _updateUrl(q.copyWith(size: size, page: 1)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTable(BuildContext context, BookListNotifier notifier) {
    final q = notifier.query;
    return EntityTable<Book>(
      items: notifier.result.items,
      idOf: (b) => b.id,
      selected: notifier.selected,
      onToggleSelect: notifier.toggleSelection,
      onSelectAll: notifier.toggleSelectAll,
      sortField: q.sortField,
      sortAscending: q.sortAscending,
      onSort: (field) {
        final asc = field == q.sortField ? !q.sortAscending : true;
        _updateUrl(q.copyWith(sortField: field, sortAscending: asc));
      },
      columns: [
        TableColumnSpec(
          label: 'Название',
          sortField: 'title',
          build: (b) => Text(
            b.title,
            style: TextStyle(
              decoration: b.isDeleted ? TextDecoration.lineThrough : null,
              color: b.isDeleted ? Colors.grey : null,
            ),
          ),
        ),
        TableColumnSpec(label: 'ISBN', build: (b) => Text(b.isbn)),
        TableColumnSpec(
          label: 'Год',
          sortField: 'year',
          numeric: true,
          build: (b) => Text('${b.year}'),
        ),
        TableColumnSpec(
          label: 'Страниц',
          sortField: 'pages',
          numeric: true,
          build: (b) => Text('${b.pages}'),
        ),
        TableColumnSpec(
          label: 'Издательство',
          build: (b) => Text(DictionaryData.publishers[b.publisherId] ?? '-'),
        ),
        TableColumnSpec(
          label: 'Экземпляры',
          numeric: true,
          build: (b) => Text('${b.copiesAvailable} / ${b.copiesTotal}'),
        ),
      ],
      actions: (b) => [
        IconButton(
          icon: const Icon(Icons.visibility),
          tooltip: 'Открыть карточку',
          onPressed: () => context.go('/books/${b.id}'),
        ),
        if (b.isDeleted)
          IconButton(
            icon: const Icon(Icons.restore, color: Colors.green),
            tooltip: 'Восстановить',
            onPressed: () => notifier.restore(b.id),
          )
        else
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Мягкое удаление',
            onPressed: () => notifier.softDelete(b.id),
          ),
        IconButton(
          icon: const Icon(Icons.delete_forever, color: Colors.red),
          tooltip: 'Физическое удаление',
          onPressed: () => notifier.hardDelete(b.id),
        ),
      ],
    );
  }

  Widget _buildCardList(BuildContext context, BookListNotifier notifier) {
    return ListView.builder(
      itemCount: notifier.result.items.length,
      itemBuilder: (context, index) {
        final b = notifier.result.items[index];
        final isSelected = notifier.selected.contains(b.id);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: Checkbox(
              value: isSelected,
              onChanged: (_) => notifier.toggleSelection(b.id),
            ),
            title: Text(
              b.title,
              style: TextStyle(
                decoration: b.isDeleted ? TextDecoration.lineThrough : null,
                color: b.isDeleted ? Colors.grey : null,
              ),
            ),
            subtitle: Text(
              '${b.year} г. • ${b.pages} стр. • ${DictionaryData.publishers[b.publisherId] ?? ""}',
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (val) {
                switch (val) {
                  case 'view':
                    context.go('/books/${b.id}');
                    break;
                  case 'soft':
                    notifier.softDelete(b.id);
                    break;
                  case 'restore':
                    notifier.restore(b.id);
                    break;
                  case 'hard':
                    notifier.hardDelete(b.id);
                    break;
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(value: 'view', child: Text('Открыть')),
                if (b.isDeleted)
                  const PopupMenuItem(value: 'restore', child: Text('Восстановить'))
                else
                  const PopupMenuItem(value: 'soft', child: Text('В корзину')),
                const PopupMenuItem(value: 'hard', child: Text('Удалить насовсем', style: TextStyle(color: Colors.red))),
              ],
            ),
          ),
        );
      },
    );
  }
}
