import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/auth_notifier.dart';
import 'providers/inventory_notifier.dart';
import 'providers/settings_notifier.dart';
import 'services/firebase_service.dart';
import 'services/settings_service.dart';
import 'widgets/bootstrap_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final auth = AuthNotifier();
  final firebaseService = FirebaseService();
  final settingsService = SettingsService();
  final inventory = InventoryNotifier(firebaseService, auth);
  final settings = SettingsNotifier(settingsService);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider.value(value: inventory),
        ChangeNotifierProvider.value(value: settings),
      ],
      child: const BootstrapGate(),
    ),
  );
}
