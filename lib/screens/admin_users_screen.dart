import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../models/app_user.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<AppUser> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await buildDio().get('/admin/users');
      final list = (res.data['items'] as List).map((e) => AppUser.fromJson(e as Map<String, dynamic>)).toList();
      setState(() => _users = list);
    } catch (_) {}
    finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Управление пользователями (Администратор)')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              itemCount: _users.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (ctx, i) {
                final u = _users[i];
                return ListTile(
                  leading: CircleAvatar(child: Text(u.role.name.substring(0, 1).toUpperCase())),
                  title: Text(u.name),
                  subtitle: Text(u.email),
                  trailing: Chip(label: Text(u.role.label)),
                );
              },
            ),
    );
  }
}