import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, this.isAnonymous = false});

  final bool isAnonymous;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _signUp = false;
  bool _busy = false;
  bool _obscure = true;
  String? _message;
  bool _messageIsError = false;

  SupabaseClient get _client => Supabase.instance.client;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _busy) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _message = null;
    });

    try {
      if (widget.isAnonymous) {
        await _claimWorkspace();
      } else if (_signUp) {
        final response = await _client.auth.signUp(
          email: _email.text.trim(),
          password: _password.text,
        );
        if (!mounted) return;
        if (response.session == null) {
          _showMessage('Account created. Check your email to confirm the account, then return to Wren.');
        }
      } else {
        await _client.auth.signInWithPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
      }
    } on AuthException catch (error) {
      if (mounted) _showMessage(error.message, error: true);
    } catch (error) {
      if (mounted) _showMessage(error.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _claimWorkspace() async {
    final user = _client.auth.currentUser;
    if (user == null || !user.isAnonymous) {
      throw AuthException('The temporary Wren workspace is no longer available.');
    }

    await _client.auth.updateUser(
      UserAttributes(email: _email.text.trim()),
    );

    if (!mounted) return;
    _showMessage('Confirmation email sent. Open it to secure this workspace. Your existing Wren data will stay attached to this account.');
  }

  void _showMessage(String message, {bool error = false}) {
    setState(() {
      _message = message;
      _messageIsError = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final claim = widget.isAnonymous;
    final title = claim ? 'Secure your Wren workspace' : (_signUp ? 'Create your Wren account' : 'Welcome to Wren');
    final subtitle = claim
        ? 'Your current workspace is temporary. Add your email so your products, clients and orders remain tied to you.'
        : (_signUp
            ? 'Create a permanent account for your Wren workspace.'
            : 'Sign in to continue to your sales and marketing workspace.');

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF4F6F4), Color(0xFFE8EEF0)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1040),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 60, 20),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('wren•', style: TextStyle(fontSize: 42, height: 1, fontWeight: FontWeight.w900, letterSpacing: -2, color: Color(0xFF294B68))),
                          const SizedBox(height: 28),
                          const Text('Sales and marketing intelligence.', style: TextStyle(fontSize: 34, height: 1.08, fontWeight: FontWeight.w800, letterSpacing: -1)),
                          const SizedBox(height: 12),
                          const Text('One workspace for clients, products, orders, marketing activity and the signals that tell you what to do next.', style: TextStyle(fontSize: 16, height: 1.5, color: Color(0xFF69736D))),
                          const SizedBox(height: 30),
                          Row(children: [
                            _AuthPill(icon: Icons.people_outline, label: 'Clients'),
                            const SizedBox(width: 8),
                            _AuthPill(icon: Icons.inventory_2_outlined, label: 'Products'),
                            const SizedBox(width: 8),
                            _AuthPill(icon: Icons.auto_awesome_outlined, label: 'Intelligence'),
                          ]),
                        ]),
                      ),
                    ),
                    SizedBox(
                      width: 430,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(30),
                          child: Form(
                            key: _formKey,
                            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                              Text(title, style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 8),
                              Text(subtitle, style: const TextStyle(fontSize: 14, height: 1.45, color: Color(0xFF69736D))),
                              if (claim) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(13),
                                  decoration: BoxDecoration(color: const Color(0xFFFFF6E6), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE8C47A))),
                                  child: const Text('Keep this browser session until your confirmation email is completed.', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                ),
                              ],
                              const SizedBox(height: 24),
                              TextFormField(
                                controller: _email,
                                enabled: !_busy,
                                keyboardType: TextInputType.emailAddress,
                                autofillHints: const [AutofillHints.email],
                                decoration: const InputDecoration(labelText: 'Email address', prefixIcon: Icon(Icons.email_outlined)),
                                validator: (value) {
                                  final email = value?.trim() ?? '';
                                  if (email.isEmpty || !email.contains('@')) return 'Enter a valid email address.';
                                  return null;
                                },
                              ),
                              if (!claim) ...[
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _password,
                                  enabled: !_busy,
                                  obscureText: _obscure,
                                  autofillHints: _signUp ? const [AutofillHints.newPassword] : const [AutofillHints.password],
                                  decoration: InputDecoration(labelText: 'Password', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(onPressed: () => setState(() => _obscure = !_obscure), icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined))),
                                  validator: (value) => (value ?? '').length < 8 ? 'Password must be at least 8 characters.' : null,
                                ),
                                if (_signUp) ...[
                                  const SizedBox(height: 12),
                                  TextFormField(controller: _confirmPassword, enabled: !_busy, obscureText: _obscure, decoration: const InputDecoration(labelText: 'Confirm password', prefixIcon: Icon(Icons.lock_reset_outlined)), validator: (value) => value != _password.text ? 'Passwords do not match.' : null),
                                ],
                              ],
                              if (_message != null) ...[
                                const SizedBox(height: 16),
                                Container(padding: const EdgeInsets.all(13), decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: _messageIsError ? const Color(0xFFFFEEEE) : const Color(0xFFEAF5EE), border: Border.all(color: _messageIsError ? const Color(0xFFE1A5A5) : const Color(0xFFA8D0B7))), child: Text(_message!, style: const TextStyle(fontSize: 13))),
                              ],
                              const SizedBox(height: 20),
                              FilledButton.icon(
                                onPressed: _busy ? null : _submit,
                                icon: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(claim ? Icons.verified_user_outlined : (_signUp ? Icons.person_add_outlined : Icons.login)),
                                label: Text(_busy ? 'Working…' : (claim ? 'Secure Workspace' : (_signUp ? 'Create Account' : 'Sign In'))),
                              ),
                              if (!claim) ...[
                                const SizedBox(height: 10),
                                TextButton(onPressed: _busy ? null : () => setState(() { _signUp = !_signUp; _message = null; }), child: Text(_signUp ? 'Already have an account? Sign in' : 'New to Wren? Create an account')),
                              ],
                            ]),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthPill extends StatelessWidget {
  const _AuthPill({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(11), border: Border.all(color: const Color(0xFFD6DEDA))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 17, color: const Color(0xFF294B68)), const SizedBox(width: 6), Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))]),
  );
