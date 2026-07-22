// lib/services/excel_service.dart
import 'dart:io' as io;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'api_service.dart';

class ExcelService {
  static Future<void> downloadPlanningExcel(int planningId) async {
    // 1. On récupère les bytes via ApiService (inclut automatiquement le token JWT)
    final bytes = await ApiService.getBytes('/plannings/$planningId/export/excel');

    const mimeType =
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

    if (kIsWeb) {
      // LOGIQUE WEB : Téléchargement direct
      final blob = html.Blob([bytes], mimeType);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute("download", "planning_$planningId.xlsx")
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      // LOGIQUE MOBILE : Partage / Enregistrement
      final dir = await getTemporaryDirectory();
      final file = io.File('${dir.path}/planning_$planningId.xlsx');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)],
          text: 'Mon planning VolleyPlan (Excel)');
    }
  }
}