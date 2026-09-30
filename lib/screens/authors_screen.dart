import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/breakpoints.dart';
import '../models/author.dart';
import '../models/author_query.dart';
import '../state/author_list_notifier.dart';
import '../state/book_list_notifier.dart';
import '../widgets/entity_table.dart';
import '../widgets/pagination_bar.dart';

class AuthorsScreen extends StatefulWidget {
  const AuthorsScreen({super.key});

  @override
  State<AuthorsScreen> createState() => _AuthorsScreenState();
}

class _AuthorsScreenState extends State<AuthorsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounce;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final params = GoRouterState.of(context).uri.queryParameters;
    final query = AuthorQuery.fromQueryParams(params);

    if (!_searchFocusNode.hasFocus && _searchController.text != query.search) {
      _searchController.value = TextEditingValue(
        text: query.search,
        selection: TextSelection.collapsed(offset: query.search.length),
      );
    }

    final notifier = context.read<AuthorListNotifier>();
    if (notifier.query != query) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<AuthorListNotifier>().applyQuery(query);
        }
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _updateUrl(AuthorQuery next) {
    final uri = Uri(path: '/authors', queryParameters: next.toQueryParams());
    context.replace(uri.toString());
  }

  void _onSearchChanged(String val) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      final cur = AuthorQuery.fromQueryParams(
        GoRouterState.of(context).uri.queryParameters,
      );
      _updateUrl(cur.copyWith(search: val));
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<AuthorListNotifier>();
    final q = notifier.query;
    final compact = isCompact(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Авторы'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.menu_book),
            label: const Text('Книги'),
            onPressed: () => context.go('/books'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 240,
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Поиск по фамилии/стране...',
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                      border: const OutlineInputBorder(),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                final cur = AuthorQuery.fromQueryParams(
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
                FilterChip(
                  label: const Text('Включая удалённых'),
                  selected: q.includeDeleted,
                  onSelected: (val) => _updateUrl(q.copyWith(includeDeleted: val)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (notifier.hasSelection)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text('Выбрано: ${notifier.selected.length}'),
                    const Spacer(),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () => notifier.deleteSelected(),
                      child: const Text('Удалить выбранных'),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: switch (notifier.status) {
                LoadStatus.idle || LoadStatus.loading => const Center(child: CircularProgressIndicator()),
                LoadStatus.error => Center(child: Text(notifier.error ?? 'Ошибка')),
                LoadStatus.success when notifier.result.items.isEmpty => const Center(child: Text('Авторов не найдено')),
                LoadStatus.success => compact
                    ? ListView.builder(
                        itemCount: notifier.result.items.length,
                        itemBuilder: (ctx, i) {
                          final a = notifier.result.items[i];
                          return Card(
                            child: ListTile(
                              leading: Checkbox(
                                value: notifier.selected.contains(a.id),
                                onChanged: (_) => notifier.toggleSelection(a.id),
                              ),
                              title: Text(a.name),
                              subtitle: Text('${a.country}, родился в ${a.birthYear}'),
                              onTap: () => context.go('/authors/${a.id}'),
                            ),
                          );
                        },
                      )
                    : EntityTable<Author>(
                        items: notifier.result.items,
                        idOf: (a) => a.id,
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
                            label: 'Имя / Фамилия',
                            sortField: 'name',
                            build: (a) => Text(
                              a.name,
                              style: TextStyle(
                                decoration: a.isDeleted ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          ),
                          TableColumnSpec(
                            label: 'Страна',
                            sortField: 'country',
                            build: (a) => Text(a.country),
                          ),
                          TableColumnSpec(
                            label: 'Год рождения',
                            sortField: 'birthYear',
                            numeric: true,
                            build: (a) => Text('${a.birthYear}'),
                          ),
                        ],
                        actions: (a) => [
                          IconButton(
                            icon: const Icon(Icons.visibility),
                            onPressed: () => context.go('/authors/${a.id}'),
                          ),
                          if (a.isDeleted)
                            IconButton(
                              icon: const Icon(Icons.restore, color: Colors.green),
                              onPressed: () => notifier.restore(a.id),
                            )
                          else
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => notifier.softDelete(a.id),
                            ),
                          IconButton(
                            icon: const Icon(Icons.delete_forever, color: Colors.red),
                            onPressed: () => notifier.hardDelete(a.id),
                          ),
                        ],
                      ),
              },
            ),
            PaginationBar(
              currentPage: notifier.result.page,
              pageSize: notifier.result.size,
              totalItems: notifier.result.total,
              onPageChanged: (p) => _updateUrl(q.copyWith(page: p)),
              onPageSizeChanged: (s) => _updateUrl(q.copyWith(size: s, page: 1)),
            ),
          ],
        ),
      ),
    );
  }
}
