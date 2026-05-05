import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/auth_notifier.dart';
import '../providers/inventory_notifier.dart';
import '../providers/settings_notifier.dart';
import '../utils/currency_format.dart';
import '../widgets/product_thumb.dart';
import '../widgets/sell_product_sheet.dart';

class SalesScreen extends StatelessWidget {
  const SalesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final inv = context.watch<InventoryNotifier>();
    final cc = context.watch<SettingsNotifier>().currencyCode;
    final df = DateFormat.yMMMd().add_jm();
    final isAdmin = context.select((AuthNotifier a) => a.isAdmin);

    if (!inv.isLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(
          child: inv.products.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Add products first to record sales.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.55),
                          ),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: inv.products.length,
                  itemBuilder: (context, i) {
                    final p = inv.products[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: ProductThumb(
                          imageUrl: p.imageUrl,
                          localImagePath: p.localImagePath,
                          size: 48,
                        ),
                        title: Text(p.name),
                        subtitle: Text(
                          '${formatMoney(p.price, cc)} · Stock ${p.stock}',
                        ),
                        trailing: FilledButton(
                          onPressed:
                              (isAdmin && p.stock > 0)
                                  ? () => showSellProductSheet(
                                        context,
                                        productId: p.id,
                                      )
                                  : null,
                          child: Text(isAdmin ? 'Sell' : 'View'),
                        ),
                      ),
                    );
                  },
                ),
        ),
        const Divider(height: 1),
        Material(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
          child: SizedBox(
            height: 320,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Text(
                    'Sales history',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                Expanded(
                  child: inv.sales.isEmpty
                      ? Center(
                          child: Text(
                            'No sales recorded yet.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.5),
                                ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 16),
                          itemCount: inv.sales.length,
                          itemBuilder: (context, i) {
                            final s = inv.sales[i];
                            return ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 18,
                                child: Text('${s.quantity}'),
                              ),
                              title: Text(s.productName),
                              subtitle: Text(df.format(s.dateTime.toLocal())),
                              trailing: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    formatMoney(s.totalPrice, cc),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  IconButton(
                                    tooltip: 'Undo sale',
                                    icon: Icon(
                                      Icons.undo,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                    onPressed: () async {
                                      final ok = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Undo sale?'),
                                          content: Text(
                                            'Restore ${s.quantity} × ${s.productName} to stock and remove this entry from history.',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx, false),
                                              child: const Text('Cancel'),
                                            ),
                                            FilledButton(
                                              onPressed: () => Navigator.pop(ctx, true),
                                              child: const Text('Undo'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (ok != true || !context.mounted) return;
                                      final err = await context
                                          .read<InventoryNotifier>()
                                          .undoSale(s.id);
                                      if (!context.mounted) return;
                                      final messenger = ScaffoldMessenger.of(context);
                                      if (err != null) {
                                        messenger.showSnackBar(
                                          SnackBar(content: Text(err)),
                                        );
                                      } else {
                                        messenger.showSnackBar(
                                          const SnackBar(
                                            content: Text('Sale undone — stock updated'),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
