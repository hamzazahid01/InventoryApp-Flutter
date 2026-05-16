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
  final _priceCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _submitting = false;

  static const _maxNoteLength = 500;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _priceCtrl.text.isNotEmpty) return;
      final p = context.read<InventoryNotifier>().productById(widget.productId);
      if (p == null) return;
      final cp = p.costPrice;
      _priceCtrl.text = cp == cp.truncateToDouble()
          ? cp.toInt().toString()
          : cp.toStringAsFixed(2);
      setState(() {});
    });
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    _notesCtrl.dispose();
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
    final qty = int.tryParse(_qtyCtrl.text.trim()) ?? 0;
    final sellPrice = double.tryParse(_priceCtrl.text.trim()) ?? 0;
    final lineTotal = sellPrice * qty;
    final lineProfit = (sellPrice - p.costPrice) * qty;

    Future<void> submit() async {
      if (_submitting) return;
      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);
      final noteText = _notesCtrl.text.trim();
      setState(() => _submitting = true);
      final err = await context.read<InventoryNotifier>().sellProduct(
            productId: p.id,
            quantity: qty,
            sellingPrice: sellPrice,
            notes: noteText.isEmpty ? null : noteText,
          );
      if (!mounted) return;
      setState(() => _submitting = false);
      if (err != null) {
        messenger.showSnackBar(SnackBar(content: Text(err)));
        return;
      }
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Sale recorded · Profit ${formatMoney(lineProfit, currency)}',
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
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
            'Cost ${formatMoney(p.costPrice, currency)} · In stock ${p.stock}',
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
              labelText: 'Quantity sold',
              prefixIcon: Icon(Icons.inventory_outlined),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _priceCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: const InputDecoration(
              labelText: 'Selling price (per unit)',
              prefixIcon: Icon(Icons.sell_outlined),
              helperText: 'Enter actual sale price — not limited to cost price',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          Text(
            'Sale note',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _notesCtrl,
            minLines: 3,
            maxLines: 5,
            maxLength: _maxNoteLength,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText:
                  'Customer name, payment terms, delivery details, discount reason…',
              alignLabelWithHint: true,
              filled: true,
              fillColor: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              helperText: 'Optional — saved with this sale in history',
            ),
            onChanged: (_) => setState(() {}),
          ),
          if (qty > 0 && sellPrice >= 0) ...[
            const SizedBox(height: 16),
            Card(
              color: Theme.of(context).colorScheme.primaryContainer.withValues(
                    alpha: 0.35,
                  ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _summaryRow(
                      context,
                      'Sale total',
                      formatMoney(lineTotal, currency),
                    ),
                    const SizedBox(height: 6),
                    _summaryRow(
                      context,
                      'Profit on this sale',
                      formatMoney(lineProfit, currency),
                      valueColor: lineProfit >= 0
                          ? Colors.green.shade700
                          : Theme.of(context).colorScheme.error,
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: (p.stock > 0 && qty > 0 && !_submitting) ? submit : null,
            child: _submitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Confirm sale'),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: valueColor,
              ),
        ),
      ],
    );
  }
}
