import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_drawer.dart';
import 'app_navigation.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
  });
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  String fallback(String path) {
    if (path.contains('/scoring/')) return '/matches/${path.split('/').last}';
    if (path.contains('/teams') || path.contains('/players')) return '/teams';
    if (path.contains('/tournaments')) return '/tournaments';
    if (path.contains('/matches') || path.contains('/scoring')) {
      return '/matches';
    }
    return '/';
  }

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final primary = mainDestinations.any((d) => d.$1 == path);
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actions,
        leading: primary
            ? null
            : BackButton(
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(fallback(path));
                  }
                },
              ),
      ),
      drawer: primary ? const AppDrawer() : null,
      bottomNavigationBar: primary ? AppNavigation(path: path) : null,
      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: body,
          ),
        ),
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}
