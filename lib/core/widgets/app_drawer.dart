import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../utils/friendly_error.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).asData?.value;
    Widget entry(String label, String path, IconData icon) => ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.pop(context);
        context.go(path);
      },
    );
    return Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            Container(
              color: AppColors.primaryDark,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GULLY CRICKET',
                    style: AppText.team.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user?.name.isNotEmpty == true
                        ? user!.name
                        : 'Welcome to the ground',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.white),
                  ),
                  Text(
                    user == null
                        ? 'Watch every ball as a guest'
                        : 'Your cricket, all in one place',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            if (ref.watch(managementAccessProvider))
              entry(
                'Manage Users',
                '/admin/users',
                Icons.manage_accounts_outlined,
              ),
            entry('About', '/about', Icons.info_outline),
            if (user == null)
              entry('Login', '/login', Icons.login)
            else
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () async {
                  await ref.read(authControllerProvider.notifier).logout();
                  if (!context.mounted) return;
                  final error = ref.read(authControllerProvider).error;
                  if (error != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(friendlyError(error))),
                    );
                  } else {
                    Navigator.pop(context);
                    context.go('/');
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}
