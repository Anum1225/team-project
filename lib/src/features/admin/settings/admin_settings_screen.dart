part of '../../common/reports/reporting.dart';

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({
    super.key,
    required this.onUsers,
    required this.onCategories,
  });

  final VoidCallback onUsers;
  final VoidCallback onCategories;

  @override
  Widget build(BuildContext context) {
    final palette = Harvest.colors(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: palette.canvas,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
        children: [
          const SectionHeader('Appearance'),
          SwitchListTile.adaptive(
            value: dark,
            title: Text(dark ? 'Dark appearance' : 'Light appearance'),
            subtitle: const Text('Use the theme that is easiest to read.'),
            secondary: Icon(
              dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              color: palette.green,
            ),
            onChanged: (_) => ThemeReveal.toggle(context),
          ),
          const SizedBox(height: 14),
          if (HarvestScope.of(context).live &&
              HarvestScope.of(context).authenticated) ...[
            const SectionHeader('Account security'),
            const EmailSecurityPanel(),
            const SizedBox(height: 14),
          ],
          const SectionHeader('Platform management'),
          _settingsAction(
            context,
            Icons.storefront_outlined,
            'Farmers markets',
            'Publish locations, map positions and opening hours',
            () => openPage(context, const MarketDirectory()),
          ),
          _settingsAction(
            context,
            Icons.edit_note_outlined,
            'About & public content',
            'Edit the About page, preview changes and publish support details',
            () => openPage(context, const PublicContentEditor()),
          ),
          _settingsAction(
            context,
            Icons.people_alt_outlined,
            'Accounts and access',
            'Review and suspend customer or farmer accounts',
            onUsers,
          ),
          _settingsAction(
            context,
            Icons.category_outlined,
            'Product categories',
            'Maintain the live product catalog categories',
            onCategories,
          ),
          _settingsAction(
            context,
            Icons.feedback_outlined,
            'Customer feedback',
            'Read messages submitted from customer support',
            () => openPage(context, const ReviewsScreen()),
          ),
          _settingsAction(
            context,
            Icons.analytics_outlined,
            'Platform reports',
            'Order totals, completed value and active farmers',
            () =>
                openPage(context, const LiveReports(title: 'Platform reports')),
          ),
          const SizedBox(height: 14),
          const InfoNote(
            'Checkout records simulated orders. No payment provider is configured.',
          ),
        ],
      ),
    );
  }

  Widget _settingsAction(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback action,
  ) {
    final palette = Harvest.colors(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      child: ListTile(
        leading: Icon(icon, color: palette.green),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: action,
      ),
    );
  }
}
