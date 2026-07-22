from abc import ABC, abstractmethod


class ActionJeuRepository(ABC):

    @abstractmethod
    def save_batch(self, seance_id: int, exercice_id: int, actions: list[dict]) -> list[int]:
        """
        actions = [
          {"joueur_id": 3, "domaine": "service", "donnees": {"type_action": "smashe", "position": "6", "zone": "1", "resultat": "perdu"}},
          ...
        ]
        Retourne la liste des IDs créés.
        """
        ...

    @abstractmethod
    def delete(self, action_id: int, coach_id: int) -> tuple[bool, str | None]:
        ...

    @abstractmethod
    def get_stats_joueur_exercice(self, exercice_id: int, joueur_id: int) -> dict:
        """
        Retourne les stats agrégées d'un joueur sur un exercice, groupées par domaine.
        Format de sortie IDENTIQUE quelle que soit l'implémentation choisie :
        {
          "service": {
            "total": 10,
            "par_champ": {
              "type_action": {"smashe": 8, "flottant": 2},
              "resultat": {"reussi": 5, "perdu": 3, "ace": 2}
            }
          },
          "reception": {...}
        }
        """
        ...

    @abstractmethod
    def get_stats_exercice(self, exercice_id: int) -> dict:
        """Stats agrégées de TOUS les joueurs sur un exercice, même format imbriqué par joueur_id."""
        ...

    @abstractmethod
    def get_stats_seance(self, seance_id: int) -> dict:
        """Stats agrégées sur toute la séance, groupées par exercice puis joueur."""
        ...
