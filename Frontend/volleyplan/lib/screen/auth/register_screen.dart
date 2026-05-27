import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/app_state.dart';
import '../../utils/constants.dart';
import '../../widgets/vp_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nomCtrl      = TextEditingController();
  final _telCtrl      = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _equipeCtrl   = TextEditingController();
  final _pwdCtrl      = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  Future<void> _register() async {
    if (_nomCtrl.text.isEmpty || _telCtrl.text.isEmpty || _emailCtrl.text.isEmpty || _equipeCtrl.text.isEmpty || _pwdCtrl.text.isEmpty) {
      setState(() => _error = 'Veuillez remplir tous les champs.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await context.read<AppState>().register(
        _nomCtrl.text.trim(), _telCtrl.text.trim(), _emailCtrl.text.trim(), _equipeCtrl.text.trim(), _pwdCtrl.text.trim()
      );
      if (mounted) context.go('/home');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              children: [
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.red, AppColors.yellow]),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Center(child: Text('🏐', style: TextStyle(fontSize: 36))),
                ),
                const SizedBox(height: 16),
                const Text('VolleyPlan', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.charcoal)),
                const SizedBox(height: 32),

                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 20)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Créer un compte', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.charcoal)),
                      const SizedBox(height: 20),

                      _field('Nom du coach', _nomCtrl, TextInputType.name),
                      const SizedBox(height: 14),
                      _field('Numéro de téléphone', _telCtrl, TextInputType.phone),
                      const SizedBox(height: 14),
                      _field('Email', _emailCtrl, TextInputType.emailAddress),
                      const SizedBox(height: 14),
                      _field("Nom de l'équipe", _equipeCtrl, TextInputType.text),
                      const SizedBox(height: 14),
                      _field('Mot de passe', _pwdCtrl, TextInputType.text, obscure: _obscure, suffix: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: AppColors.gray),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      )),

                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: AppColors.redLight, borderRadius: BorderRadius.circular(8)),
                          child: Text(_error!, style: const TextStyle(color: AppColors.red, fontSize: 13)),
                        ),
                      ],

                      const SizedBox(height: 24),
                      VpButton(label: "S'inscrire", onPressed: _register, loading: _loading, icon: Icons.person_add),
                      const SizedBox(height: 14),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: const Text('Déjà un compte ? Se connecter', style: TextStyle(color: AppColors.red)),
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

  Widget _field(String label, TextEditingController ctrl, TextInputType type, {bool obscure = false, Widget? suffix}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.charcoal)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: type,
          obscureText: obscure,
          decoration: InputDecoration(
            suffixIcon: suffix,
            filled: true, fillColor: AppColors.grayXLight,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.red, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}