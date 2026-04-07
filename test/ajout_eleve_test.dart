import'package:flutter_test/flutter_test.dart';
import'package:echeance_fest/pages/page/etudiant.dart';

void main() {
  List<String> eleves = [];

  bool ajouterEleve(String nom) {
    if (nom.isEmpty) return false;
    eleves.add(nom);
    return true;
  }

  test('Ajout d’un élève', () {
    eleves.clear();
    bool resultat = ajouterEleve("Jean");
    expect(resultat, true);
    expect(eleves.contains("Jean"), true);
  });
}