class DomaineActionConfig {
  final Map<String, List<String>> champs;
  const DomaineActionConfig({required this.champs});
}

const Map<String, DomaineActionConfig> domainesActionConfig = {
  'service': DomaineActionConfig(champs: {
    'type_action': ['smashe', 'flottant'],
    'position': ['1', '6', '5'],
    'zone': ['1', '2', '3', '4', '5', '6', '7', '8', '9'],
    'resultat': ['reussi', 'perdu', 'ace', 'degat'],
  }),
  'reception': DomaineActionConfig(champs: {
    'type_action': ['smashe', 'flottant'],
    'position': ['1', '6', '5', 'zone_avant'],
    'qualite': ['bonne', 'moyenne', 'mauvaise', 'point_concede'],
  }),
  'passe': DomaineActionConfig(champs: {
    'position': ['1', '2', '4', '6', 'fixe_avant', 'fixe_arriere', 'decale', 'basket'],
    'qualite': ['bonne', 'moyenne', 'mauvaise'],
    'resultat': ['reussie', 'ratee'],
    'point_direct': ['true', 'false'],
  }),
  'attaque': DomaineActionConfig(champs: {
    'position': ['1', '2', '4', '6', 'fixe_avant', 'fixe_arriere', 'decale', 'basket'],
    'nombre_bloqueurs': ['0', '1', '2', '3'],
    'zone': ['grande_diagonale', 'petite_diagonale', 'ligne', 'fausse_ligne', 'bloc_out', '5', '1', '6'],
    'resultat': ['point_direct', 'contree', 'defendue', 'faute', 'erreur'],
  }),
  'defense': DomaineActionConfig(champs: {
    'position': ['1', '2', '4', '5', '6'],
    'qualite': ['bonne', 'moyenne', 'mauvaise'],
    'puissance_adverse': ['elevee', 'moyenne', 'faible'],
  }),
  'block': DomaineActionConfig(champs: {
    'nombre_bloqueurs': ['1', '2', '3'],
    'position': ['1', '2', '4', '6', 'centre'],
    'resultat': ['gagnant', 'non_gagnant'],
    'touche': ['true', 'false'],
  }),
};


/// Ordre d'affichage recommandé des domaines (cohérence visuelle des tabs)
const List<String> ordreDomainesAction = [
  'service', 'reception', 'passe', 'attaque', 'defense', 'block',
];

