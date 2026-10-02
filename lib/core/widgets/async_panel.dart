import '../utils/friendly_error.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AsyncPanel<T> extends StatelessWidget {
  const AsyncPanel({
    super.key,
    required this.value,
    required this.retry,
    required this.data,
  });
  final AsyncValue<T> value;
  final VoidCallback retry;
  final Widget Function(T) data;
  @override
  Widget build(BuildContext context) => value.when(
    data: data,
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (error, _) => Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Could not load this content.'),
            const SizedBox(height: 8),
            Text(friendlyError(error), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: retry, child: const Text('Retry')),
          ],
        ),
      ),
    ),
  );
}
