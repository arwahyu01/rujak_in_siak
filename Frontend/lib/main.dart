import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'core/database/app_database.dart';
import 'core/providers.dart';
import 'core/storage/secure_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');

  final store = SecureStore();
  final databaseKey = await store.databaseKey();
  final database = AppDatabase(AppDatabase.openEncrypted(databaseKey));

  runApp(
    ProviderScope(
      overrides: [
        secureStoreProvider.overrideWithValue(store),
        databaseProvider.overrideWithValue(database),
      ],
      child: const RujakApp(),
    ),
  );
}
