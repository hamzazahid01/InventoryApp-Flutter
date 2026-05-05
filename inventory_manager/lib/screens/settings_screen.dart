import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../constants/currencies.dart';
import '../providers/auth_notifier.dart';
import '../providers/inventory_notifier.dart';
import '../providers/settings_notifier.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _thresholdCtrl = TextEditingController();
  bool _thresholdSeeded = false;
  String _deleteRange = 'today'; // today | week | year | total

  @override
  void dispose() {
    _thresholdCtrl.dispose();
    super.dispose();
  }

  Future<void> _showDeleteDataDialog(BuildContext context) async {
    final inv = context.read<InventoryNotifier>();

    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Delete data'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _deleteRange,
                decoration: const InputDecoration(
                  labelText: 'How much to delete',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'today',
                    child: Text('Today (sales history)'),
                  ),
                  DropdownMenuItem(
                    value: 'week',
                    child: Text('Last 7 days (sales history)'),
                  ),
                  DropdownMenuItem(
                    value: 'year',
                    child: Text('Last 1 year (sales history)'),
                  ),
                  DropdownMenuItem(
                    value: 'total',
                    child: Text('Total'),
                  ),
                ],
                onChanged: (v) => setLocal(() => _deleteRange = v ?? 'today'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error,
                foregroundColor: Theme.of(ctx).colorScheme.onError,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
    if (proceed != true || !context.mounted) return;

    // Second confirmation (required).
    final ok2 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm delete'),
        content: Text(
          _deleteRange == 'total'
              ? 'Are you sure you want to permanently delete ALL data (products + sales)?'
              : 'Are you sure you want to permanently delete this sales data?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok2 != true || !context.mounted) return;

    try {
      if (_deleteRange == 'today') {
        await inv.deleteSalesToday();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Today sales deleted')),
        );
      } else if (_deleteRange == 'week') {
        await inv.deleteSalesLastWeek();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Last 7 days sales deleted')),
        );
      } else if (_deleteRange == 'year') {
        await inv.deleteSalesLastYear();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Last year sales deleted')),
        );
      } else {
        await inv.resetAllData();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All data deleted')),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_thresholdSeeded) {
      final t = context.read<SettingsNotifier>().lowStockThreshold;
      _thresholdCtrl.text = '$t';
      _thresholdSeeded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsNotifier>();
    final auth = context.watch<AuthNotifier>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Card(
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    'AD',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        auth.isAdmin
                            ? 'Admin'
                            : (auth.isSignedIn ? 'User' : 'Guest'),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        auth.isSignedIn
                            ? 'Inventory control · Store operations'
                            : 'Read-only access (no sign-in)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.65),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: auth.isSignedIn
              ? ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Sign out'),
                  subtitle: Text(auth.user?.email ?? ''),
                  onTap: () async => context.read<AuthNotifier>().signOut(),
                )
              : ListTile(
                  leading: const Icon(Icons.admin_panel_settings_outlined),
                  title: const Text('Admin login'),
                  subtitle: const Text('Unlock add/edit/delete/reset'),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                ),
        ),
        const SizedBox(height: 16),
        Text(
          'Appearance',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          value: settings.darkMode,
          onChanged: (v) => context.read<SettingsNotifier>().setDarkMode(v),
          title: const Text('Dark mode'),
          secondary: Icon(
            settings.darkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Regional',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.currency_exchange),
            title: const Text('Currency'),
            subtitle: const Text('Used across pricing and reports'),
            trailing: DropdownButton<String>(
              value: kSupportedCurrencyCodes.contains(settings.currencyCode)
                  ? settings.currencyCode
                  : kDefaultCurrencyCode,
              items: kSupportedCurrencyCodes
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text(currencyOptionLabel(c)),
                    ),
                  )
                  .toList(),
              onChanged: (c) {
                if (c != null) {
                  context.read<SettingsNotifier>().setCurrencyCode(c);
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Inventory rules',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Low stock threshold',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _thresholdCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    hintText: 'e.g. 10',
                  ),
                  onSubmitted: (v) {
                    final n = int.tryParse(v.trim());
                    if (n != null) {
                      context.read<SettingsNotifier>().setLowStockThreshold(n);
                    }
                  },
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      final n = int.tryParse(_thresholdCtrl.text.trim());
                      if (n != null) {
                        context.read<SettingsNotifier>().setLowStockThreshold(n);
                      }
                    },
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (auth.isSignedIn) ...[
          const SizedBox(height: 24),
          Text(
            'Danger zone',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.error,
                ),
          ),
          const SizedBox(height: 8),
          Card(
            color: Theme.of(context)
                .colorScheme
                .errorContainer
                .withValues(alpha: 0.35),
            child: ListTile(
              leading: Icon(
                Icons.delete_forever_outlined,
                color: Theme.of(context).colorScheme.error,
              ),
              title: const Text('Delete data'),
              subtitle: const Text('Choose how much data to delete.'),
              onTap: () => _showDeleteDataDialog(context),
            ),
          ),
        ],
      ],
    );
  }
}
