import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../utils/constants.dart';

class DomaineChip extends StatelessWidget {
  final String domaineId;
  final bool selected;
  final VoidCallback? onTap;
  final AppLocalizations? l10n; // Ajout de l10n en paramètre optionnel

  const DomaineChip(
      {super.key,
      required this.domaineId,
      this.selected = false,
      this.onTap,
      this.l10n});

  @override
  Widget build(BuildContext context) {
    final currentL10n = l10n ??
        AppLocalizations.of(
            context)!; // Utilise le l10n passé ou le récupère du contexte
    final color = AppConstants.domaineColor(domaineId);

    String getTranslatedDomaineLabel(String id) {
      switch (id.toLowerCase()) {
        case 'service':
          return currentL10n.domaineService;
        case 'reception':
          return currentL10n.domaineReception;
        case 'passe':
          return currentL10n.domainePasse;
        case 'attaque':
          return currentL10n.domaineAttaque;
        case 'block':
          return currentL10n.domaineBlock;
        case 'defense':
          return currentL10n.domaineDefense;
        case 'physique':
          return currentL10n.domainePhysique;
        case 'general':
          return currentL10n.domaineGeneral;
        default:
          return id;
      }
    }

    final label = getTranslatedDomaineLabel(domaineId);
    final icon = AppConstants.domaineIcon(domaineId);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : Colors.white,
          border: Border.all(
              color: selected ? color : AppColors.grayLight, width: 1.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected ? color : AppColors.gray)),
          ],
        ),
      ),
    );
  }
}
