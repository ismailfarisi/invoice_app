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
  bool _isLoading = false;
  bool _isLogin = true;

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final supabaseService = ref.read(supabaseServiceProvider);

    try {
      if (_isLogin) {
        await supabaseService.signIn(email, password);
        await ref.read(syncProvider.notifier).sync();
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        await supabaseService.signUp(email, password);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Sign up successful! Please check your email/login.',
              ),
            ),
          );
          setState(() {
            _isLogin = true;
          });
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
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
              onSubmit: _submit,
              onToggleMode: () => setState(() => _isLogin = !_isLogin),
            );
          } else {
            return _MobileAuthLayout(
              isLogin: _isLogin,
              isLoading: _isLoading,
              emailController: _emailController,
              passwordController: _passwordController,
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
  final VoidCallback onSubmit;
  final VoidCallback onToggleMode;

  const _DesktopAuthLayout({
    required this.isLogin,
    required this.isLoading,
    required this.emailController,
    required this.passwordController,
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
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 40,
                  left: 20,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
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
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: _AuthForm(
                    isLogin: isLogin,
                    isLoading: isLoading,
                    emailController: emailController,
                    passwordController: passwordController,
                    onSubmit: onSubmit,
                    onToggleMode: onToggleMode,
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
  final VoidCallback onSubmit;
  final VoidCallback onToggleMode;

  const _MobileAuthLayout({
    required this.isLogin,
    required this.isLoading,
    required this.emailController,
    required this.passwordController,
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              children: [
                // Logo
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
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
                const SizedBox(height: 48),
                // Illustration (Small)
                SizedBox(
                  height: 200,
                  child: Hero(
                    tag: 'auth_illustration',
                    child: Image.asset(
                      'assets/images/auth_illustration.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // Form Card
                ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
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
  final VoidCallback onSubmit;
  final VoidCallback onToggleMode;
  final bool isDark;

  const _AuthForm({
    required this.isLogin,
    required this.isLoading,
    required this.emailController,
    required this.passwordController,
    required this.onSubmit,
    required this.onToggleMode,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = isDark ? null : const Color(0xFF003D40);
    final subtitleColor = isDark ? Colors.grey.shade600 : Colors.grey.shade700;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isLogin ? 'Welcome Back' : 'Create Account',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: titleColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isLogin
              ? 'Please sign in to continue managing your invoices.'
              : 'Join us and start invoicing professionally today.',
          style: TextStyle(fontSize: 14, color: subtitleColor),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: emailController,
          decoration: InputDecoration(
            labelText: 'Email Address',
            prefixIcon: const Icon(Icons.email_outlined),
            fillColor: isDark ? null : Colors.white,
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 20),
        TextField(
          controller: passwordController,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline),
            fillColor: isDark ? null : Colors.white,
          ),
          obscureText: true,
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
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
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
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isLogin ? "Don't have an account? " : "Already have an account? ",
              style: TextStyle(color: subtitleColor),
            ),
            TextButton(
              onPressed: onToggleMode,
              child: Text(
                isLogin ? 'Sign Up' : 'Login',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF006064),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
