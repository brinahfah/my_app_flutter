import'package:flutter_test/flutter_test.dart';
import'package:echeance_fest/pages/page/login.dart';

void main() {
  bool connexionReferent(String login, String mdp) {
    const loginCorrect = "referent";
    const mdpCorrect = "1234";
    return login == loginCorrect && mdp == mdpCorrect;
  }

  test('Connexion avec identifiants corrects', () {
    bool resultat = connexionReferent("referent", "1234");
    expect(resultat, true);
  });

  test('Connexion avec identifiants incorrects', () {
    bool resultat = connexionReferent("referent", "wrong");
    expect(resultat, false);
  });
}