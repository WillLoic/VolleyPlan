import os
from .action_jeu_repository_colonnes import ActionJeuRepositoryColonnes
from .action_jeu_repository_json import ActionJeuRepositoryJSON


def get_action_jeu_repository():
    """
    Le mode actif est piloté par la variable d'environnement ACTION_JEU_STORAGE_MODE.
    Valeurs possibles : "colonnes" (défaut, MVP) ou "json".
    Changer cette variable ne nécessite AUCUNE modification du code appelant.
    """
    mode = os.getenv("ACTION_JEU_STORAGE_MODE", "colonnes")
    if mode == "json":
        return ActionJeuRepositoryJSON()
    return ActionJeuRepositoryColonnes()