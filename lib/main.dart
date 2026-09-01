import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/supabase/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );

  final client = Supabase.instance.client;

  // Restore a persisted permanent session and refresh it when necessary.
  // A missing session is intentionally handled by AuthGate; ASAM no longer
  // creates disposable anonymous users at startup.
  final session = client.auth.currentSession;
  if (session != null && session.isExpired) {
    try {
      await client.auth.refreshSession();
    } on AuthException catch (error) {
      debugPrint('Supabase session refresh failed: ${error.message}');
    }
  }

  runApp(const AsamApp());
}
