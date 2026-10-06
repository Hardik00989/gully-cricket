import '../../../core/utils/friendly_error.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      email = TextEditingController(),
      password = TextEditingController();
  bool register = false;
  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final action = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(register ? 'Join Gully Cricket' : 'Welcome back'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Local cricket. Live from the ground.',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  if (register) ...[
                    TextFormField(
                      controller: name,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Enter your name'
                          : null,
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (v) => v == null || !v.contains('@')
                        ? 'Enter a valid email'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: password,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                    validator: (v) => v == null || v.length < 6
                        ? 'Use at least 6 characters'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  if (action.hasError)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        friendlyError(action.error!),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  FilledButton(
                    onPressed: action.isLoading
                        ? null
                        : () async {
                            if (!form.currentState!.validate()) return;
                            final ok = await ref
                                .read(authControllerProvider.notifier)
                                .submit(
                                  email: email.text,
                                  password: password.text,
                                  name: register ? name.text : null,
                                );
                            if (ok && context.mounted) context.go('/');
                          },
                    child: Text(
                      action.isLoading
                          ? 'Please wait…'
                          : register
                          ? 'Create account'
                          : 'Login',
                    ),
                  ),
                  TextButton(
                    onPressed: action.isLoading
                        ? null
                        : () => setState(() => register = !register),
                    child: Text(
                      register
                          ? 'Already registered? Login'
                          : 'Create an account',
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/'),
                    child: const Text('Continue as guest'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
