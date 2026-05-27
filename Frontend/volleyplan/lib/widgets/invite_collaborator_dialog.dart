import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../widgets/vp_button.dart';

class InviteCollaboratorDialog extends StatefulWidget {
  final Function(String email) onInvite;
  const InviteCollaboratorDialog({super.key, required this.onInvite});

  @override
  State<InviteCollaboratorDialog> createState() =>
      _InviteCollaboratorDialogState();
}

class _InviteCollaboratorDialogState extends State<InviteCollaboratorDialog> {
  final _emailCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Inviter un collaborateur',
          style: TextStyle(fontWeight: FontWeight.w800)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
              'Entrez l\'adresse email du coach ou du préparateur physique à inviter sur ce planning.',
              style: TextStyle(fontSize: 13, color: AppColors.gray)),
          const SizedBox(height: 16),
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'email@exemple.com',
              filled: true,
              fillColor: AppColors.grayXLight,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler')),
        VpButton(
          label: 'Envoyer l\'invitation',
          onPressed: () {
            if (_emailCtrl.text.contains('@')) {
              widget.onInvite(_emailCtrl.text.trim());
              Navigator.pop(context);
            }
          },
          small: true,
        ),
      ],
    );
  }
}
