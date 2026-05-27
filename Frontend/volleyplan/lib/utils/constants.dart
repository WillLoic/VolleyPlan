import 'package:flutter/material.dart';

class AppColors {
  static const red       = Color(0xFFD72638);
  static const redLight  = Color(0xFFF5E6E8);
  static const redDark   = Color(0xFFB01E2C);
  static const yellow    = Color(0xFFF2B705);
  static const Color yellowDark = Color(0xFFFBC02D); 
  static const yellowLight = Color(0xFFFEF6DC);
  static const charcoal  = Color(0xFF1A1A2E);
  static const gray      = Color(0xFF6B7280);
  static const grayLight = Color(0xFFE5E7EB);
  static const grayXLight= Color(0xFFF3F4F6);
  static const white     = Color(0xFFFFFFFF);
  static const offWhite  = Color(0xFFFAF9F7);
}

class AppConstants {
  // Remplace par ton URL Render en production
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:5000/api',
  );

  static const List<Map<String, dynamic>> domaines = [
    {'id': 'service',   'label': 'Service',   'icon': '🏐', 'color': Color(0xFFD72638)},
    {'id': 'reception', 'label': 'Réception', 'icon': '🤲', 'color': Color(0xFFE85D04)},
    {'id': 'passe',     'label': 'Passe',     'icon': '🙌', 'color': Color(0xFFF2B705)},
    {'id': 'attaque',   'label': 'Attaque',   'icon': '⚡', 'color': Color(0xFF3A86FF)},
    {'id': 'block',     'label': 'Block',     'icon': '🛡️', 'color': Color(0xFF8338EC)},
    {'id': 'defense',   'label': 'Défense',   'icon': '💪', 'color': Color(0xFF06D6A0)},
    {'id': 'physique',  'label': 'Physique',  'icon': '🏋️', 'color': Color(0xFFEF476F)},
    {'id': 'general',   'label': 'Général',   'icon': '🎯', 'color': Color(0xFF6B7280)},
  ];

  static const List<String> postes = [
    'Passeur', 'Libéro', 'Central', 'Pointu',
    'Réceptionneur-Attaquant', 'Universal',
  ];

  static Color domaineColor(String id) {
    final d = domaines.firstWhere((d) => d['id'] == id,
        orElse: () => {'color': const Color(0xFF6B7280)});
    return d['color'] as Color;
  }

  static String domaineLabel(String id) {
    final d = domaines.firstWhere((d) => d['id'] == id,
        orElse: () => {'label': id});
    return d['label'] as String;
  }

  static String domaineIcon(String id) {
    final d = domaines.firstWhere((d) => d['id'] == id,
        orElse: () => {'icon': '🏐'});
    return d['icon'] as String;
  }

  static String fmtMinutes(int minutes) {
    if (minutes <= 0) return '0min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h > 0) return m > 0 ? '${h}h${m.toString().padLeft(2, '0')}min' : '${h}h';
    return '${m}min';
  }
}