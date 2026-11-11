import '../../../core/utils/friendly_error.dart';
import 'entity_form_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/firestore_values.dart';
import '../../auth/providers/auth_providers.dart';
import '../../teams/domain/team.dart';
import '../../tournaments/domain/tournament.dart';
import '../providers/admin_providers.dart';
import 'editor_fields.dart';

class EntityEditor extends ConsumerStatefulWidget {
  const EntityEditor({
    super.key,
    required this.kind,
    required this.id,
    required this.initial,
    required this.tournaments,
    required this.teams,
    this.teamId,
    this.tournamentId,
  });
  final String kind, id;
  final String? teamId, tournamentId;
  final Map<String, dynamic> initial;
  final List<Tournament> tournaments;
  final List<Team> teams;
  @override
  ConsumerState<EntityEditor> createState() => _EntityEditorState();
}

class _EntityEditorState extends ConsumerState<EntityEditor> {
  final form = GlobalKey<FormState>();
  late Map<String, dynamic> values;
  String? validationError;
  @override
  void initState() {
    super.initState();
    values = {...widget.initial};
    for (final key in ['startDate', 'endDate', 'scheduledAt']) {
      values[key] = values[key] == null
          ? DateTime.now()
          : readDate(values[key]);
    }
    for (final key in ['startDate', 'endDate']) {
      final date = values[key] as DateTime;
      values[key] = DateTime(date.year, date.month, date.day);
    }
    values['teamIds'] = List<String>.from(values['teamIds'] as List? ?? []);
    values['tournamentIds'] = List<String>.from(
      values['tournamentIds'] as List? ?? [],
    );
    if (widget.id == 'new' && widget.tournamentId != null) {
      values['tournamentId'] = widget.tournamentId;
      if (widget.kind == 'teams') {
        values['tournamentIds'] = [widget.tournamentId!];
      }
    }
    values.putIfAbsent('logoUrl', () => '');
    values.putIfAbsent('shortName', () => '');
    final tournament = widget.tournaments
        .where((t) => t.id == values['tournamentId'])
        .firstOrNull;
    values.putIfAbsent('overs', () => tournament?.format == 'T10' ? 10 : 20);
    values.putIfAbsent('jerseyNo', () => 1);
    values.putIfAbsent('format', () => 'T20');
    values.putIfAbsent('status', () => 'upcoming');
    values.putIfAbsent('role', () => 'batter');
    final toss = Map<String, dynamic>.from(values['toss'] as Map? ?? {});
    values['tossWinner'] = toss['winnerTeamId'];
    values['tossDecision'] = toss['decision'] ?? 'bat';
  }

  @override
  Widget build(BuildContext context) {
    final action = ref.watch(adminControllerProvider);
    if (widget.kind == 'matches' && values['status'] != 'upcoming') {
      return const Center(
        child: Text('This match has started. Use live scoring to manage it.'),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EditorFields(
              canManage: ref.watch(managementAccessProvider),
              kind: widget.kind,
              values: values,
              teams: widget.teams,
              tournaments: widget.tournaments,
              onChanged: () => setState(() {}),
            ),
            if (validationError != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  validationError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (action.hasError)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  friendlyError(action.error!),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: action.isLoading ? null : _save,
              child: Text(
                action.isLoading
                    ? 'Saving...'
                    : 'Save ${widget.kind == 'matches' ? 'match' : widget.kind.substring(0, widget.kind.length - 1)}',
              ),
            ),
            if (widget.kind == 'players' &&
                widget.id != 'new' &&
                ref.watch(managementAccessProvider))
              TextButton.icon(
                onPressed: action.isLoading ? null : _removePlayer,
                icon: const Icon(Icons.person_remove_outlined),
                label: const Text('Remove from squad'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _removePlayer() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${values['name']}?'),
        content: const Text('This player will be removed from the squad.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await ref
        .read(adminControllerProvider.notifier)
        .delete('players', widget.id, teamId: widget.teamId);
    if (ok && mounted) {
      context.canPop() ? context.pop() : context.go('/teams/${widget.teamId}');
    }
  }

  Future<void> _save() async {
    if (!form.currentState!.validate()) return;
    form.currentState!.save();
    late Map<String, dynamic> data;
    try {
      data = entityFormData(widget.kind, values, widget.teams);
      setState(() => validationError = null);
    } on ArgumentError catch (error) {
      setState(() => validationError = error.message.toString());
      return;
    }
    if (widget.id == 'new') {
      data['createdBy'] = ref.read(currentUserProvider).requireValue!.uid;
      if (widget.kind == 'tournaments' && !ref.read(managementAccessProvider)) {
        data['status'] = 'upcoming';
      }
    }
    final ok = await ref
        .read(adminControllerProvider.notifier)
        .save(
          widget.kind,
          widget.id == 'new' ? null : widget.id,
          data,
          teamId: widget.teamId,
        );
    if (ok && mounted) {
      final savedId = ref.read(adminControllerProvider.notifier).savedId;
      if (widget.id == 'new' && savedId != null) {
        context.replace('/${widget.kind}/$savedId');
        return;
      }

      if (context.canPop()) {
        context.pop();
      } else {
        context.go(
          widget.kind == 'players'
              ? '/teams/${widget.teamId}'
              : '/${widget.kind}',
        );
      }
    }
  }
}
