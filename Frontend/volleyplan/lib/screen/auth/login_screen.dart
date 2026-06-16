import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../services/app_state.dart';
import '../../utils/constants.dart';
import '../../widgets/vp_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _telCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AppState>().login(_telCtrl.text.trim(), _pwdCtrl.text);
      if (mounted) context.go('/home');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.forgotPasswordTitle,
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                l10n.forgotPasswordMessage),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                  labelText: l10n.emailField, border: const OutlineInputBorder()),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancelAction)),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty || !email.contains('@')) return;

              try {
                await context.read<AppState>().requestPasswordReset(email);
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          l10n.emailSentMessage),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Erreur : ${e.toString()}"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text("Envoyer"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              children: [
                // Logo
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [AppColors.red, AppColors.yellow]),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Center(
                      child: Text('🏐', style: TextStyle(fontSize: 36))),
                ),
                const SizedBox(height: 16),
                const Text('VolleyPlan',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppColors.charcoal)),
                Text(l10n.landingHeroBadge,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.yellow,
                        letterSpacing: 2)),
                const SizedBox(height: 40),

                // Card
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.07), blurRadius: 20)
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(l10n.loginTitle,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.charcoal)),
                      const SizedBox(height: 20),
                      _field(
                          l10n.emailField, _telCtrl, TextInputType.emailAddress),
                      const SizedBox(height: 14),
                      _field(l10n.passwordField, _pwdCtrl, TextInputType.text,
                          obscure: _obscure,
                          suffixIcon: IconButton(
                            icon: Icon(
                                _obscure
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: AppColors.gray),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          )),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: AppColors.redLight,
                              borderRadius: BorderRadius.circular(8)),
                          child: Text(_error!,
                              style: const TextStyle(
                                  color: AppColors.red, fontSize: 13)),
                        ),
                      ],
                      const SizedBox(height: 24),
                      VpButton(
                          label: l10n.loginAction,
                          onPressed: _login,
                          loading: _loading,
                          icon: Icons.login),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _showForgotPasswordDialog,
                        child: Text(l10n.forgotPasswordLink,
                            style:
                                const TextStyle(color: AppColors.gray, fontSize: 13)),
                      ),
                      const SizedBox(height: 14),
                      TextButton(
                        onPressed: () => context.go('/register'),
                        child: Text("${l10n.noAccountPrompt} ${l10n.registerAction}",
                            style: const TextStyle(color: AppColors.red)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, TextInputType type,
      {bool obscure = false, Widget? suffixIcon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.charcoal)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: type,
          obscureText: obscure,
          decoration: InputDecoration(
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: AppColors.grayXLight,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.red, width: 1.5)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}
