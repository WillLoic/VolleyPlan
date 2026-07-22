"""
Configuration déclarative des domaines supportant la saisie d'action de jeu.
SOURCE DE VÉRITÉ — toute modification ici doit être répercutée à l'identique
dans le fichier Dart équivalent côté frontend.
"""

DOMAINES_ACTION_CONFIG = {
    "service": {
        "champs": {
            "type_action": ["smashe", "flottant"],
            "position":    ["1", "6", "5"],
            "zone":        ["1", "2", "3", "4", "5", "6", "7", "8", "9"],
            "resultat":    ["reussi", "perdu", "ace", "degat"],
        }
    },
    "reception": {
        "champs": {
            "type_action": ["smashe", "flottant"],
            "position":    ["1", "6", "5", "zone_avant"],
            "qualite":     ["bonne", "moyenne", "mauvaise", "point_concede"],
        }
    },
    "passe": {
        "champs": {
            "position":     ["1", "2", "4", "6", "fixe_avant", "fixe_arriere", "decale", "basket"],
            "qualite":      ["bonne", "moyenne", "mauvaise"],
            "resultat":     ["reussie", "ratee"],
            "point_direct": ["true", "false"],  # traité comme booléen à la validation
        }
    },
    "attaque": {
        "champs": {
            "position":         ["1", "2", "4", "6", "fixe_avant", "fixe_arriere", "decale", "basket"],
            "nombre_bloqueurs": ["0", "1", "2", "3"],
            "zone":             ["grande_diagonale", "petite_diagonale", "ligne", "fausse_ligne", "bloc_out", "5", "1", "6"],
            "resultat":         ["point_direct", "contree", "defendue", "faute", "erreur"],
        }
    },
    "defense": {
        "champs": {
            "position":         ["1", "2", "4", "5", "6"],
            "qualite":          ["bonne", "moyenne", "mauvaise"],
            "puissance_adverse": ["elevee", "moyenne", "faible"],
        }
    },
    "block": {
        "champs": {
            "nombre_bloqueurs": ["1", "2", "3"],
            "position":         ["1", "2", "4", "6", "centre"],
            "resultat":         ["gagnant", "non_gagnant"],
            "touche":           ["true", "false"],
        }
    },
}


def get_config_domaine(domaine: str) -> dict | None:
    return DOMAINES_ACTION_CONFIG.get(domaine)


def valider_action(domaine: str, donnees: dict) -> tuple[bool, str | None]:
    """
    Valide qu'une action soumise respecte la configuration de son domaine.
    donnees = {"type_action": "smashe", "position": "6", ...}
    """
    config = get_config_domaine(domaine)
    if not config:
        return False, f"Domaine '{domaine}' non reconnu pour la saisie d'action"

    champs_attendus = config["champs"]
    for champ, valeur in donnees.items():
        if champ not in champs_attendus:
            return False, f"Champ '{champ}' non attendu pour le domaine '{domaine}'"
        val_str = str(valeur).lower() if isinstance(valeur, bool) else str(valeur)
        if val_str not in champs_attendus[champ]:
            return False, f"Valeur '{valeur}' invalide pour le champ '{champ}' (domaine '{domaine}')"

    return True, None
