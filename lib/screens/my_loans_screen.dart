import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../models/loan.dart';

class MyLoansScreen extends StatefulWidget {
  const MyLoansScreen({super.key});

  @override
  State<MyLoansScreen> createState() => _MyLoansScreenState();
}

class _MyLoansScreenState extends State<MyLoansScreen> {
  List<Loan> _loans = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final dio = buildDio();
      final res = await dio.get('/my-loans');
      final list = (res.data['items'] as List).map((e) => Loan.fromJson(e as Map<String, dynamic>)).toList();
      if (mounted) setState(() => _loans = list);
    } catch (_) {}
    finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _extend(int id) async {
    try {
      final dio = buildDio();
      await dio.post('/my-loans/$id/extend');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Срок возврата продлен на 14 дней')));
      _fetch();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ошибка продления')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Мои выданные книги (Кабинет читателя)')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loans.isEmpty
              ? const Center(child: Text('У вас нет активных выдач'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _loans.length,
                  itemBuilder: (ctx, i) {
                    final l = _loans[i];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.bookmark),
                        title: Text(l.bookTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Выдана: ${l.issueDate} \vert{} Вернуть до: ${l.dueDate}'),
                        trailing: l.isExtended
                            ? const Chip(label: Text('Продлена'), backgroundColor: Colors.amberAccent)
                            : FilledButton.tonal(onPressed: () => _extend(l.id), child: const Text('Продлить')),
                      ),
                    );
                  },
                ),
    );
  }
}