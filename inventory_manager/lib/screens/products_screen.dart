import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/auth_notifier.dart';
import '../providers/inventory_notifier.dart';
import '../providers/settings_notifier.dart';
import '../utils/currency_format.dart';
import '../widgets/product_thumb.dart';
import 'product_form_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _searchCtrl = TextEditingController();
  String _categoryFilter = '__all__';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Product> _filtered(List<Product> all, String categoryFilter) {
    final q = _searchCtrl.text.trim().toLowerCase();
    return all.where((p) {
      if (categoryFilter != '__all__') {
        final c = p.category ?? '';
        if (c != categoryFilter) return false;
      }
      if (q.isEmpty) return true;
      return p.name.toLowerCase().contains(q) ||
          (p.category?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  Set<String> _categories(List<Product> all) {
    final s = <String>{};
    for (final p in all) {
      if (p.category != null && p.category!.trim().isNotEmpty) {
        s.add(p.category!.trim());
      }
    }
    return s;
  }

  Future<void> _confirmDelete(Product p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete product'),
        content: Text('Remove "${p.name}" from inventory? Sales history for this product will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<InventoryNotifier>().deleteProduct(p.id);
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

    final cats = _categories(inv.products).toList()..sort();
    final effectiveFilter =
        _categoryFilter != '__all__' && cats.contains(_categoryFilter)
            ? _categoryFilter
            : '__all__';
    final list = _filtered(inv.products, effectiveFilter);

    return Scaffold(
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProductFormScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add product'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search name or category…',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchCtrl.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() {});
                            },
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Category',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      DropdownButton<String>(
                        value: effectiveFilter,
                        items: [
                          const DropdownMenuItem(
                            value: '__all__',
                            child: Text('All'),
                          ),
                          ...cats.map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(c),
                            ),
                          ),
                        ],
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() => _categoryFilter = v);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? Center(
                    child: Text(
                      inv.products.isEmpty
                          ? 'No products yet. Tap Add product.'
                          : 'No matches for your filters.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.55),
                          ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final p = list[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: ProductThumb(
                            imageUrl: p.imageUrl,
                            localImagePath: p.localImagePath,
                            size: 52,
                          ),
                          title: Text(p.name),
                          subtitle: Text(
                            'Cost ${formatMoney(p.costPrice, cc)} · Stock ${p.stock} · Sold ${p.sold}'
                            '${p.totalProfit > 0 ? ' · Profit ${formatMoney(p.totalProfit, cc)}' : ''}'
                            '${p.category != null ? ' · ${p.category}' : ''}',
                          ),
                          isThreeLine: true,
                          trailing: isAdmin
                              ? PopupMenuButton<String>(
                                  onSelected: (action) async {
                                    if (action == 'edit') {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              ProductFormScreen(product: p),
                                        ),
                                      );
                                    } else if (action == 'delete') {
                                      await _confirmDelete(p);
                                    }
                                  },
                                  itemBuilder: (ctx) => const [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: ListTile(
                                        leading: Icon(Icons.edit_outlined),
                                        title: Text('Edit'),
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: ListTile(
                                        leading: Icon(Icons.delete_outline),
                                        title: Text('Delete'),
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ],
                                )
                              : null,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
