import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_notifier.dart';
import '../providers/inventory_notifier.dart';
import '../providers/settings_notifier.dart';
import 'app_shell.dart';
import '../theme/app_theme.dart';

class BootstrapGate extends StatefulWidget {
  const BootstrapGate({super.key});

  @override
  State<BootstrapGate> createState() => _BootstrapGateState();
}

class _BootstrapGateState extends State<BootstrapGate> {
  Future<void>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _bootstrap();
  }

  Future<void> _bootstrap() async {
    final auth = context.read<AuthNotifier>();
    final inv = context.read<InventoryNotifier>();
    final settings = context.read<SettingsNotifier>();

    // Start listening to auth state ASAP.
    unawaited(auth.load());

    // Don't block first frame forever: give bootstrap operations a timeout.
    await Future.wait([
      settings.load(),
      inv.load(),
    ]).timeout(const Duration(seconds: 12));
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsNotifier>();
    context.watch<AuthNotifier>();

    return MaterialApp(
      title: 'Burj Al Qairan',
      debugShowCheckedModeBanner: false,
      themeMode: settings.themeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: FutureBuilder<void>(
        future: _future,
        builder: (ctx, snap) {
          if (snap.hasError) {
            return _BootstrapError(
              error: snap.error,
              onRetry: () => setState(() => _future = _bootstrap()),
            );
          }
          if (snap.connectionState != ConnectionState.done) {
            return const _BootstrapLoading();
          }
          // Guest mode: app works without login. Admin can sign in from Settings.
          return const AppShell();
        },
      ),
    );
  }
}

class _BootstrapLoading extends StatelessWidget {
  const _BootstrapLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _BootstrapError extends StatelessWidget {
  const _BootstrapError({
    required this.error,
    required this.onRetry,
  });

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Startup error')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'App could not finish startup.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SelectableText(error?.toString() ?? 'Unknown error'),
            const Spacer(),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

