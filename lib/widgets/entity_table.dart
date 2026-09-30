import 'package:flutter/material.dart';

class TableColumnSpec<T> {
  final String label;
  final String? sortField;
  final bool numeric;
  final Widget Function(T item) build;

  const TableColumnSpec({
    required this.label,
    required this.build,
    this.sortField,
    this.numeric = false,
  });
}

class EntityTable<T> extends StatelessWidget {
  final List<TableColumnSpec<T>> columns;
  final List<T> items;
  final int Function(T item) idOf;
  final Set<int> selected;
  final ValueChanged<int>? onToggleSelect;
  final ValueChanged<bool?>? onSelectAll;
  final String? sortField;
  final bool sortAscending;
  final void Function(String field)? onSort;
  final List<Widget> Function(T item)? actions;

  const EntityTable({
    super.key,
    required this.columns,
    required this.items,
    required this.idOf,
    this.selected = const {},
    this.onToggleSelect,
    this.onSelectAll,
    this.sortField,
    this.sortAscending = true,
    this.onSort,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    int? sortColIndex;
    if (sortField != null) {
      final idx = columns.indexWhere((c) => c.sortField == sortField);
      if (idx != -1) sortColIndex = idx;
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: MediaQuery.sizeOf(context).width - 32),
            child: DataTable(
              showCheckboxColumn: true,
              sortColumnIndex: sortColIndex,
              sortAscending: sortAscending,
              onSelectAll: onSelectAll,
              columns: [
                for (final col in columns)
                  DataColumn(
                    label: Text(
                      col.label,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    numeric: col.numeric,
                    onSort: col.sortField != null && onSort != null
                        ? (_, __) => onSort!(col.sortField!)
                        : null,
                  ),
                if (actions != null)
                  const DataColumn(
                    label: Text(
                      'Действия',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
              rows: items.map((item) {
                final id = idOf(item);
                final isRowSelected = selected.contains(id);

                return DataRow(
                  selected: isRowSelected,
                  onSelectChanged: onToggleSelect != null
                      ? (_) => onToggleSelect!(id)
                      : null,
                  cells: [
                    for (final col in columns) DataCell(col.build(item)),
                    if (actions != null)
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: actions!(item),
                        ),
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
