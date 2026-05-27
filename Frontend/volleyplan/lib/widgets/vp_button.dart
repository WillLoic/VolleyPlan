import 'package:flutter/material.dart';
import '../utils/constants.dart';

enum VpButtonVariant { primary, secondary, ghost, danger }

class VpButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final VpButtonVariant variant;
  final bool loading;
  final IconData? icon;
  final bool small;

  const VpButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = VpButtonVariant.primary,
    this.loading = false,
    this.icon,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = {
      VpButtonVariant.primary:   [AppColors.red, Colors.white],
      VpButtonVariant.secondary: [AppColors.yellow, AppColors.charcoal],
      VpButtonVariant.ghost:     [Colors.transparent, AppColors.red],
      VpButtonVariant.danger:    [const Color(0xFFfee2e2), AppColors.redDark],
    };
    final bg = colors[variant]![0];
    final fg = colors[variant]![1];

    return SizedBox(
      height: small ? 36 : 46,
      child: ElevatedButton.icon(
        onPressed: loading ? null : onPressed,
        icon: loading
            ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: fg))
            : (icon != null ? Icon(icon, size: small ? 16 : 18, color: fg) : const SizedBox.shrink()),
        label: Text(label, style: TextStyle(fontSize: small ? 13 : 15, fontWeight: FontWeight.w700, color: fg)),
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: variant == VpButtonVariant.primary ? 3 : 0,
          padding: EdgeInsets.symmetric(horizontal: small ? 14 : 22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: variant == VpButtonVariant.ghost ? BorderSide(color: AppColors.red, width: 2) : BorderSide.none,
          ),
        ),
      ),
    );
  }
}