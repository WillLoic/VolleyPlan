import 'api_service.dart';
import '../models/joueur.dart';

class JoueurService {
  static Future<List<Joueur>> getJoueurs({bool includeInactifs = false}) async {
    final res = await ApiService.get('/joueurs/list_joueurs?inactifs=$includeInactifs');
    return (res['data'] as List).map((j) => Joueur.fromJson(j)).toList();
  }

  static Future<Joueur> addJoueur(String nom, {String? poste}) async {
    final res = await ApiService.post(
        '/joueurs/add_joueurs', {'nom': nom, 'poste': poste});
    return Joueur.fromJson(res);
  }

  static Future<Joueur> updateJoueur(int id, Map<String, dynamic> data) async {
    final res = await ApiService.put('/joueurs/update/$id', data);
    return Joueur.fromJson(res);
  }

  static Future<void> deleteJoueur(int id) async {
    await ApiService.delete('/joueurs/delete/$id');
  }
}
