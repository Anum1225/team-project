import 'package:flutter/material.dart';

import '../../authentication/email_security.dart';

import '../data/models.dart';
import '../shared/components.dart';
import '../shared/theme_reveal.dart';

class PreferencesScreen extends StatelessWidget {
  const PreferencesScreen({super.key});
  @override
  Widget build(BuildContext context) => HarvestPage(
    title: 'App settings',
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (HarvestScope.of(context).role == UserRole.customer)
          const AssistantPreferenceTile(),
        const SectionHeader('Appearance'),
        SwitchListTile.adaptive(
          title: const Text('Dark appearance'),
          value: Theme.of(context).brightness == Brightness.dark,
          onChanged: (_) => ThemeReveal.toggle(context),
        ),
        if (HarvestScope.of(context).live &&
            HarvestScope.of(context).authenticated) ...[
          const SizedBox(height: 20),
          const SectionHeader('Account security'),
          const EmailSecurityPanel(),
        ],
      ],
    ),
  );
}

class AssistantPreferenceTile extends StatefulWidget {
  const AssistantPreferenceTile({super.key});
  @override
  State<AssistantPreferenceTile> createState() =>
      _AssistantPreferenceTileState();
}

class _AssistantPreferenceTileState extends State<AssistantPreferenceTile> {
  bool saving = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final store = HarvestScope.of(context);
    store.assistantPreferences.load(store.account.id);
  }

  @override
  Widget build(BuildContext context) {
    final store = HarvestScope.of(context);
    return ListenableBuilder(
      listenable: store.assistantPreferences,
      builder: (context, _) => SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        secondary: const Icon(Icons.auto_awesome_outlined),
        title: const Text('Show Ola assistant'),
        subtitle: const Text(
          'Show the floating assistant on your dashboard. You can still open the Assistant tab.',
        ),
        value: store.assistantPreferences.enabledFor(store.account.id) ?? false,
        onChanged: saving
            ? null
            : (enabled) async {
                setState(() => saving = true);
                final saved = await store.assistantPreferences.setEnabled(
                  store.account.id,
                  enabled,
                );
                if (!mounted) return;
                setState(() => saving = false);
                if (!saved && context.mounted) {
                  notice(
                    context,
                    'Could not save this preference. Please retry.',
                    isError: true,
                  );
                }
              },
      ),
    );
  }
}
