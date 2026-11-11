import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gully_crickett/app.dart';
import 'package:gully_crickett/core/router/app_router.dart';
import 'package:gully_crickett/core/utils/firebase_providers.dart';
import 'package:gully_crickett/features/auth/domain/app_user.dart';
import 'package:gully_crickett/features/auth/providers/auth_providers.dart';
import 'package:gully_crickett/features/matches/providers/match_providers.dart';
import 'package:gully_crickett/features/teams/domain/team.dart';
import 'package:gully_crickett/features/teams/providers/team_providers.dart';
import 'package:gully_crickett/features/players/domain/player.dart';
import 'package:gully_crickett/features/players/data/player_repository.dart';
import 'package:gully_crickett/features/players/providers/player_providers.dart';
import 'package:gully_crickett/features/tournaments/providers/tournament_providers.dart';

class UnusedFirestore extends Fake implements FirebaseFirestore {}

class RecordingPlayers extends PlayerRepository {
  RecordingPlayers() : super(UnusedFirestore());
  final saves = <(String, String?, Map<String, dynamic>)>[];
  @override
  Future<void> save(
    String teamId,
    String? id,
    Map<String, dynamic> data,
  ) async {
    saves.add((teamId, id, data));
  }
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);
  ProviderContainer setup({bool guest = false, RecordingPlayers? repository}) =>
      ProviderContainer(
        overrides: [
          firebaseReadyProvider.overrideWith((ref) async => true),
          appUserStreamProvider.overrideWith(
            (ref) => Stream.value(
              guest
                  ? null
                  : const AppUser(
                      uid: 'owner',
                      name: 'Owner',
                      email: 'owner@test.local',
                      role: 'user',
                    ),
            ),
          ),
          matchesProvider.overrideWith((ref) => Stream.value([])),
          teamsProvider.overrideWith((ref) => Stream.value([])),
          tournamentsProvider.overrideWith((ref) => Stream.value([])),
          teamProvider.overrideWith(
            (ref, id) => Stream.value(
              Team(id, {
                'name': 'Team $id',
                'createdBy': id == 'own' ? 'owner' : 'someone-else',
              }),
            ),
          ),
          playersProvider.overrideWith(
            (ref, id) => Stream.value([
              const Player('p1', {
                'name': 'Existing player',
                'role': 'bowler',
                'jerseyNo': 9,
              }),
            ]),
          ),
          if (repository != null)
            playerRepositoryProvider.overrideWithValue(repository),
        ],
      );
  testWidgets(
    'regular user can add and edit players with temporary management access',
    (tester) async {
      final repository = RecordingPlayers();
      final container = setup(repository: repository);
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const CricketApp(),
        ),
      );
      await tester.pumpAndSettle();
      final router = container.read(appRouterProvider);
      router.go('/teams/own');
      await tester.pumpAndSettle();
      expect(find.text('Manage squad'), findsNothing);
      await tester.tap(find.text('Add player'));
      await tester.pumpAndSettle();
      expect(find.text('Create player'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).first, 'New teammate');
      await tester.ensureVisible(find.text('Save player'));
      await tester.tap(find.text('Save player'));
      await tester.pumpAndSettle();
      expect(repository.saves.length, 1);
      expect(repository.saves.first.$1, 'own');
      expect(repository.saves.first.$2, isNull);
      expect(repository.saves.first.$3['name'], 'New teammate');
      expect(repository.saves.first.$3['createdBy'], 'owner');
      await tester.tap(find.text('Existing player'));
      await tester.pumpAndSettle();
      expect(find.text('Edit player'), findsOneWidget);
      expect(find.text('Remove from squad'), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField).first,
        'Updated teammate',
      );
      await tester.ensureVisible(find.text('Save player'));
      await tester.tap(find.text('Save player'));
      await tester.pumpAndSettle();
      expect(repository.saves.length, 2);
      expect(repository.saves.last.$2, 'p1');
      expect(repository.saves.last.$3.containsKey('createdBy'), false);
    },
  );
  testWidgets('temporary management access includes other teams squads', (
    tester,
  ) async {
    final container = setup();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const CricketApp(),
      ),
    );
    await tester.pumpAndSettle();
    final router = container.read(appRouterProvider);
    router.go('/teams/other');
    await tester.pumpAndSettle();
    expect(find.text('Add player'), findsOneWidget);
    for (final path in ['/teams/other/squad/new', '/teams/other/squad/p1']) {
      router.go(path);
      await tester.pumpAndSettle();
      expect(find.textContaining('Only this team'), findsNothing);
      expect(find.text('Save player'), findsOneWidget);
    }
  });
  testWidgets('guest squad management links redirect to login', (tester) async {
    final container = setup(guest: true);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const CricketApp(),
      ),
    );
    await tester.pumpAndSettle();
    container.read(appRouterProvider).go('/teams/own/squad/new');
    await tester.pumpAndSettle();
    expect(
      container.read(appRouterProvider).routeInformationProvider.value.uri.path,
      '/login',
    );
  });
}
