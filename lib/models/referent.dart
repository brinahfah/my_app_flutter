import 'classe.dart';
import 'eleve.dart';
import 'models/classe.dart';
import 'models/eleve.dart';

class Referent {
  String nom;
  String prenom;
  String email;
  String motdepasse;

  Referent({
    required this.nom,
    required this.prenom,
    required this.email,
    required this.motdepasse,
  });

  // Méthodes
  void seConnecter() {
    print('$prenom $nom s’est connecté.');
  }

  void seDeconnecter() {
    print('$prenom $nom s’est déconnecté.');
  }

  void ajouterClasse(Classe classe) {
    print('Classe ${classe.nomClasse} ajoutée par $prenom $nom.');
  }

  void supprimerClasse(Classe classe) {
    print('Classe ${classe.nomClasse} supprimée par $prenom $nom.');
  }

  void ajouterEleve(Eleve eleve) {
    print('Élève ${eleve.prenom} ${eleve.nom} ajouté par $prenom $nom.');
  }

  void supprimerEleve(Eleve eleve) {
    print('Élève ${eleve.prenom} ${eleve.nom} supprimé par $prenom $nom.');
  }

  void consulterFiche(Eleve eleve) {
    print('Consultation de la fiche de ${eleve.prenom} ${eleve.nom}.');
  }

  void ajouterCommentaire(String commentaire) {
    print('Commentaire ajouté: $commentaire');
  }
}