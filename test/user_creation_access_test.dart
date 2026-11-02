import 'package:gully_crickett/features/admin/providers/admin_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gully_crickett/app.dart';
import 'package:gully_crickett/core/router/app_router.dart';
import 'package:gully_crickett/core/utils/firebase_providers.dart';
import 'package:gully_crickett/features/auth/domain/app_user.dart';
import 'package:gully_crickett/features/auth/providers/auth_providers.dart';
import 'package:gully_crickett/features/matches/providers/match_providers.dart';
import 'package:gully_crickett/features/teams/providers/team_providers.dart';
import 'package:gully_crickett/features/teams/domain/team.dart';
import 'package:gully_crickett/features/tournaments/providers/tournament_providers.dart';
import 'package:gully_crickett/features/tournaments/domain/tournament.dart';

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);
  testWidgets('ordinary user can open creation forms and management routes', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        firebaseReadyProvider.overrideWith((ref) async => true),
        appUserStreamProvider.overrideWith(
          (ref) => Stream.value(
            const AppUser(
              uid: 'viewer',
              name: 'Viewer',
              email: 'viewer@test.local',
              role: 'user',
            ),
          ),
        ),
        matchesProvider.overrideWith((ref) => Stream.value([])),
        usersProvider.overrideWith((ref) => Stream.value([])),
        teamsProvider.overrideWith(
          (ref) => Stream.value([
            const Team('a', {
              'name': 'Home XI',
              'shortName': 'HMX',
              'tournamentIds': [],
            }),
            const Team('b', {
              'name': 'Away XI',
              'shortName': 'AWX',
              'tournamentIds': [],
            }),
          ]),
        ),
        tournamentsProvider.overrideWith(
          (ref) => Stream.value([
            const Tournament('own', {
              'name': 'My Cup',
              'createdBy': 'viewer',
              'teamIds': ['a', 'b'],
            }),
            const Tournament('other', {
              'name': 'Other Cup',
              'createdBy': 'another',
              'teamIds': ['a', 'b'],
            }),
          ]),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const CricketApp(),
      ),
    );
    await tester.pumpAndSettle();
    final router = container.read(appRouterProvider);
    router.go('/create/tournaments');
    await tester.pumpAndSettle();
    expect(find.text('Create tournament'), findsOneWidget);
    expect(find.text('Participating teams'), findsOneWidget);
    expect(find.text('Home XI'), findsOneWidget);
    expect(find.text('Status'), findsNothing);
    await tester.tap(find.text('Dates & other details'));
    await tester.pumpAndSettle();
    expect(find.text('Status'), findsOneWidget);
    router.go('/create/teams');
    await tester.pumpAndSettle();
    expect(find.text('Create team'), findsOneWidget);
    expect(find.text('My Cup'), findsNothing);
    await tester.tap(find.text('Tournament & logo'));
    await tester.pumpAndSettle();
    expect(find.text('My Cup'), findsOneWidget);
    expect(find.text('Other Cup'), findsOneWidget);
    router.go('/create/matches');
    await tester.pumpAndSettle();
    expect(find.text('Create match'), findsOneWidget);
    router.go('/admin/users');
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/admin/users');
    expect(find.text('Manage users'), findsOneWidget);
    router.go('/');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Manage Users'),
      200,
      scrollable: find.descendant(
        of: find.byType(Drawer),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Manage Users'), findsOneWidget);
  });
  testWidgets('guest must sign in before using creation routes', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        firebaseReadyProvider.overrideWith((ref) async => true),
        appUserStreamProvider.overrideWith((ref) => Stream.value(null)),
        matchesProvider.overrideWith((ref) => Stream.value([])),
        usersProvider.overrideWith((ref) => Stream.value([])),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const CricketApp(),
      ),
    );
    await tester.pumpAndSettle();
    for (final kind in ['tournaments', 'teams', 'matches']) {
      container.read(appRouterProvider).go('/create/$kind');
      await tester.pumpAndSettle();
      expect(
        container
            .read(appRouterProvider)
            .routeInformationProvider
            .value
            .uri
            .path,
        '/login',
      );
    }
  });
}
