import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gully_crickett/app.dart';
import 'package:gully_crickett/core/router/app_router.dart';
import 'package:gully_crickett/core/utils/firebase_providers.dart';
import 'package:gully_crickett/features/auth/domain/app_user.dart';
import 'package:gully_crickett/features/auth/providers/auth_providers.dart';
import 'package:gully_crickett/features/matches/providers/match_providers.dart';
import 'package:gully_crickett/features/teams/domain/team.dart';
import 'package:gully_crickett/features/teams/data/team_repository.dart';
import 'package:gully_crickett/features/teams/providers/team_providers.dart';
import 'package:gully_crickett/features/tournaments/domain/tournament.dart';
import 'package:gully_crickett/features/tournaments/data/tournament_repository.dart';
import 'package:gully_crickett/features/tournaments/providers/tournament_providers.dart';
import 'package:gully_crickett/features/players/providers/player_providers.dart';

class SetupFirestore extends Fake implements FirebaseFirestore {}

class SetupTeams extends TeamRepository {
  SetupTeams() : super(SetupFirestore());
  Map<String, dynamic>? saved;
  @override
  Future<String> save(String? id, Map<String, dynamic> data) async {
    saved = data;
    return 'new-team';
  }
}

class SetupTournaments extends TournamentRepository {
  SetupTournaments() : super(SetupFirestore());
  Map<String, dynamic>? saved;
  @override
  Future<String> save(String? id, Map<String, dynamic> data) async {
    saved = data;
    return 'new-cup';
  }
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);
  ProviderContainer setup(SetupTeams teams, SetupTournaments tournaments) =>
      ProviderContainer(
        overrides: [
          firebaseReadyProvider.overrideWith((ref) async => true),
          appUserStreamProvider.overrideWith(
            (ref) => Stream.value(
              const AppUser(
                uid: 'member',
                name: 'Member',
                email: 'member@test.local',
                role: 'user',
              ),
            ),
          ),
          matchesProvider.overrideWith((ref) => Stream.value([])),
          teamsProvider.overrideWith((ref) => Stream.value([])),
          tournamentsProvider.overrideWith(
            (ref) => Stream.value([
              const Tournament('new-cup', {
                'name': 'Community Cup',
                'createdBy': 'member',
                'teamIds': [],
              }),
            ]),
          ),
          teamProvider.overrideWith(
            (ref, id) => Stream.value(
              Team(id, {'name': 'Street XI', 'createdBy': 'member'}),
            ),
          ),
          tournamentProvider.overrideWith(
            (ref, id) => Stream.value(
              Tournament(id, {'name': 'Community Cup', 'teamIds': []}),
            ),
          ),
          playersProvider.overrideWith((ref, id) => Stream.value([])),
          teamRepositoryProvider.overrideWithValue(teams),
          tournamentRepositoryProvider.overrideWithValue(tournaments),
        ],
      );
  testWidgets('new tournament opens its page with clear next steps', (
    tester,
  ) async {
    final teams = SetupTeams(), tournaments = SetupTournaments();
    final container = setup(teams, tournaments);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const CricketApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Set up your first match'), findsOneWidget);
    await tester.tap(find.text('Create a tournament'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Community Cup');
    await tester.enterText(find.byType(TextFormField).at(1), 'Local Ground');
    await tester.ensureVisible(find.text('Save tournament'));
    await tester.tap(find.text('Save tournament'));
    await tester.pumpAndSettle();
    expect(find.text('Community Cup'), findsOneWidget);
    expect(find.text('Add team'), findsOneWidget);
    expect(find.text('Schedule match'), findsOneWidget);
    expect((tournaments.saved!['startDate'] as DateTime).hour, 0);
    expect(tournaments.saved!['createdBy'], 'member');
  });
  testWidgets(
    'adding a team from a tournament preselects it and opens squad setup',
    (tester) async {
      final teams = SetupTeams(), tournaments = SetupTournaments();
      final container = setup(teams, tournaments);
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const CricketApp(),
        ),
      );
      await tester.pumpAndSettle();
      container
          .read(appRouterProvider)
          .go('/create/teams?tournamentId=new-cup');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'Street XI');
      await tester.ensureVisible(find.text('Save team'));
      await tester.tap(find.text('Save team'));
      await tester.pumpAndSettle();
      expect(teams.saved!['shortName'], 'SX');
      expect(teams.saved!['tournamentIds'], ['new-cup']);
      expect(
        container
            .read(appRouterProvider)
            .routeInformationProvider
            .value
            .uri
            .path,
        '/teams/new-team',
      );
      expect(find.text('Add player'), findsOneWidget);
      await tester.tap(find.text('Add player'));
      await tester.pumpAndSettle();
      expect(find.text('Create player'), findsOneWidget);
    },
  );
  testWidgets('bottom navigation works on a narrow screen with enlarged text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 850);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final container = setup(SetupTeams(), SetupTournaments());
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const CricketApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byType(NavigationDestination).at(2));
    await tester.pumpAndSettle();
    expect(
      container.read(appRouterProvider).routeInformationProvider.value.uri.path,
      '/teams',
    );
    expect(find.text('Add team'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
