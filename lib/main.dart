import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'firebase_options.dart';

import 'src/app.dart';
export 'src/app.dart' show HarvestHubApp;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _Bootstrap());
}

class _Bootstrap extends StatefulWidget {
  const _Bootstrap();
  @override
  State<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<_Bootstrap> {
  late Future<void> ready = initialize();
  Future<void> initialize() async {
    const host = String.fromEnvironment('FIREBASE_EMULATOR_HOST');
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: host.isEmpty ? DefaultFirebaseOptions.currentPlatform : const FirebaseOptions(
          apiKey: 'emulator-only-key', appId: '1:123456789:web:harvesthub', messagingSenderId: '123456789',
          projectId: 'demo-harvesthub', storageBucket: 'demo-harvesthub.appspot.com',
        ),
      );
    }
    if (host.isNotEmpty) {
      await FirebaseAuth.instance.useAuthEmulator(host, 9099);
      FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
      FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);
      await FirebaseStorage.instance.useStorageEmulator(host, 9199);
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: ready,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.done &&
          !snapshot.hasError) {
        return const HarvestHubApp();
      }
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: snapshot.hasError
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Unable to initialize HarvestHub.'),
                      TextButton(
                        onPressed: () => setState(() => ready = initialize()),
                        child: const Text('Retry'),
                      ),
                    ],
                  )
                : const CircularProgressIndicator(),
          ),
        ),
      );
    },
  );
}
