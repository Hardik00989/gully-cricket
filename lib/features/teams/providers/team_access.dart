import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_providers.dart';
import 'team_providers.dart';

final canManageSquadProvider = Provider.autoDispose.family<bool, String>((
  ref,
  teamId,
) {
  if (ref.watch(managementAccessProvider)) return true;
  final uid = ref.watch(currentUserProvider).asData?.value?.uid;
  final team = ref.watch(teamProvider(teamId)).asData?.value;
  return uid != null && team?.data['createdBy'] == uid;
});
