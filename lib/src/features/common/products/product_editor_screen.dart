part of '../management/operations.dart';

class ProductEditorScreen extends StatefulWidget {
  const ProductEditorScreen({super.key, this.product});
  final Product? product;

  @override
  State<ProductEditorScreen> createState() => _ProductEditorScreenState();
}

class _ProductEditorScreenState extends State<ProductEditorScreen> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _price = TextEditingController();
  final TextEditingController _stock = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final TextEditingController _unit = TextEditingController();

  String? _category;
  String? _farmId;
  String? _error;
  String _image = '';
  Uint8List? _photo;
  bool _initialized = false;
  bool _picking = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final store = HarvestScope.of(context);
    final p = widget.product;
    _name.text = p?.name ?? '';
    _price.text = p == null ? '' : (p.price / 100).toStringAsFixed(2);
    _stock.text = p?.stock.toString() ?? '';
    _description.text = p?.description ?? '';
    _unit.text = p?.unit ?? 'kg';
    _category = p?.category ?? store.categories.firstOrNull;
    _farmId =
        p?.farmId ??
        (store.role == UserRole.farmer
            ? store.ownFarm.id
            : store.farms.firstOrNull?.id);
    _image = p?.image ?? '';
    _photo = p?.photo;
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _stock.dispose();
    _description.dispose();
    _unit.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    setState(() => _picking = true);
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1400,
        imageQuality: 85,
      );
      if (file == null) return;
      if (await file.length() > 8 * 1024 * 1024) {
        if (mounted) {
          setState(() => _error = 'Choose an image smaller than 8 MB.');
        }
        return;
      }
      final bytes = await file.readAsBytes();
      if (mounted) {
        setState(() {
          _photo = bytes;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Could not open image. Please check permissions.',
        );
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final store = HarvestScope.of(context);
    if (_category == null || _farmId == null) {
      setState(() => _error = 'Farm and category must be selected.');
      return;
    }
    final value = Product(
      id: widget.product?.id ?? 'p-${DateTime.now().microsecondsSinceEpoch}',
      name: _name.text.trim(),
      category: _category!,
      farmId: _farmId!,
      price: (double.parse(_price.text) * 100).round(),
      stock: int.parse(_stock.text),
      image: _image,
      photo: _photo,
      unit: _unit.text.trim().isEmpty ? 'kg' : _unit.text.trim(),
      description: _description.text.trim(),
    );
    final msg = await store.saveProduct(value);
    if (!mounted) return;
    if (msg != null) {
      setState(() => _error = msg);
      return;
    }
    Navigator.pop(context);
    notice(
      context,
      widget.product == null
          ? (store.role == UserRole.farmer
                ? 'Product submitted for administrator approval'
                : 'Product added to your farm stand')
          : 'Product updated successfully',
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = HarvestScope.of(context);
    final p = widget.product;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // De-duplicated, and always containing the current selection, so the
    // dropdown never asserts when categories load late or one was renamed.
    final categoryOptions = <String>{
      ...(store.categories.isEmpty
          ? const [
              'Grains',
              'Dairy',
              'Nuts',
              'Vegetables',
              'Fruits',
              'Pulses',
            ]
          : store.categories),
      if (_category != null && _category!.isNotEmpty) _category!,
    }.toList();
    _category ??= categoryOptions.firstOrNull;

    return Scaffold(
      backgroundColor: Harvest.colors(context).cream,
      appBar: AppBar(
        title: Text(
          p == null ? 'Add Product' : 'Edit Product',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          if (p != null)
            IconButton(
              tooltip: 'Delete product',
              onPressed: () async {
                if (await confirmAction(
                  context,
                  title: 'Remove this product?',
                  message: 'This will remove it from customer catalogs and shopping baskets.',
                  action: 'Remove Product',
                  isDestructive: true,
                )) {
                  final error = await store.deleteProduct(p);
                  if (error != null) {
                    if (context.mounted) notice(context, error, isError: true);
                    return;
                  }
                  if (context.mounted) {
                    Navigator.pop(context);
                    notice(context, 'Product removed from inventory');
                  }
                }
              },
              icon: const Icon(Icons.delete_outline, color: Harvest.danger),
            ),
        ],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            // Photo Upload Row matching Image 2 Screen 4
            Row(
              children: [
                // Selected photo preview
                Stack(
                  children: [
                    Container(
                      width: 140,
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Harvest.colors(context).border,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Photo(
                          _image,
                          bytes: _photo,
                          fit: BoxFit.cover,
                          radius: 18,
                        ),
                      ),
                    ),
                    if (_photo != null || _image.isNotEmpty)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: InkWell(
                          onTap: () => setState(() {
                            _photo = null;
                            _image = '';
                          }),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),

                // Dashed Add More Photos Card
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: _picking ? null : _pickImage,
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF14241B)
                            : const Color(0xFFF9FBF9),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFF1E5631).withValues(alpha: 0.4),
                          style: BorderStyle.solid,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E5631)
                                  .withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt_outlined,
                              size: 22,
                              color: Color(0xFF1E5631),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _picking
                                ? 'Opening…'
                                : (_photo != null || _image.isNotEmpty
                                      ? 'Replace photo'
                                      : 'Add photo'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Harvest.colors(context).muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Product Name *
            Text(
              'Product Name *',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Harvest.colors(context).ink,
              ),
            ),
            const SizedBox(height: 6),
            HarvestField(
              controller: _name,
              label: '',
              hint: 'e.g. Fresh Tomatoes',
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Enter product name' : null,
            ),
            const SizedBox(height: 16),

            // Category * Dropdown with icons
            Text(
              'Category *',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Harvest.colors(context).ink,
              ),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              // Rebuild when the live category list changes so the selected
              // value always matches exactly one item.
              key: ValueKey('category-${categoryOptions.join('|')}'),
              initialValue: _category,
              hint: Text(
                categoryOptions.isEmpty
                    ? 'No categories available'
                    : 'Select a category',
              ),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Harvest.colors(context).border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Harvest.colors(context).border),
                ),
              ),
              isExpanded: true,
              items: categoryOptions
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Row(
                        children: [
                          Text(switch (c.toLowerCase()) {
                            'vegetables' => '🍅',
                            'fruits' => '🍎',
                            'dairy' => '🥛',
                            'grains' => '🌾',
                            'herbs' => '🌿',
                            _ => '📦',
                          }, style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          Text(
                            c,
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _category = v),
              validator: (v) => v == null ? 'Choose a category.' : null,
            ),

            if (store.role == UserRole.admin) ...[
              const SizedBox(height: 16),
              Text(
                'Farm Origin *',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Harvest.colors(context).ink,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _farmId,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                isExpanded: true,
                items: store.farms
                    .map(
                      (f) => DropdownMenuItem(value: f.id, child: Text(f.name)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _farmId = v),
                validator: (v) => v == null ? 'Choose a farm.' : null,
              ),
            ],
            const SizedBox(height: 16),

            // Price (Rs.) * and Unit
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Price (Rs.) *',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Harvest.colors(context).ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      HarvestField(
                        controller: _price,
                        label: '',
                        hint: '120',
                        keyboard: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (v) =>
                            v == null ||
                                double.tryParse(v) == null ||
                                !double.parse(v).isFinite ||
                                double.parse(v) < 0 ||
                                double.parse(v) > 10000000
                            ? 'Enter valid price'
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Unit Type',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Harvest.colors(context).ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _unit.text.isEmpty ? 'kg' : _unit.text,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        items: {
                          'kg',
                          'litre',
                          'dozen',
                          'pack',
                          'basket',
                          if (_unit.text.isNotEmpty) _unit.text,
                        }
                            .map(
                              (u) => DropdownMenuItem(
                                value: u,
                                child: Text(u, overflow: TextOverflow.ellipsis),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _unit.text = v);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Stock Quantity * and Unit
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stock Quantity *',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Harvest.colors(context).ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      HarvestField(
                        controller: _stock,
                        label: '',
                        hint: '50',
                        keyboard: TextInputType.number,
                        validator: (v) =>
                            v == null ||
                                int.tryParse(v) == null ||
                                int.parse(v) < 0 ||
                                int.parse(v) > 1000000000
                            ? 'Enter a whole number from 0 to 1,000,000,000'
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Description with Character Counter
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Description',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Harvest.colors(context).ink,
                  ),
                ),
                Text(
                  '${_description.text.length}/500',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 11,
                    color: Harvest.colors(context).muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            HarvestField(
              controller: _description,
              label: '',
              hint: 'Describe the product, its growing conditions, storage and preparation.',
              lines: 4,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 18),

            if (_error != null) ...[
              const SizedBox(height: 14),
              InfoNote(_error!, error: true),
            ],
          ],
        ),
      ),
      bottomNavigationBar: BottomAction(
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _picking || store.busy ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E5631),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Save Product',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
