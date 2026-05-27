// lib/screen/invitation_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/invitation_service.dart';
import '../utils/constants.dart';
import '../widgets/vp_button.dart';

class InvitationScreen extends StatefulWidget {
  final String token;
  const InvitationScreen({super.key, required this.token});

  @override
  State<InvitationScreen> createState() => _InvitationScreenState();
}

class _InvitationScreenState extends State<InvitationScreen> {
  bool _loading = true;
  Map<String, dynamic>? _invitation;

  @override
  void initState() {
    super.initState();
    _checkToken();
  }

  Future<void> _checkToken() async {
    try {
      final res = await InvitationService.validateToken(widget.token);
      setState(() {
        _invitation = res;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_invitation == null)
      return const Scaffold(
          body: Center(child: Text('Invitation invalide ou expirée.')));

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
          title: const Text('Invitation VolleyPlan'),
          backgroundColor: AppColors.charcoal,
          foregroundColor: Colors.white),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🏐', style: TextStyle(fontSize: 50)),
            const SizedBox(height: 16),
            Text('Vous avez été invité sur le planning',
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            VpButton(
              label: 'Accéder au planning',
              onPressed: () async {
                try {
                  final appState = context.read<AppState>();
                  await appState.acceptInvitation(widget.token);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text(
                            'Invitation acceptée ! Bienvenue dans le staff.')));
                    context.go('/collaborations/${widget.token}');
                  }
                } catch (e) {
                  if (mounted)
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Erreur : $e'),
                        backgroundColor: AppColors.red));
                }
              },
            ),
          ]),
        ),
      ),
    );
  }
}
