import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/matches/presentation/home_screen.dart';
import '../../features/matches/presentation/matches_screen.dart';
import '../../features/matches/presentation/match_detail_screen.dart';
import '../../features/teams/presentation/teams_screen.dart';
import '../../features/teams/presentation/team_detail_screen.dart';
import '../../features/tournaments/presentation/tournaments_screen.dart';
import '../../features/tournaments/presentation/tournament_detail_screen.dart';
import '../../features/standings/presentation/standings_screen.dart';
import '../widgets/app_scaffold.dart';
import '../../features/admin/presentation/admin_list_screen.dart';
import '../../features/admin/presentation/entity_form_screen.dart';
import '../../features/admin/presentation/manage_users_screen.dart';
import '../../features/scoring/presentation/scoring_screen.dart';
import '../../features/teams/presentation/squad_access.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    redirect: (context, state) {
      if ((state.uri.path.startsWith('/create/') ||
              state.uri.path.contains('/squad')) &&
          !ref.read(isSignedInProvider)) {
        return '/login';
      }
      if (state.uri.path.startsWith('/admin') &&
          !ref.read(managementAccessProvider)) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/teams/:teamId/squad',
        builder: (_, s) {
          final id = s.pathParameters['teamId']!;
          return SquadAccess(
            teamId: id,
            child: AdminListScreen(
              kind: 'players',
              teamId: id,
              basePath: '/teams/$id/squad',
            ),
          );
        },
      ),
      GoRoute(
        path: '/teams/:teamId/squad/:id',
        builder: (_, s) => SquadAccess(
          teamId: s.pathParameters['teamId']!,
          child: EntityFormScreen(
            kind: 'players',
            id: s.pathParameters['id']!,
            teamId: s.pathParameters['teamId']!,
          ),
        ),
      ),
      for (final kind in ['tournaments', 'teams', 'matches'])
        GoRoute(
          path: '/create/$kind',
          builder: (_, s) => EntityFormScreen(
            kind: kind,
            id: 'new',
            tournamentId: s.uri.queryParameters['tournamentId'],
          ),
        ),
      GoRoute(path: '/admin/scoring', builder: (_, _) => const ScoringScreen()),
      GoRoute(
        path: '/admin/scoring/:id',
        builder: (_, s) => ScoringScreen(id: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/admin/users',
        builder: (_, _) => const ManageUsersScreen(),
      ),
      GoRoute(
        path: '/admin/teams/:teamId/players',
        builder: (_, s) => AdminListScreen(
          kind: 'players',
          teamId: s.pathParameters['teamId']!,
        ),
      ),
      GoRoute(
        path: '/admin/teams/:teamId/players/:id',
        builder: (_, s) => EntityFormScreen(
          kind: 'players',
          id: s.pathParameters['id']!,
          teamId: s.pathParameters['teamId']!,
        ),
      ),
      for (final kind in ['tournaments', 'teams', 'matches']) ...[
        GoRoute(
          path: '/admin/$kind',
          builder: (_, _) => AdminListScreen(kind: kind),
        ),
        GoRoute(
          path: '/admin/$kind/:id',
          builder: (_, s) =>
              EntityFormScreen(kind: kind, id: s.pathParameters['id']!),
        ),
      ],
      GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: '/matches',
        builder: (_, s) => MatchesScreen(
          key: ValueKey(s.uri.toString()),
          initialTab: int.tryParse(s.uri.queryParameters['tab'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        path: '/matches/:id',
        builder: (_, s) => MatchDetailScreen(id: s.pathParameters['id']!),
      ),
      GoRoute(path: '/teams', builder: (_, _) => const TeamsScreen()),
      GoRoute(
        path: '/teams/:id',
        builder: (_, s) => TeamDetailScreen(id: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/tournaments',
        builder: (_, _) => const TournamentsScreen(),
      ),
      GoRoute(
        path: '/tournaments/:id',
        builder: (_, s) => TournamentDetailScreen(id: s.pathParameters['id']!),
      ),
      GoRoute(path: '/standings', builder: (_, _) => const StandingsScreen()),
      GoRoute(
        path: '/about',
        builder: (_, _) => const AppScaffold(
          title: 'About Gully Cricket',
          body: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Local cricket. Live from the ground.\n\nFollow tournaments, squads and every delivery as it happens. Guests can browse freely. Tournament administrators manage fixtures and scoring.',
            ),
          ),
        ),
      ),
    ],
  );
  ref.listen(managementAccessProvider, (_, _) => router.refresh());
  ref.listen(isSignedInProvider, (_, _) => router.refresh());
  ref.onDispose(router.dispose);
  return router;
});
