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
          _showMessage('Account created. Check your email to confirm the account, then return to ASAM.');
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
      throw AuthException('The temporary ASAM workspace is no longer available.');
    }

    await _client.auth.updateUser(
      UserAttributes(email: _email.text.trim()),
    );

    if (!mounted) return;
    _showMessage('Confirmation email sent. Open it to secure this workspace. Your existing ASAM data will stay attached to this account.');
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
    final title = claim ? 'Secure your ASAM workspace' : (_signUp ? 'Create your ASAM account' : 'Sign in to ASAM');
    final subtitle = claim
        ? 'Your current workspace is temporary. Add your email so your products, clients, and orders remain tied to you.'
        : (_signUp
            ? 'Create a permanent account for your ASAM workspace.'
            : 'Use your ASAM account to access your data from this device or another device.');

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(Icons.storefront_outlined, size: 52),
                        const SizedBox(height: 20),
                        Text(title, style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 8),
                        Text(subtitle),
                        if (claim) ...[
                          const SizedBox(height: 16),
                          const Text('Important: do not clear this browser/device session until the email is confirmed.', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _email,
                          enabled: !_busy,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
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
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                onPressed: () => setState(() => _obscure = !_obscure),
                                icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                              ),
                            ),
                            validator: (value) => (value ?? '').length < 8 ? 'Password must be at least 8 characters.' : null,
                          ),
                          if (_signUp) ...[
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _confirmPassword,
                              enabled: !_busy,
                              obscureText: _obscure,
                              decoration: const InputDecoration(labelText: 'Confirm password', prefixIcon: Icon(Icons.lock_reset_outlined)),
                              validator: (value) => value != _password.text ? 'Passwords do not match.' : null,
                            ),
                          ],
                        ],
                        if (_message != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _messageIsError ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.outline),
                            ),
                            child: Text(_message!),
                          ),
                        ],
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: _busy ? null : _submit,
                          icon: _busy
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : Icon(claim ? Icons.verified_user_outlined : (_signUp ? Icons.person_add_outlined : Icons.login)),
                          label: Text(_busy ? 'Working…' : (claim ? 'Secure Workspace' : (_signUp ? 'Create Account' : 'Sign In'))),
                        ),
                        if (!claim) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _busy ? null : () => setState(() {
                              _signUp = !_signUp;
                              _message = null;
                            }),
                            child: Text(_signUp ? 'Already have an account? Sign in' : 'New to ASAM? Create an account'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
