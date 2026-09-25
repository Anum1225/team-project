import 'package:flutter/material.dart';

import 'customer/bootstrap.dart';
export 'customer/app.dart' show HarvestHubApp;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CustomerBootstrap());
}
