import 'package:flutter/material.dart';
import '../utils/constants.dart';

class DomaineChip extends StatelessWidget {
  final String domaineId;
  final bool selected;
  final VoidCallback? onTap;

  const DomaineChip({super.key, required this.domaineId, this.selected = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = AppConstants.domaineColor(domaineId);
    final label = AppConstants.domaineLabel(domaineId);
    final icon  = AppConstants.domaineIcon(domaineId);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : Colors.white,
          border: Border.all(color: selected ? color : AppColors.grayLight, width: 1.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: selected ? color : AppColors.gray)),
          ],
        ),
      ),
    );
  }
}