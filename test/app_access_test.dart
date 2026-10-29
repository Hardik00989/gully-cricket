import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gully_crickett/app.dart';
import 'package:gully_crickett/core/router/app_router.dart';
import 'package:gully_crickett/core/utils/firebase_providers.dart';
import 'package:gully_crickett/features/auth/domain/app_user.dart';
import 'package:gully_crickett/features/auth/providers/auth_providers.dart';
import 'package:gully_crickett/features/matches/providers/match_providers.dart';
import 'package:gully_crickett/features/admin/providers/admin_providers.dart';

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);
  testWidgets(
    'guest can browse and cannot enter admin routes or see admin drawer entries',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          firebaseReadyProvider.overrideWith((ref) async => true),
          appUserStreamProvider.overrideWith((ref) => Stream.value(null)),
          matchesProvider.overrideWith((ref) => Stream.value([])),
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
      expect(find.text('Every ball. Every run.'), findsOneWidget);
      container.read(appRouterProvider).go('/admin/users');
      await tester.pumpAndSettle();
      expect(
        container
            .read(appRouterProvider)
            .routeInformationProvider
            .value
            .uri
            .path,
        '/',
      );
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();
      expect(find.text('Manage Users'), findsNothing);
      expect(find.text('Create Match'), findsNothing);
      expect(find.text('Tournaments'), findsWidgets);
    },
  );
  testWidgets(
    'management access persists for user roles and is revoked on sign out',
    (tester) async {
      final profiles = StreamController<AppUser?>();
      addTearDown(profiles.close);
      final container = ProviderContainer(
        overrides: [
          firebaseReadyProvider.overrideWith((ref) async => true),
          appUserStreamProvider.overrideWith((ref) => profiles.stream),
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
      await tester.pump();
      profiles.add(
        const AppUser(
          uid: 'admin',
          name: 'Admin',
          email: 'admin@test.local',
          role: 'admin',
        ),
      );
      await tester.pumpAndSettle();
      container.read(appRouterProvider).go('/admin/users');
      await tester.pumpAndSettle();
      expect(find.text('Manage users'), findsOneWidget);
      profiles.add(
        const AppUser(
          uid: 'admin',
          name: 'Admin',
          email: 'admin@test.local',
          role: 'user',
        ),
      );
      await tester.pumpAndSettle();
      expect(container.read(isAdminProvider), false);
      expect(container.read(managementAccessProvider), true);
      expect(find.text('Manage users'), findsOneWidget);
      profiles.add(null);
      await tester.pumpAndSettle();
      expect(
        container
            .read(appRouterProvider)
            .routeInformationProvider
            .value
            .uri
            .path,
        '/',
      );
      expect(find.text('Manage users'), findsNothing);
    },
  );
  testWidgets('unconfigured app displays actionable setup instructions', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseReadyProvider.overrideWith((ref) async => false),
          appUserStreamProvider.overrideWith((ref) => Stream.value(null)),
        ],
        child: const CricketApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Connect your Firebase project'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
