import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../login.dart';
import 'rendez_vous.dart';
import 'mission.dart';
import 'commentaire_final.dart' hide squareButton;

class ElevePage extends StatefulWidget {
  final String classeId;
  final String nomClasse;

  const ElevePage({super.key, required this.classeId, required this.nomClasse});

  @override
  State<ElevePage> createState() => _ElevePageState();
}

class _ElevePageState extends State<ElevePage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Map<String, Map<String, dynamic>> tuteursMap = {};

  @override
  void initState() {
    super.initState();
    chargerTuteurs();
  }

  Future<void> chargerTuteurs() async {
    final snapshot = await firestore.collection("tuteurs").get();
    for (var doc in snapshot.docs) {
      tuteursMap[doc.id] = doc.data();
    }
    setState(() {});
  }

  /// CREATE ELEVE
  Future<void> creerEleveAvecSuivi({
    required String nom,
    required String prenom,
    required String nomTuteur,
    required String prenomTuteur,
    required String emailTuteur,
  }) async {
    final batch = firestore.batch();

    final eleveRef = firestore.collection("eleves").doc();
    final tuteurRef = firestore.collection("tuteurs").doc();

    batch.set(tuteurRef, {
      "nom_tuteur": nomTuteur,
      "prenom_tuteur": prenomTuteur,
      "email_tuteur": emailTuteur,
    });

    batch.set(eleveRef, {
      "nom": nom,
      "prenom": prenom,
      "classeId": widget.classeId,
      "tuteurId": tuteurRef.id,
      "commentaireFinal": "",
    });

    for (int i = 0; i < 3; i++) {
      final rdvRef = firestore.collection("meets").doc();
      batch.set(rdvRef, {
        "eleveId": eleveRef.id,
        "numero": i + 1,
        "statut": "À faire",
        "date": null,
      });
    }

    for (int i = 0; i < 4; i++) {
      final missionRef = firestore.collection("missions").doc();
      batch.set(missionRef, {
        "eleveId": eleveRef.id,
        "numero": i + 1,
        "statut": "À faire",
        "datePlanification": null,
        "dateEffectuee": null,
        "commentaire": "",
      });
    }

    await batch.commit();
  }

  /// DIALOG
  Future<void> ajouterEleve() async {
    final nomController = TextEditingController();
    final prenomController = TextEditingController();
    final nomTuteurController = TextEditingController();
    final prenomTuteurController = TextEditingController();
    final emailTuteurController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Ajouter un élève"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: nomController, decoration: const InputDecoration(labelText: "Nom élève")),
              TextField(controller: prenomController, decoration: const InputDecoration(labelText: "Prénom élève")),
              const SizedBox(height: 10),
              const Text("Tuteur", style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(controller: nomTuteurController, decoration: const InputDecoration(labelText: "Nom tuteur")),
              TextField(controller: prenomTuteurController, decoration: const InputDecoration(labelText: "Prénom tuteur")),
              TextField(controller: emailTuteurController, decoration: const InputDecoration(labelText: "Email tuteur")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () async {
              if (nomController.text.isEmpty || prenomController.text.isEmpty) return;

              await creerEleveAvecSuivi(
                nom: nomController.text,
                prenom: prenomController.text,
                nomTuteur: nomTuteurController.text,
                prenomTuteur: prenomTuteurController.text,
                emailTuteur: emailTuteurController.text,
              );

              Navigator.pop(context);
            },
            child: const Text("Ajouter"),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> getEleves() {
    return firestore
        .collection("eleves")
        .where("classeId", isEqualTo: widget.classeId)
        .snapshots();
  }

  Future<int> getScoreRDV(String eleveId) async {
    final snap = await firestore.collection("meets").where("eleveId", isEqualTo: eleveId).get();
    return snap.docs.where((d) => d["date"] != null).length;
  }

  Future<int> getScoreMissions(String eleveId) async {
    final snap = await firestore.collection("missions").where("eleveId", isEqualTo: eleveId).get();
    return snap.docs.where((d) => d["dateEffectuee"] != null).length;
  }

  Future<int> getScoreCommentaire(String eleveId) async {
    final doc = await firestore.collection("eleves").doc(eleveId).get();
    final val = doc.data()?["commentaireFinal"];
    return (val != null && val != "") ? 1 : 0;
  }

  /// ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Insertion de ton bouton personnalisé ici
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: squareButton("←", Colors.blue, () {
            Navigator.pop(context);
          }),
        ),
        title: Text("Classe ${widget.nomClasse}"),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 800;

          return StreamBuilder<QuerySnapshot>(
            stream: getEleves(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final eleves = snapshot.data!.docs;

              if (isMobile) {
                return buildMobileList(eleves);
              } else {
                return buildWebTable(eleves);
              }
            },
          );
        },
      ),
    );
  }
  /// MOBILE
  Widget buildMobileList(List<QueryDocumentSnapshot> eleves) {
    return ListView.builder(
      itemCount: eleves.length,
      itemBuilder: (context, index) {
        final doc = eleves[index];
        final data = doc.data() as Map<String, dynamic>;
        final tuteur = tuteursMap[data["tuteurId"]];

        return Card(
          margin: const EdgeInsets.all(10),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${data["prenom"]} ${data["nom"]}",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    scoreClickable("RDV", getScoreRDV(doc.id), 3, () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => RendezVousSection(eleveId: doc.id)));
                    }),
                    scoreClickable("Missions", getScoreMissions(doc.id), 4, () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => MissionsSection(eleveId: doc.id)));
                    }),
                    scoreClickable("Com", getScoreCommentaire(doc.id), 1, () {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => CommentaireSection(
                          eleveId: doc.id,
                          commentaireInitial: data["commentaireFinal"] ?? "",
                        ),
                      ));
                    }),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// WEB
  Widget buildWebTable(List<QueryDocumentSnapshot> eleves) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text("Nom")),
          DataColumn(label: Text("Prénom")),
          DataColumn(label: Text("RDV (/3)")),
          DataColumn(label: Text("Missions (/4)")),
          DataColumn(label: Text("Commentaire (/1)")),
        ],
        rows: eleves.map((doc) {
          final data = doc.data() as Map<String, dynamic>;

          return DataRow(cells: [
            DataCell(Text(data["nom"] ?? "")),
            DataCell(Text(data["prenom"] ?? "")),

            DataCell(scoreClickableTable(getScoreRDV(doc.id), 3, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => RendezVousSection(eleveId: doc.id)));
            })),

            DataCell(scoreClickableTable(getScoreMissions(doc.id), 4, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => MissionsSection(eleveId: doc.id)));
            })),

            DataCell(scoreClickableTable(getScoreCommentaire(doc.id), 1, () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => CommentaireSection(
                  eleveId: doc.id,
                  commentaireInitial: data["commentaireFinal"] ?? "",
                ),
              ));
            })),
          ]);
        }).toList(),
      ),
    );
  }

  /// CLICKABLE MOBILE
  Widget scoreClickable(String label, Future<int> future, int max, VoidCallback onTap) {
    return FutureBuilder<int>(
      future: future,
      builder: (_, s) => GestureDetector(
        onTap: onTap,
        child: Text(
          "$label: ${s.data ?? "..."} / $max",
          style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
        ),
      ),
    );
  }

  /// CLICKABLE TABLE
  Widget scoreClickableTable(Future<int> future, int max, VoidCallback onTap) {
    return FutureBuilder<int>(
      future: future,
      builder: (_, s) => GestureDetector(
        onTap: onTap,
        child: Text(
          "${s.data ?? "..."} / $max",
          style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
        ),
      ),
    );
  }
}