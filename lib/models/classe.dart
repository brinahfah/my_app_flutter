class Classe {
  final String id;
  final String etablissement;
  final String ville;
  final String nomClasse;
  final int nombreLivretsDeposes;
  final int nombreEleve;
  final int nombreLivretsRetard;

  Classe({
    required this.id,
    required this.etablissement,
    required this.ville,
    required this.nomClasse,
    required this.nombreLivretsDeposes,
    required this.nombreEleve,
    required this.nombreLivretsRetard,
  });

  factory Classe.fromMap(Map<String, dynamic> data, String id) {
    return Classe(
      id: id,
      etablissement: data['etablissement'] ?? '',
      ville: data['ville'] ?? '',
      nomClasse: data['nom_classe'] ?? '',
      nombreLivretsDeposes: data['nb_livret_deposes'] ?? 0,
      nombreEleve: data['nb_etudiant'] ?? 0,
      nombreLivretsRetard: data['nb_livret_retard'] ?? 0,
    );
  }
}