class Tuteur {
  String nom;
  String prenom;
  String email;

  Tuteur({
    required this.nom,
    required this.prenom,
    required this.email,
  });

  String getNom() => nom;
  String getEmail() => email;
}