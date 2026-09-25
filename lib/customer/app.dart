import 'package:flutter/material.dart';

import 'screens/welcome_screen.dart';
import 'screens/customer_shell.dart';
import 'state/customer_store.dart';
import 'theme/customer_theme.dart';

class HarvestHubApp extends StatefulWidget {
  const HarvestHubApp({super.key, this.store});
  final CustomerStore? store;
  @override
  State<HarvestHubApp> createState() => _HarvestHubAppState();
}

class _HarvestHubAppState extends State<HarvestHubApp> {
  late final store = widget.store ?? CustomerStore();
  @override
  void dispose() {
    store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'HarvestHub · Fresh from your community',
    debugShowCheckedModeBanner: false,
    theme: customerTheme(),
    home: store.isDemo
        ? WelcomeScreen(store: store)
        : CustomerShell(store: store),
  );
}
