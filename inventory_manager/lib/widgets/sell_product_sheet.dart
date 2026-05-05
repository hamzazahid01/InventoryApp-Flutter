import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/inventory_notifier.dart';
import '../providers/settings_notifier.dart';
import '../utils/currency_format.dart';

Future<void> showSellProductSheet(
  BuildContext context, {
  required String productId,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: _SellProductBody(productId: productId),
      );
    },
  );
}

class _SellProductBody extends StatefulWidget {
  const _SellProductBody({required this.productId});

  final String productId;

  @override
  State<_SellProductBody> createState() => _SellProductBodyState();
}

class _SellProductBodyState extends State<_SellProductBody> {
  final _qtyCtrl = TextEditingController(text: '1');

  @override
  void dispose() {
    _qtyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inv = context.watch<InventoryNotifier>();
    final settings = context.watch<SettingsNotifier>();
    final p = inv.productById(widget.productId);

    if (p == null) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text('Product no longer exists.'),
      );
    }

    final currency = settings.currencyCode;

    Future<void> submit() async {
      final q = int.tryParse(_qtyCtrl.text.trim()) ?? 0;
      final err = await context.read<InventoryNotifier>().sellProduct(
            productId: p.id,
            quantity: q,
          );
      if (!context.mounted) return;
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
        return;
      }
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sale recorded')),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Sell · ${p.name}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Price ${formatMoney(p.price, currency)} · In stock ${p.stock}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.65),
                ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _qtyCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Quantity',
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: p.stock > 0 ? submit : null,
            child: const Text('Confirm sale'),
          ),
        ],
      ),
    );
  }
}
