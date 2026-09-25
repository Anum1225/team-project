import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase_options.dart';
import 'app.dart';
import 'services/firebase_customer_service.dart';
import 'state/customer_store.dart';
import 'theme/customer_theme.dart';

class CustomerBootstrap extends StatefulWidget {
  const CustomerBootstrap({super.key});
  @override
  State<CustomerBootstrap> createState() => _CustomerBootstrapState();
}

class _CustomerBootstrapState extends State<CustomerBootstrap> {
  late final initialization = initialize();
  Future<CustomerStore> initialize() async {
    SharedPreferences? preferences;
    try {
      preferences = await SharedPreferences.getInstance();
      final app = await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      final service = FirebaseCustomerService(
        FirebaseAuth.instanceFor(app: app),
        FirebaseFirestore.instanceFor(app: app),
      );
      final store = CustomerStore.connected(service, preferences);
      await store.restore();
      return store;
    } catch (error) {
      final store = CustomerStore()
        ..preferences = preferences
        ..connectionError = FirebaseCustomerService.errorMessage(error);
      await store.restore();
      return store;
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<CustomerStore>(
    future: initialization,
    builder: (context, snapshot) => snapshot.hasData
        ? HarvestHubApp(store: snapshot.data!)
        : MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: customerTheme(),
            home: const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          ),
  );
}
