class SupabaseConfig {
  const SupabaseConfig._();

  // The publishable key is intended for use in client applications.
  // Build-time values still take precedence, so deployments can override these.
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://uckwrngfdibugwrhvagl.supabase.co',
  );

  static const String publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_Cp62FhbYisA0Pmjxw-Iw1g_YFLnGPPt',
  );
}
