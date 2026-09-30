import 'package:flutter/material.dart';

class PaginationBar extends StatelessWidget {
  final int currentPage;
  final int pageSize;
  final int totalItems;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onPageSizeChanged;

  const PaginationBar({
    super.key,
    required this.currentPage,
    required this.pageSize,
    required this.totalItems,
    required this.onPageChanged,
    required this.onPageSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final totalPages = totalItems == 0 ? 1 : (totalItems / pageSize).ceil();
    final from = totalItems == 0 ? 0 : (currentPage - 1) * pageSize + 1;
    final to = (currentPage * pageSize) > totalItems ? totalItems : (currentPage * pageSize);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 8,
        children: [
          Text(
            'Показано $from–$to из $totalItems',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Строк на странице: '),
              DropdownButton<int>(
                value: pageSize,
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: 10, child: Text('10')),
                  DropdownMenuItem(value: 25, child: Text('25')),
                  DropdownMenuItem(value: 50, child: Text('50')),
                ],
                onChanged: (val) {
                  if (val != null) onPageSizeChanged(val);
                },
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.first_page),
                tooltip: 'Первая страница',
                onPressed: currentPage > 1 ? () => onPageChanged(1) : null,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Предыдущая',
                onPressed: currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text('$currentPage из $totalPages'),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Следующая',
                onPressed: currentPage < totalPages ? () => onPageChanged(currentPage + 1) : null,
              ),
              IconButton(
                icon: const Icon(Icons.last_page),
                tooltip: 'Последняя страница',
                onPressed: currentPage < totalPages ? () => onPageChanged(totalPages) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
