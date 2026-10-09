import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ForbiddenScreen extends StatelessWidget {
  const ForbiddenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Доступ запрещен')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.gpp_bad, size: 72, color: Colors.red),
              const SizedBox(height: 16),
              const Text('403 - Недостаточно прав', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Ваша учетная запись не имеет прав для просмотра этого раздела.', textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton(onPressed: () => context.go('/'), child: const Text('Вернуться в каталог')),
            ],
          ),
        ),
      ),
    );
  }
}