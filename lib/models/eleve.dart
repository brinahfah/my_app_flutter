class Eleve {
  String nom;
  String prenom;

  Eleve({
    required this.nom,
    required this.prenom,
  });

  String getNom() => nom;
  String getPrenom() => prenom;

  void consulterFiche() {
    print('Consultation de la fiche de $prenom $nom.');
  }
}