import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/firebase_providers.dart';
import 'core/widgets/async_panel.dart';
import 'features/auth/providers/auth_providers.dart';

class CricketApp extends ConsumerWidget {
  const CricketApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ready = ref.watch(firebaseReadyProvider);
    return MaterialApp.router(
      title: 'Gully Cricket',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: ref.watch(appRouterProvider),
      builder: (context, child) => AsyncPanel(
        value: ready,
        retry: () => ref.invalidate(firebaseReadyProvider),
        data: (configured) => configured
            ? AsyncPanel(
                value: ref.watch(currentUserProvider),
                retry: () => ref.invalidate(appUserStreamProvider),
                data: (_) => child!,
              )
            : const Scaffold(
                body: Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'Gully Cricket\n\nConnect your Firebase project to start.\nSee README.md for configuration and local emulator setup.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
