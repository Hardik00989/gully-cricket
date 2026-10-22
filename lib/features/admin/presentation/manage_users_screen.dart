import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/async_panel.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/admin_providers.dart';

class ManageUsersScreen extends ConsumerWidget {
  const ManageUsersScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => AppScaffold(
    title: 'Manage users',
    body: AsyncPanel(
      value: ref.watch(usersProvider),
      retry: () => ref.invalidate(usersProvider),
      data: (users) => users.isEmpty
          ? const Center(child: Text('No registered users.'))
          : ListView.separated(
              itemCount: users.length,
              separatorBuilder: (_, _) => const Divider(),
              itemBuilder: (_, index) {
                final u = users[index];
                final self =
                    ref.watch(currentUserProvider).asData?.value?.uid == u.uid;
                return ListTile(
                  title: Text(u.name),
                  subtitle: Text(u.email),
                  trailing: DropdownButton<String>(
                    value: u.role,
                    items: ['user', 'admin']
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged:
                        self || ref.watch(adminControllerProvider).isLoading
                        ? null
                        : (role) async {
                            if (role == null || role == u.role) return;
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Make ${u.name} an $role?'),
                                content: const Text(
                                  'Admins can edit tournaments, score matches and manage other users.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Confirm'),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed != true) return;
                            final ok = await ref
                                .read(adminControllerProvider.notifier)
                                .role(u.uid, role);
                            if (!ok && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    ref
                                        .read(adminControllerProvider)
                                        .error
                                        .toString(),
                                  ),
                                ),
                              );
                            }
                          },
                  ),
                );
              },
            ),
    ),
  );
}
