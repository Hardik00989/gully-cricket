import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/admin/providers/admin_providers.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../utils/friendly_error.dart';

class RecordMenu extends ConsumerWidget {
  const RecordMenu({
    super.key,
    required this.kind,
    required this.id,
    required this.name,
    this.allowEdit = true,
  });
  final String kind, id, name;
  final bool allowEdit;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(managementAccessProvider)) return const SizedBox.shrink();
    return PopupMenuButton<String>(
      tooltip: 'More options',
      onSelected: (action) async {
        if (action == 'edit') {
          context.push('/admin/$kind/$id');
          return;
        }
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Delete $name?'),
            content: const Text('This cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (confirmed != true) return;
        final ok = await ref
            .read(adminControllerProvider.notifier)
            .delete(kind, id);
        if (!context.mounted) return;
        if (ok) {
          context.go('/$kind');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                friendlyError(ref.read(adminControllerProvider).error!),
              ),
            ),
          );
        }
      },
      itemBuilder: (_) => [
        if (allowEdit)
          const PopupMenuItem(
            value: 'edit',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.edit_outlined),
              title: Text('Edit details'),
            ),
          ),
        const PopupMenuItem(
          value: 'delete',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.delete_outline),
            title: Text('Delete'),
          ),
        ),
      ],
    );
  }
}
