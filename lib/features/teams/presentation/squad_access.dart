import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/async_panel.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../providers/team_providers.dart';
import '../providers/team_access.dart';

class SquadAccess extends ConsumerWidget {
  const SquadAccess({super.key, required this.teamId, required this.child});
  final String teamId;
  final Widget child;
  @override
  Widget build(BuildContext context, WidgetRef ref) => AsyncPanel(
    value: ref.watch(teamProvider(teamId)),
    retry: () => ref.invalidate(teamProvider(teamId)),
    data: (team) => ref.watch(canManageSquadProvider(teamId)) && team != null
        ? child
        : AppScaffold(
            title: 'Team squad',
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    team == null
                        ? 'Team no longer exists.'
                        : 'Only this team’s creator and admins can manage its squad.',
                  ),
                  TextButton(
                    onPressed: () => context.go('/teams/$teamId'),
                    child: const Text('Back to team'),
                  ),
                ],
              ),
            ),
          ),
  );
}
