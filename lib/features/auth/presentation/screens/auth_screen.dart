import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_invoice_app/core/services/supabase_service.dart';
import 'package:flutter_invoice_app/features/sync/presentation/providers/sync_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isLogin = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _friendlyError(Object e) {
    final text = e.toString();
    if (text.contains('SocketException') ||
        text.contains('ClientException') ||
        text.contains('Failed host lookup') ||
        text.contains('TimeoutException')) {
      return 'No internet connection. Connect and try again. Your invoices '
          'still work without signing in.';
    }
    return 'Something went wrong. Please try again.';
  }

  void _showError(String message) {
    final scheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: scheme.onError)),
        backgroundColor: scheme.error,
      ),
    );
  }

  Future<void> _submit() async {
    if (_isLoading) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final supabaseService = ref.read(supabaseServiceProvider);

    try {
      if (_isLogin) {
        await supabaseService.signIn(email, password);
        try {
          await ref.read(syncProvider.notifier).sync();
        } catch (_) {
          // Signed in already; the sync can be retried from Settings.
        }
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        await supabaseService.signUp(email, password);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Account created. Check your email to confirm it, then sign in.',
              ),
            ),
          );
          setState(() {
            _isLogin = true;
          });
        }
      }
    } on AuthException catch (e) {
      if (mounted) _showError(e.message);
    } catch (e) {
      if (mounted) _showError(_friendlyError(e));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 800) {
            return _DesktopAuthLayout(
              isLogin: _isLogin,
              isLoading: _isLoading,
              emailController: _emailController,
              passwordController: _passwordController,
              formKey: _formKey,
              onSubmit: _submit,
              onToggleMode: () => setState(() => _isLogin = !_isLogin),
            );
          } else {
            return _MobileAuthLayout(
              isLogin: _isLogin,
              isLoading: _isLoading,
              emailController: _emailController,
              passwordController: _passwordController,
              formKey: _formKey,
              onSubmit: _submit,
              onToggleMode: () => setState(() => _isLogin = !_isLogin),
            );
          }
        },
      ),
    );
  }
}

class _DesktopAuthLayout extends StatelessWidget {
  final bool isLogin;
  final bool isLoading;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final GlobalKey<FormState> formKey;
  final VoidCallback onSubmit;
  final VoidCallback onToggleMode;

  const _DesktopAuthLayout({
    required this.isLogin,
    required this.isLoading,
    required this.emailController,
    required this.passwordController,
    required this.formKey,
    required this.onSubmit,
    required this.onToggleMode,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Illustration Side
        Expanded(
          flex: 12,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF003D40), Color(0xFF006064)],
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(64.0),
                    child: Hero(
                      tag: 'auth_illustration',
                      child: Image.asset(
                        'assets/images/auth_illustration.png',
                        fit: BoxFit.contain,
                        excludeFromSemantics: true,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 40,
                  left: 20,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Back',
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      hoverColor: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                Positioned(
                  top: 46,
                  left: 80,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.bolt,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Invoicer',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Form Side
        Expanded(
          flex: 10,
          child: Container(
            color: Theme.of(context).colorScheme.surface,
            child: Center(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: _AuthForm(
                      isLogin: isLogin,
                      isLoading: isLoading,
                      emailController: emailController,
                      passwordController: passwordController,
                      formKey: formKey,
                      onSubmit: onSubmit,
                      onToggleMode: onToggleMode,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MobileAuthLayout extends StatelessWidget {
  final bool isLogin;
  final bool isLoading;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final GlobalKey<FormState> formKey;
  final VoidCallback onSubmit;
  final VoidCallback onToggleMode;

  const _MobileAuthLayout({
    required this.isLogin,
    required this.isLoading,
    required this.emailController,
    required this.passwordController,
    required this.formKey,
    required this.onSubmit,
    required this.onToggleMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF003D40), Color(0xFF006064)],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              children: [
                // Logo
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Back',
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.bolt,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Invoicer',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48), // Balance for back button
                  ],
                ),
                const SizedBox(height: 32),
                // Illustration (Small)
                SizedBox(
                  height: 160,
                  child: Hero(
                    tag: 'auth_illustration',
                    child: Image.asset(
                      'assets/images/auth_illustration.png',
                      fit: BoxFit.contain,
                      excludeFromSemantics: true,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Form Card
                ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: _AuthForm(
                        isLogin: isLogin,
                        isLoading: isLoading,
                        emailController: emailController,
                        passwordController: passwordController,
                        formKey: formKey,
                        onSubmit: onSubmit,
                        onToggleMode: onToggleMode,
                        isDark: false,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthForm extends StatelessWidget {
  final bool isLogin;
  final bool isLoading;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final GlobalKey<FormState> formKey;
  final VoidCallback onSubmit;
  final VoidCallback onToggleMode;

  /// True when the form sits on the theme surface (desktop); false when it
  /// sits on the fixed light card over the teal gradient (phone).
  final bool isDark;

  const _AuthForm({
    required this.isLogin,
    required this.isLoading,
    required this.emailController,
    required this.passwordController,
    required this.formKey,
    required this.onSubmit,
    required this.onToggleMode,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final titleColor = isDark ? scheme.onSurface : const Color(0xFF003D40);
    final subtitleColor =
        isDark ? scheme.onSurfaceVariant : Colors.grey.shade700;

    return Form(
      key: formKey,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                isLogin ? 'Welcome Back' : 'Create Account',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isLogin
                  ? 'Sign in to back up and sync your invoices. The app works '
                        'without an account.'
                  : 'Create an account to back up and sync your invoices.',
              style: TextStyle(fontSize: 14, color: subtitleColor),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email Address',
                prefixIcon: const Icon(Icons.email_outlined),
                fillColor: isDark ? null : Colors.white,
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: (val) {
                final v = val?.trim() ?? '';
                if (v.isEmpty) return 'Enter your email address';
                if (!v.contains('@') || !v.contains('.')) {
                  return 'Enter a valid email, like name@company.com';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                fillColor: isDark ? null : Colors.white,
              ),
              obscureText: true,
              textInputAction: TextInputAction.done,
              autofillHints: [
                isLogin ? AutofillHints.password : AutofillHints.newPassword,
              ],
              onFieldSubmitted: (_) {
                if (!isLoading) onSubmit();
              },
              validator: (val) {
                if (val == null || val.isEmpty) return 'Enter your password';
                if (!isLogin && val.length < 6) {
                  return 'Use at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isLoading ? null : onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006064),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: isLoading
                    ? Semantics(
                        label: isLogin ? 'Signing in' : 'Creating account',
                        child: const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    : Text(
                        isLogin ? 'Sign In' : 'Create Account',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    isLogin
                        ? "Don't have an account?"
                        : 'Already have an account?',
                    style: TextStyle(color: subtitleColor),
                  ),
                  TextButton(
                    onPressed: isLoading ? null : onToggleMode,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                    ),
                    child: Text(
                      isLogin ? 'Sign Up' : 'Sign In',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? scheme.primary
                            : const Color(0xFF006064),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
