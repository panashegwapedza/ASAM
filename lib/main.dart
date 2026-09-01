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

  // Supabase Flutter v2 does not wait for an expired persisted session to
  // refresh during initialize(). Refresh it before deciding that this is a
  // new device/browser session. This prevents the app from silently creating
  // a second anonymous owner and making existing owner-scoped data appear to
  // have disappeared.
  final session = client.auth.currentSession;
  if (session != null && session.isExpired) {
    try {
      await client.auth.refreshSession();
    } on AuthException catch (error) {
      debugPrint('Supabase session refresh failed: ${error.message}');
    }
  }

  // ASAM currently uses an authenticated anonymous session while the
  // development identity/onboarding flow is being built. Supabase persists
  // this session locally; do not create another user when a valid session is
  // already available.
  if (client.auth.currentSession == null) {
    try {
      await client.auth.signInAnonymously();
    } on AuthException catch (error) {
      debugPrint('Anonymous Supabase sign-in failed: ${error.message}');
    }
  }

  runApp(const AsamApp());
}
