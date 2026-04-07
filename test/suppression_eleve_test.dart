import'package:flutter_test/flutter_test.dart';
import'package:echeance_fest/pages/page/etudiant.dart';

void main() {
  List<String> eleves = [];

  bool supprimerEleve(String nom) {
    return eleves.remove(nom);
  }

  test('Suppression d’un élève', () {
    eleves.clear();
    eleves.add("Marie");
    bool resultat = supprimerEleve("Marie");
    expect(resultat, true);
    expect(eleves.contains("Marie"), false);
  });
}