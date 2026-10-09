import 'package:flutter/material.dart';
import '../core/api_client.dart';

class ManageLoansScreen extends StatefulWidget {
  const ManageLoansScreen({super.key});

  @override
  State<ManageLoansScreen> createState() => _ManageLoansScreenState();
}

class _ManageLoansScreenState extends State<ManageLoansScreen> {
  List<Map<String, dynamic>> _loans = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await buildDio().get('/librarian/loans');
      final list = (res.data['items'] as List).cast<Map<String, dynamic>>();
      setState(() => _loans = list);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _closeLoan(int id) async {
    try {
      await buildDio().post('/librarian/loans/$id/close');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Книга возвращена в фонд библиотеки')),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red.shade800, content: Text('Ошибка: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Журнал выдач (Рабочее место библиотекаря)')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Ошибка загрузки: $_error', style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 12),
                      FilledButton(onPressed: _load, child: const Text('Повторить')),
                    ],
                  ),
                )
              : _loans.isEmpty
                  ? const Center(child: Text('Нет открытых выдач'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _loans.length,
                      itemBuilder: (ctx, i) {
                        final item = _loans[i];
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.assignment_turned_in, color: Colors.deepPurple),
                            title: Text(item['bookTitle'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Читатель: ${item['userName']} \vert{} Срок сдачи: ${item['dueDate']}'),
                            trailing: FilledButton.tonal(
                              onPressed: () => _closeLoan(item['id'] as int),
                              child: const Text('Принять возврат'),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}