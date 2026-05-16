import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../models/sale_record.dart';
import '../providers/auth_notifier.dart';
import '../providers/inventory_notifier.dart';
import '../providers/settings_notifier.dart';
import '../utils/currency_format.dart';
import '../utils/sales_history_filter.dart';
import '../widgets/product_thumb.dart';
import '../widgets/sales_history_panel.dart';
import '../widgets/sell_product_sheet.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  SalesHistoryFilterState _filters = const SalesHistoryFilterState();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() => _filters = const SalesHistoryFilterState());
  }

  SalesHistoryFilterState _effectiveFilters(List<Product> products) {
    var f = _filters;
    final cats = SalesHistoryFilter.categoriesFromProducts(products);
    if (f.category != null && !cats.contains(f.category)) {
      f = f.copyWith(clearCategory: true);
    }
    if (f.productId != null && !products.any((p) => p.id == f.productId)) {
      f = f.copyWith(clearProduct: true);
    }
    return f;
  }

  Future<void> _undoSale(BuildContext context, SaleRecord sale) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Undo sale?'),
        content: Text(
          'Restore ${sale.quantity} × ${sale.productName} to stock and remove this entry from history.',
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
    final err = await context.read<InventoryNotifier>().undoSale(sale.id);
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    if (err != null) {
      messenger.showSnackBar(SnackBar(content: Text(err)));
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text('Sale undone — stock updated')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final inv = context.watch<InventoryNotifier>();
    final cc = context.watch<SettingsNotifier>().currencyCode;
    final isAdmin = context.select((AuthNotifier a) => a.isAdmin);

    if (!inv.isLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    final effectiveFilters = _effectiveFilters(inv.products);
    final summary = SalesHistoryFilter.apply(
      sales: inv.sales,
      products: inv.products,
      filters: effectiveFilters,
    );

    return Column(
      children: [
        Material(
          color: Theme.of(context).colorScheme.surface,
          child: TabBar(
            controller: _tabs,
            tabs: const [
              Tab(
                height: 48,
                icon: Icon(Icons.point_of_sale_outlined, size: 20),
                text: 'Sell',
              ),
              Tab(
                height: 48,
                icon: Icon(Icons.receipt_long_outlined, size: 20),
                text: 'History',
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _SellProductsTab(
                products: inv.products,
                currencyCode: cc,
                isAdmin: isAdmin,
              ),
              SalesHistoryPanel(
                products: inv.products,
                allSalesCount: inv.sales.length,
                summary: summary,
                effectiveFilters: effectiveFilters,
                currencyCode: cc,
                isAdmin: isAdmin,
                onFiltersChanged: (f) => setState(() => _filters = f),
                onClearFilters: _clearFilters,
                onUndoSale: (s) => _undoSale(context, s),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SellProductsTab extends StatelessWidget {
  const _SellProductsTab({
    required this.products,
    required this.currencyCode,
    required this.isAdmin,
  });

  final List<Product> products;
  final String currencyCode;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return Center(
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
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, i) {
        final p = products[i];
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
              'Cost ${formatMoney(p.costPrice, currencyCode)} · Stock ${p.stock}',
            ),
            trailing: FilledButton(
              onPressed: (isAdmin && p.stock > 0)
                  ? () => showSellProductSheet(context, productId: p.id)
                  : null,
              child: Text(isAdmin ? 'Sell' : 'View'),
            ),
          ),
        );
      },
    );
  }
}
