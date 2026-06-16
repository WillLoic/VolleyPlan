import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.inviteCollaboratorTitle,
          style: const TextStyle(fontWeight: FontWeight.w800)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.inviteCollaboratorSubtitle,
              style: const TextStyle(fontSize: 13, color: AppColors.gray)),
          const SizedBox(height: 16),
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: l10n.inviteEmailHint,
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
            child: Text(l10n.cancelButton)),
        VpButton(
          label: l10n.inviteSendAction,
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
