import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/models/classe.dart';
import 'etudiant.dart';

class ClassePage extends StatefulWidget {
  const ClassePage({super.key});

  @override
  State<ClassePage> createState() => _ClassePageState();
}

class _ClassePageState extends State<ClassePage> {
  final CollectionReference classesRef =
  FirebaseFirestore.instance.collection('classes');

  Stream<int> getNombreEleves(String classeId) {
    return FirebaseFirestore.instance
        .collection("eleves")
        .where("classeId", isEqualTo: classeId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> showAddClasseDialog() async {
    final TextEditingController etabController = TextEditingController();
    final TextEditingController villeController = TextEditingController();
    final TextEditingController nomClasseController = TextEditingController();
    final TextEditingController nbLivretsDeposeController =
    TextEditingController();
    final TextEditingController nbLivretsRetardController =
    TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Ajouter une classe"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: etabController,
                  decoration:
                  const InputDecoration(labelText: "Établissement"),
                ),
                TextField(
                  controller: villeController,
                  decoration: const InputDecoration(labelText: "Ville"),
                ),
                TextField(
                  controller: nomClasseController,
                  decoration:
                  const InputDecoration(labelText: "Nom Classe"),
                ),
                TextField(
                  controller: nbLivretsDeposeController,
                  decoration: const InputDecoration(
                      labelText: "Nb Livrets déposés (optionnel)"),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: nbLivretsRetardController,
                  decoration: const InputDecoration(
                      labelText: "Nb Livrets retard (optionnel)"),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Annuler")),
            ElevatedButton(
              onPressed: () async {
                if (etabController.text.isNotEmpty &&
                    villeController.text.isNotEmpty &&
                    nomClasseController.text.isNotEmpty) {
                  await classesRef.add({
                    "etablissement": etabController.text,
                    "ville": villeController.text,
                    "nom_classe": nomClasseController.text,
                    "nb_livret_depose":
                    int.tryParse(nbLivretsDeposeController.text) ?? 0,
                    "nb_livret_retard":
                    int.tryParse(nbLivretsRetardController.text) ?? 0,
                  });

                  Navigator.pop(context);
                }
              },
              child: const Text("Ajouters"),
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteClasse(String classeId) async {
    await classesRef.doc(classeId).delete();
  }

  /// 🔥 BOUTON CARRE (SANS ICON → PAS DE BUG)
  Widget squareButton(String symbol, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 35,
        height: 35,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(color: color, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          symbol,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      appBar: AppBar(
        leading: Navigator.canPop(context)
            ? Padding(
          padding: const EdgeInsets.all(8),
          child: squareButton("←", Colors.lightGreen, () {
            Navigator.pop(context);
          }),
        )
            : null,
        title: const Text("Gestion des Classes"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: squareButton("+", Colors.blueAccent, showAddClasseDialog),
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: classesRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Erreur : ${snapshot.error}"));
          }

          final docs = snapshot.data!.docs;
          final classes = docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Classe.fromMap(data, doc.id);
          }).toList();

          /// 📱 MOBILE
          if (isMobile) {
            return ListView.builder(
              itemCount: classes.length,
              itemBuilder: (context, index) {
                final classe = classes[index];

                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ElevePage(
                            classeId: classe.id,
                            nomClasse: classe.nomClasse,
                          ),
                        ),
                      );
                    },
                    title: Text(classe.nomClasse),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(classe.etablissement),
                        Text(classe.ville),
                        StreamBuilder<int>(
                          stream: getNombreEleves(classe.id),
                          builder: (context, snapshot) {
                            return Text(
                                "Élèves: ${snapshot.data ?? "..."}");
                          },
                        ),
                      ],
                    ),
                    trailing: squareButton("-", Colors.red, () {
                      deleteClasse(classe.id);
                    }),
                  ),
                );
              },
            );
          }

          /// 💻 WEB
          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 30,
                columns: const [
                  DataColumn(label: Text("Établissement")),
                  DataColumn(label: Text("Ville")),
                  DataColumn(label: Text("Nom Classe")),
                  DataColumn(label: Text("Nb Élèves")),
                  DataColumn(label: Text("Livrets déposés")),
                  DataColumn(label: Text("Livrets retard")),
                  DataColumn(label: Text("Supprimer")),
                ],
                rows: classes.map((classe) {
                  return DataRow(
                    cells: [
                      DataCell(
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ElevePage(
                                  classeId: classe.id,
                                  nomClasse: classe.nomClasse,
                                ),
                              ),
                            );
                          },
                          child: Text(classe.etablissement),
                        ),
                      ),
                      DataCell(Text(classe.ville)),
                      DataCell(Text(classe.nomClasse)),
                      DataCell(
                        StreamBuilder<int>(
                          stream: getNombreEleves(classe.id),
                          builder: (context, snapshot) {
                            return Text(snapshot.data?.toString() ?? "...");
                          },
                        ),
                      ),
                      DataCell(
                          Text(classe.nombreLivretsDeposes.toString())),
                      DataCell(
                          Text(classe.nombreLivretsRetard.toString())),
                      DataCell(
                        squareButton("-", Colors.red, () {
                          deleteClasse(classe.id);
                        }),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}