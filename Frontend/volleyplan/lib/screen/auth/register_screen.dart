import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart'; // Import nécessaire pour TapGestureRecognizer
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../services/app_state.dart';
import '../../utils/constants.dart';
import '../../widgets/vp_button.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nomCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _equipeCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;
  String _completePhoneNumber = "";

  Future<void> _register() async {
    final l10n = AppLocalizations.of(context)!;
    if (_nomCtrl.text.isEmpty ||
        _telCtrl.text.isEmpty ||
        _emailCtrl.text.isEmpty ||
        _equipeCtrl.text.isEmpty ||
        _pwdCtrl.text.isEmpty) {
      setState(() => _error = l10n.fillAllFieldsError);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AppState>().register(
          _nomCtrl.text.trim(),
          _completePhoneNumber.isNotEmpty
              ? _completePhoneNumber
              : _telCtrl.text.trim(),
          _emailCtrl.text.trim(),
          _equipeCtrl.text.trim(),
          _pwdCtrl.text.trim());
      if (mounted) context.go('/tarifs');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
                const SizedBox(height: 32),
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
                      Text(l10n.registerTitle,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.charcoal)),
                      const SizedBox(height: 20),
                      _field(l10n.fullNameField, _nomCtrl, TextInputType.name),
                      const SizedBox(height: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.phoneField,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.charcoal)),
                          const SizedBox(height: 6),
                          IntlPhoneField(
                            controller: _telCtrl,
                            decoration: InputDecoration(
                              filled: true, fillColor: AppColors.grayXLight,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none),
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                      color: AppColors.red, width: 1.5)),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              counterText:
                                  "", // Masque le compteur de caractères
                            ),
                            initialCountryCode:
                                'CM', // Cameroun par défaut comme discuté
                            languageCode: Localizations.localeOf(context).languageCode,
                            disableLengthCheck:
                                true, // NE BLOQUE PAS l'utilisateur sur la longueur
                            invalidNumberMessage:
                                null, // Pas de message d'erreur bloquant
                            autovalidateMode: AutovalidateMode
                                .disabled, // Désactive la validation auto
                            onChanged: (phone) {
                              setState(() {
                                _completePhoneNumber = phone.completeNumber;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _field(l10n.emailField, _emailCtrl, TextInputType.emailAddress),
                      const SizedBox(height: 14),
                      _field(
                          l10n.teamNameField, _equipeCtrl, TextInputType.text),
                      const SizedBox(height: 14),
                      _field(l10n.passwordField, _pwdCtrl, TextInputType.text,
                          obscure: _obscure,
                          suffix: IconButton(
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
                      // --- Nouveau: Message légal ---
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 0), // Ajuste le padding si nécessaire
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            text: l10n.registerTermsPrompt,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.gray,
                            ),
                            children: <TextSpan>[
                              TextSpan(
                                text: l10n.termsTitle,
                                style: const TextStyle(
                                  color: AppColors.red,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () => context.push('/terms'),
                              ),
                              TextSpan(text: l10n.andOurLabel),
                              TextSpan(
                                text: l10n.privacyPolicyLabel,
                                style: const TextStyle(
                                  color: AppColors.red,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () => context.push('/privacy'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      VpButton(
                          label: l10n.registerAction,
                          onPressed: _register,
                          loading: _loading,
                          icon: Icons.person_add),
                      const SizedBox(height: 14),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: Text("${l10n.alreadyAccountPrompt} ${l10n.loginAction}",
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
      {bool obscure = false, Widget? suffix}) {
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
            suffixIcon: suffix,
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
