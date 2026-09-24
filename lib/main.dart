import 'package:flutter/material.dart';

import 'customer/app.dart';
export 'customer/app.dart' show HarvestHubApp;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HarvestHubApp());
}
