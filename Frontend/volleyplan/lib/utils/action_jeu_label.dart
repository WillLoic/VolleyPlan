// lib/utils/action_jeu_labels.dart
//
// Traduit les valeurs internes (clés) définies dans domaines_action_config.dart
// vers des libellés lisibles, en français et anglais.
// Centralisé ici pour éviter de dupliquer la logique dans chaque écran.

class ActionJeuLabels {
  static String champLabel(String champ, String localeCode, {String? domaine}) {
    if (champ == 'qualite') {
      if (domaine == 'passe') {
        return localeCode == 'en' ? 'Quality of reception' : 'Qualité de la réception';
      } else if (domaine == 'reception') {
        return localeCode == 'en' ? 'Reception quality' : 'Qualité de la réception';
      } else if (domaine == 'defense') {
        return localeCode == 'en' ? 'Defense quality' : 'Qualité de la défense';
      }
    }
    final fr = {
      'position': 'Poste ou Position',
      'type_action': 'Type',
      'zone': 'Zone',
      'qualite': 'Qualité',
      //'qualite_reception': 'Qualité de la reception',
      'resultat': 'Résultat',
      'point_direct': 'Point direct',
      'touche': 'Touché',
      'nombre_bloqueurs': 'Nombre de Bloqueurs',
      'puissance_adverse': 'Puissance adverse',
    };
    final en = {
      'position': 'Post or Position',
      'type_action': 'Type',
      'zone': 'Zone',
      'qualite': 'Quality',
      'qualite_reception': 'Quality of reception',
      'resultat': 'Result',
      'point_direct': 'Direct point',
      'touche': 'Touched',
      'nombre_bloqueurs': 'Blockers',
      'puissance_adverse': 'Opponent power',
    };
    final map = localeCode == 'en' ? en : fr;
    return map[champ] ?? champ;
  }

  static String valeurLabel(String valeur, String localeCode) {
    final fr = <String, String>{
      // Communs
      'true': 'Oui', 'false': 'Non',
      'zone_avant': 'Zone avant', 'centre': 'Centre',
      'fixe_avant': 'Fixe avant', 'fixe_arriere': 'Fixe arrière',
      'decale': 'Décalé', 'basket': 'Basket',
      // Type / qualité
      'smashe': 'Smashé', 'flottant': 'Flottant',
      'bonne': 'Bonne', 'moyenne': 'Moyenne', 'mauvaise': 'Mauvaise',
      'point_concede': 'Point concédé',
      'elevee': 'Élevée', 'faible': 'Faible',
      // Résultats
      'reussi': 'Réussi', 'perdu': 'Perdu', 'ace': 'Ace', 'degat': 'Dégat', //
      'reussie': 'Réussie', 'ratee': 'Ratée',
      'point_direct': 'Point direct', 'contree': 'Contrée',
      'defendue': 'Défendue', 'faute': 'Faute', 'erreur': 'Erreur', //
      'gagnant': 'Gagnant', 'non_gagnant': 'Non gagnant',
      // Zones d'attaque
      'grande_diagonale': 'Grande diagonale',
      'petite_diagonale': 'Petite diagonale',
      'ligne': 'Ligne', 'fausse_ligne': 'Fausse ligne', 'bloc_out': 'Bloc-out',
    };
    final en = <String, String>{
      'true': 'Yes', 'false': 'No',
      'zone_avant': 'Front zone', 'centre': 'Middle',
      'fixe_avant': 'Front quick', 'fixe_arriere': 'Back quick',
      'decale': 'Shifted', 'basket': 'High set',
      'smashe': 'Jump serve', 'flottant': 'Float',
      'bonne': 'Good', 'moyenne': 'Average', 'mauvaise': 'Bad',
      'point_concede': 'Point lost',
      'elevee': 'High', 'faible': 'Low',
      'reussi': 'In', 'perdu': 'Fault', 'ace': 'Ace', 'degat': 'Damage', //
      'reussie': 'Successful', 'ratee': 'Missed',
      'point_direct': 'Kill', 'contree': 'Blocked',
      'defendue': 'Dug', 'faute': 'Fault', 'erreur': 'Error', //
      'gagnant': 'Kill block', 'non_gagnant': 'No kill',
      'grande_diagonale': 'Long diagonal', 'petite_diagonale': 'Short diagonal',
      'ligne': 'Line', 'fausse_ligne': 'Sharp line', 'bloc_out': 'Block-out',
    };
    final map = localeCode == 'en' ? en : fr;
    return map[valeur] ??
        valeur; // fallback: chiffres (zones, postes) affichés tels quels
  }

  static String domaineLabel(String domaine, String localeCode) {
    final fr = {
      'service': 'Service',
      'reception': 'Réception',
      'passe': 'Passe',
      'attaque': 'Attaque',
      'defense': 'Défense',
      'block': 'Block',
    };
    final en = {
      'service': 'Serve',
      'reception': 'Reception',
      'passe': 'Set',
      'attaque': 'Attack',
      'defense': 'Defense',
      'block': 'Block',
    };
    final map = localeCode == 'en' ? en : fr;
    return map[domaine] ?? domaine;
  }
}
