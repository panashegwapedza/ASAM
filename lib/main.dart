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

  // ASAM's database is owner-scoped and its RLS policies use auth.uid().
  // Bootstrap an anonymous authenticated session for the development app so
  // the Products screen can persist data without collecting user PII yet.
  if (client.auth.currentSession == null) {
    try {
      await client.auth.signInAnonymously();
    } on AuthException catch (error) {
      debugPrint('Anonymous Supabase sign-in failed: ${error.message}');
    }
  }

  runApp(const AsamApp());
}
