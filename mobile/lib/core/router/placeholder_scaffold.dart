import 'package:dt13_pos/core/router/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Scaffold tạm cho các màn chưa làm. Có danh sách route để điều hướng thử.
/// Xoá khi mọi màn đã có UI thật.
class PlaceholderScaffold extends StatelessWidget {
  const PlaceholderScaffold({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    final current = GoRouterState.of(context).uri.path;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Placeholder: $current',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          for (final path in AppRoutes.all)
            if (path != current)
              ListTile(
                leading: const Icon(Icons.chevron_right),
                title: Text(path),
                onTap: () => context.go(path),
              ),
        ],
      ),
    );
  }
}
