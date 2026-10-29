part of '../../common/management/operations.dart';

String _updatedDateLabel(DateTime date) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final local = date.toLocal();
  return '${months[local.month - 1]} ${local.day}, ${local.year}';
}

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final TextEditingController _search = TextEditingController();
  String _selectedFilter = 'All';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = HarvestScope.of(context);
    final palette = Harvest.colors(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (store.live && (!store.authenticated || store.role != UserRole.admin)) {
      return const Scaffold(
        body: Center(child: Text('Administrator access required.')),
      );
    }

    final query = _search.text.toLowerCase().trim();

    final allUsers = store.accounts.where((a) {
      if (query.isNotEmpty) {
        return a.name.toLowerCase().contains(query) ||
            a.email.toLowerCase().contains(query);
      }
      return true;
    }).toList();

    final customerCount = store.accounts
        .where((a) => a.role == UserRole.customer)
        .length;
    final farmerCount = store.accounts
        .where((a) => a.role == UserRole.farmer)
        .length;
    final totalCount = store.accounts.length;

    final users = allUsers.where((a) {
      if (_selectedFilter == 'Customers') return a.role == UserRole.customer;
      if (_selectedFilter == 'Farmers') return a.role == UserRole.farmer;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: palette.canvas,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'Users',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: palette.ink,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // Filter Tabs matching Image 1: All (1,248) | Customers (1,012) | Farmers (186)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterPill(
                  'All',
                  'All ($totalCount)',
                  _selectedFilter == 'All',
                  () => setState(() => _selectedFilter = 'All'),
                  palette,
                ),
                const SizedBox(width: 8),
                _filterPill(
                  'Customers',
                  'Customers ($customerCount)',
                  _selectedFilter == 'Customers',
                  () => setState(() => _selectedFilter = 'Customers'),
                  palette,
                ),
                const SizedBox(width: 8),
                _filterPill(
                  'Farmers',
                  'Farmers ($farmerCount)',
                  _selectedFilter == 'Farmers',
                  () => setState(() => _selectedFilter = 'Farmers'),
                  palette,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          SearchBox(
            controller: _search,
            hint: 'Search users by name or email…',
            managementStyle: true,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),

          if (users.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No users match your filter.',
                  style: TextStyle(fontFamily: 'Manrope', color: palette.muted),
                ),
              ),
            ),

          for (final a in users) ...[
            // Prefer the most recent profile change; new accounts may only
            // have a creation timestamp until their first update.
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: palette.border, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: InkWell(
                onTap: () => openPage(context, UserDetailScreen(account: a)),
                borderRadius: BorderRadius.circular(20),
                child: Row(
                  children: [
                    // Avatar circle
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: a.role == UserRole.farmer
                            ? const Color(0xFF10B981).withValues(alpha: 0.15)
                            : const Color(0xFF3B82F6).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        a.name.isNotEmpty ? a.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: a.role == UserRole.farmer
                              ? const Color(0xFF059669)
                              : const Color(0xFF2563EB),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // User Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.name,
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            a.email,
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 11,
                              color: palette.muted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  (a.role == UserRole.farmer
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFF3B82F6))
                                      .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              a.role.label,
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: a.role == UserRole.farmer
                                    ? const Color(0xFF059669)
                                    : const Color(0xFF2563EB),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Status Badge & Date & 3 Dots
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    (a.active
                                            ? const Color(0xFF10B981)
                                            : const Color(0xFFEF4444))
                                        .withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                a.active ? 'Active' : 'Inactive',
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: a.active
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFEF4444),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(
                                Icons.more_horiz_rounded,
                                size: 18,
                              ),
                              color: palette.muted,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => openPage(
                                context,
                                UserDetailScreen(account: a),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (a.updatedAt ?? a.createdAt case final date?)
                          Text(
                            _updatedDateLabel(date),
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 10,
                              color: palette.muted,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _filterPill(
    String id,
    String label,
    bool isSelected,
    VoidCallback onTap,
    HarvestPalette palette,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? palette.green : palette.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? palette.green : palette.border,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : palette.ink,
          ),
        ),
      ),
    );
  }
}
