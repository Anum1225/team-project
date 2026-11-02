part of '../../common/management/operations.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final TextEditingController _search = TextEditingController();
  bool _showSearch = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _editCategory(BuildContext context, {String? category}) async {
    final store = HarvestScope.of(context);
    final controller = TextEditingController(text: category);
    String? error;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheet) => StatefulBuilder(
        builder: (context, update) => SheetBody(
          children: [
            Text(
              category == null ? 'Add Category' : 'Edit Category',
              style: Harvest.editorial(24),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Category Name',
                errorText: error,
              ),
            ),
            const SizedBox(height: 20),
            HarvestButton(
              label: category == null ? 'Create Category' : 'Save Changes',
              onPressed: store.busy
                  ? null
                  : () async {
                      final result = await store.saveCategory(
                        controller.text,
                        previous: category,
                      );
                      if (!context.mounted) return;
                      if (result != null) {
                        update(() => error = result);
                        return;
                      }
                      Navigator.pop(sheet);
                    },
            ),
          ],
        ),
      ),
    );
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = HarvestScope.of(context);
    if (store.live && (!store.authenticated || store.role != UserRole.admin)) {
      return const Scaffold(
        body: Center(child: Text('Administrator access required.')),
      );
    }

    final query = _search.text.toLowerCase().trim();
    final categories = store.categories.where((c) {
      if (query.isNotEmpty && !c.toLowerCase().contains(query)) return false;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: Harvest.colors(context).cream,
      appBar: AppBar(
        title: const Text(
          'Market Categories',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: 'Search categories',
            icon: Icon(
              _showSearch ? Icons.close_rounded : Icons.search_rounded,
            ),
            onPressed: () => setState(() {
              _showSearch = !_showSearch;
              if (!_showSearch) _search.clear();
            }),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 14, left: 4),
            child: Center(
              child: ElevatedButton.icon(
                onPressed: () => _editCategory(context),
                icon: const Icon(
                  Icons.add_rounded,
                  size: 16,
                  color: Colors.white,
                ),
                label: const Text(
                  'Add',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E5631),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          if (_showSearch)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: SearchBox(
                controller: _search,
                hint: 'Search categories…',
                managementStyle: true,
                onChanged: (_) => setState(() {}),
              ),
            ),
          if (store.live) const DataStatusBar(),
          if (categories.isEmpty)
            const InfoNote('No categories yet. Tap + Add to begin.'),
          for (final c in categories) ...[
            Builder(
              builder: (ctx) {
                final count = store.live
                    ? store.categoryCounts[c] ?? 0
                    : store.products.where((p) => p.category == c).length;
                final (iconEmoji, bgColor) = switch (c.toLowerCase()) {
                  'fruits' => ('🍎', const Color(0xFFFEE2E2)),
                  'vegetables' => ('🥕', const Color(0xFFDCFCE7)),
                  'dairy' => ('🥛', const Color(0xFFDBEAFE)),
                  'grains' => ('🌾', const Color(0xFFFEF3C7)),
                  'herbs' => ('🌿', const Color(0xFFD1FAE5)),
                  _ => ('📦', const Color(0xFFFFEDD5)),
                };

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Harvest.colors(context).surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Harvest.colors(context).border),
                    boxShadow: Harvest.cardShadow,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          iconEmoji,
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c,
                              style: const TextStyle(
                                fontFamily: 'Manrope',
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$count products',
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                color: Harvest.colors(context).muted,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.edit_outlined,
                          size: 19,
                          color: Harvest.colors(context).green,
                        ),
                        onPressed: () => _editCategory(context, category: c),
                      ),
                      PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          Icons.more_horiz_rounded,
                          size: 19,
                          color: Harvest.colors(context).muted,
                        ),
                        onSelected: (val) async {
                          if (val == 'edit') {
                            _editCategory(context, category: c);
                          } else if (val == 'delete') {
                            if (await confirmAction(
                              context,
                              title: 'Remove $c?',
                              message: 'Only categories without assigned products can be deleted.',
                              action: 'Remove Category',
                              isDestructive: true,
                            )) {
                              final err = await store.deleteCategory(c);
                              if (context.mounted) {
                                notice(
                                  context,
                                  err ?? 'Category removed',
                                  isError: err != null,
                                );
                              }
                            }
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit Category'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
      bottomNavigationBar: BottomAction(
        child: HarvestButton(
          label: 'Add New Category',
          icon: Icons.add,
          onPressed: () => _editCategory(context),
        ),
      ),
    );
  }
}
