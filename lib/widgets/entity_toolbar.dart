import 'dart:async';
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
  Timer? _debounce;
  final _searchController = TextEditingController();

  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      widget.onSearch(text);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Wrap(
          spacing: 16,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.spaceBetween,
          children: [
            SizedBox(
              width: 260,
              child: TextField(
                controller: _searchController,
                onChanged: _onChanged,
                decoration: InputDecoration(
                  hintText: widget.searchHint,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Корзина:'),
                Switch(
                  value: widget.showDeleted,
                  onChanged: widget.onToggleDeleted,
                ),
              ],
            ),
            DropdownButton<String>(
              value: widget.sortOrder,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'asc', child: Text('По возрастанию (А-Я)')),
                DropdownMenuItem(value: 'desc', child: Text('По убыванию (Я-А)')),
              ],
              onChanged: (val) {
                if (val != null) widget.onSortChanged(val);
              },
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: widget.page > 1 ? widget.onPrevPage : null,
                ),
                Text('Стр. ${widget.page} из ${widget.totalPages == 0 ? 1 : widget.totalPages}'),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: widget.page < widget.totalPages ? widget.onNextPage : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}