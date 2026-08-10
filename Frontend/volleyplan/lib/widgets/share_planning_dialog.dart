import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/analytics_service.dart';
import '../services/app_state.dart';
import '../services/partage_service.dart';
import '../utils/constants.dart';
import 'vp_button.dart';

class SharePlanningDialog extends StatefulWidget {
  final int planningId;

  const SharePlanningDialog({super.key, required this.planningId});

  @override
  State<SharePlanningDialog> createState() => _SharePlanningDialogState();
}

class _SharePlanningDialogState extends State<SharePlanningDialog> {
  bool _loading = true;
  String? _url;
  DateTime? _expiresAt;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLienExistant();
  }

  Future<void> _loadLienExistant() async {
    setState(() => _loading = true);
    try {
      final res = await PartageService.getLienActuel(widget.planningId);
      if (res['partage'] == null) {
        // Aucun lien encore généré → on en crée un directement
        await _genererLien();
      } else {
        setState(() {
          _url = res['url'];
          _expiresAt = DateTime.parse(res['expires_at']);
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _genererLien({bool regenerated = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await PartageService.genererLien(widget.planningId);
      final token = context.read<AppState>().token;
      AnalyticsService.trackEvent(
        'planning_share_generated',
        data: {
          'planning_id': widget.planningId,
          'regenerated': regenerated,
        },
        token: token,
      );
      setState(() {
        _url = res['url'];
        _expiresAt = DateTime.parse(res['expires_at']);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _copyLink() {
    if (_url == null) return;
    Clipboard.setData(ClipboardData(text: _url!));
    AnalyticsService.trackEvent(
      'planning_share_copied',
      data: {'planning_id': widget.planningId},
      token: context.read<AppState>().token,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.linkCopied)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.sharePlanningTitle,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.charcoal)),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.gray),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Center(
                  child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: AppColors.red),
              ))
            else if (_error != null)
              Text(_error!, style: const TextStyle(color: AppColors.red))
            else ...[
              Text(l10n.sharePlanningReadOnlyNotice,
                  style: const TextStyle(fontSize: 13, color: AppColors.gray)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.grayXLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _url ?? '',
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18, color: AppColors.red),
                      onPressed: _copyLink,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (_expiresAt != null)
                Text(
                  l10n.linkExpiresOn(
                      DateFormat('dd/MM/yyyy').format(_expiresAt!)),
                  style: const TextStyle(fontSize: 12, color: AppColors.gray),
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: VpButton(
                  label: l10n.regenerateLinkButton,
                  variant: VpButtonVariant.ghost,
                  onPressed: () => _genererLien(regenerated: true),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}