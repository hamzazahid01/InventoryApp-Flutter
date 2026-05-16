import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/inventory_notifier.dart';
import '../widgets/local_file_image.dart';

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key, this.product});

  final Product? product;

  bool get isEditing => product != null;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _categoryCtrl;

  XFile? _pickedImage;
  MemoryImage? _pickedPreview;
  bool _removeExistingImage = false;
  bool _saving = false;

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _priceCtrl = TextEditingController(
      text: p != null ? p.price.toString() : '',
    );
    _stockCtrl = TextEditingController(
      text: p != null ? p.stock.toString() : '',
    );
    _categoryCtrl = TextEditingController(text: p?.category ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    try {
      final x = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 88,
      );
      if (x == null) return;
      final bytes = await x.readAsBytes();
      setState(() {
        _pickedImage = x;
        _pickedPreview = MemoryImage(bytes);
        _removeExistingImage = false;
      });
    } on PlatformException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open gallery: ${e.message}')),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final name = _nameCtrl.text.trim();
      final costPrice = double.tryParse(_priceCtrl.text.trim()) ?? 0;
      final stock = int.tryParse(_stockCtrl.text.trim()) ?? 0;
      final cat = _categoryCtrl.text.trim();

      final notifier = context.read<InventoryNotifier>();
      if (widget.isEditing) {
        final existing = widget.product!;
        await notifier.updateProduct(
          existing.copyWith(
            name: name,
            costPrice: costPrice,
            stock: stock,
            category: cat.isEmpty ? null : cat,
            clearCategory: cat.isEmpty,
          ),
          newImage: _pickedImage,
          removeImage:
              _removeExistingImage &&
              _pickedImage == null &&
              (existing.imageUrl != null && existing.imageUrl!.trim().isNotEmpty),
        );
      } else {
        final result = await notifier.addProduct(
          name: name,
          costPrice: costPrice,
          stock: stock,
          category: cat.isEmpty ? null : cat,
          image: _pickedImage,
        );
        if (!mounted) return;
        if (_pickedImage != null && result.imageUrl == null) {
          final msg = result.imageError ?? 'Image upload failed';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Product saved, but photo not uploaded. ($msg)'),
            ),
          );
        }
      }
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product saved')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _imagePreview(BuildContext context) {
    final hasNetwork =
        !_removeExistingImage &&
        widget.product?.imageUrl != null &&
        (widget.product!.imageUrl!.trim().isNotEmpty);
    final hasLocal =
        !_removeExistingImage &&
        (widget.product?.localImagePath != null) &&
        (widget.product!.localImagePath!.trim().isNotEmpty);

    Widget child;
    if (_pickedPreview != null) {
      child = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Image(image: _pickedPreview!, fit: BoxFit.cover),
        ),
      );
    } else if (hasNetwork) {
      child = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Image.network(
            widget.product!.imageUrl!.trim(),
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (ctx, error, stack) => _placeholderBox(context),
            loadingBuilder: (ctx, child, prog) =>
                prog == null ? child : _placeholderBox(context, loading: true),
          ),
        ),
      );
    } else if (hasLocal) {
      // For edit screen, show local fallback if remote isn't available.
      // (On web this will just show the placeholder.)
      child = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: buildLocalFileImage(
            path: widget.product!.localImagePath!.trim(),
            fit: BoxFit.cover,
            onError: _placeholderBox(context),
          ),
        ),
      );
    } else {
      child = _placeholderBox(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        child,
        const SizedBox(height: 10),
        Row(
          children: [
            FilledButton.tonalIcon(
              onPressed: _saving ? null : _pickFromGallery,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Gallery'),
            ),
            const SizedBox(width: 12),
            if (_pickedImage != null || hasNetwork || _removeExistingImage)
              TextButton(
                onPressed: _saving
                    ? null
                    : () {
                        setState(() {
                          _pickedImage = null;
                          _pickedPreview = null;
                          if (hasNetwork || widget.product?.imageUrl != null) {
                            _removeExistingImage = true;
                          }
                        });
                      },
                child: const Text('Clear image'),
              ),
          ],
        ),
        if (_removeExistingImage && (_pickedImage == null))
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Saving will remove the stored product photo.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
            ),
          ),
      ],
    );
  }

  Widget _placeholderBox(BuildContext context, {bool loading = false}) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 44,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.45),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'No image',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.55),
                          ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit product' : 'Add product'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Photo',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            _imagePreview(context),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _priceCtrl,
              decoration: const InputDecoration(
                labelText: 'Cost price (per unit)',
                helperText: 'Buying price — selling price is set at sale time',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              validator: (v) {
                final x = double.tryParse(v?.trim() ?? '');
                if (x == null || x < 0) return 'Valid price required';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _stockCtrl,
              decoration: const InputDecoration(labelText: 'Stock quantity'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                final x = int.tryParse(v?.trim() ?? '');
                if (x == null || x < 0) return 'Valid stock required';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _categoryCtrl,
              decoration: const InputDecoration(
                labelText: 'Category (optional)',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            if (widget.isEditing && widget.product != null) ...[
              const SizedBox(height: 12),
              Text(
                'Created ${widget.product!.createdAt.toLocal()}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.55),
                    ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.isEditing ? 'Save changes' : 'Create product'),
            ),
          ],
        ),
      ),
    );
  }
}
