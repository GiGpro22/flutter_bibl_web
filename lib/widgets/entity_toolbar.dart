import 'package:flutter/material.dart';

class EntityToolbar extends StatefulWidget {
  final String searchHint;
  final ValueChanged<String> onSearch;
  final bool showDeleted;
  final ValueChanged<bool> onToggleDeleted;
  final String sortOrder;
  final ValueChanged<String> onSortChanged;
  final int page;
  final int totalPages;
  final VoidCallback onPrevPage;
  final VoidCallback onNextPage;

  const EntityToolbar({
    super.key,
    required this.searchHint,
    required this.onSearch,
    required this.showDeleted,
    required this.onToggleDeleted,
    required this.sortOrder,
    required this.onSortChanged,
    required this.page,
    required this.totalPages,
    required this.onPrevPage,
    required this.onNextPage,
  });

  @override
  State<EntityToolbar> createState() => _EntityToolbarState();
}

class _EntityToolbarState extends State<EntityToolbar> {
  late final TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      color:
          Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(128),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.spaceBetween,
          children: [
            // Поле поиска
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 200, maxWidth: 320),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: widget.searchHint,
                  isDense: true,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            widget.onSearch('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onSubmitted: (val) => widget.onSearch(val),
              ),
            ),

            // Фильтры и переключатели
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilterChip(
                  label: const Text('Корзина'),
                  selected: widget.showDeleted,
                  onSelected: (val) => widget.onToggleDeleted(val),
                  avatar: Icon(
                    widget.showDeleted ? Icons.delete : Icons.delete_outline,
                    size: 16,
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: widget.sortOrder == 'asc'
                      ? 'Сортировка: А-Я'
                      : 'Сортировка: Я-А',
                  icon: Icon(
                    widget.sortOrder == 'asc'
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                    size: 20,
                  ),
                  onPressed: () => widget.onSortChanged(
                      widget.sortOrder == 'asc' ? 'desc' : 'asc'),
                ),
              ],
            ),

            // Пагинация
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Предыдущая страница',
                  onPressed: widget.page > 1 ? widget.onPrevPage : null,
                ),
                Text(
                    '${widget.page} /${widget.totalPages > 0 ? widget.totalPages : 1}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Следующая страница',
                  onPressed: widget.page < widget.totalPages
                      ? widget.onNextPage
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
