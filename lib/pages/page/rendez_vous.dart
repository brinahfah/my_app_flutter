import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RendezVousSection extends StatefulWidget {
  final String eleveId;
  const RendezVousSection({super.key, required this.eleveId});

  @override
  State<RendezVousSection> createState() => _RendezVousSectionState();
}

class _RendezVousSectionState extends State<RendezVousSection> {
  final CollectionReference rdvRef = FirebaseFirestore.instance.collection('meets');

  Map<String, TextEditingController> controllers = {};
  Map<String, DateTime?> dates = {};

  @override
  void dispose() {
    for (var c in controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Color getStatutColor(String statut) {
    switch (statut) {
      case "Complété":
        return Colors.green.shade800;
      case "En retard":
        return Colors.red.shade800;
      case "En cours":
        return Colors.green.shade500;
      default:
        return Colors.yellow.shade500;
    }
  }

  String computeStatut(DateTime? date, String commentaire) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (date == null) return "À faire";

    final d = DateTime(date.year, date.month, date.day);

    if (d.isAfter(today)) return "En retard";
    if (d.isAtSameMomentAs(today)) return "En cours";
    if (d.isBefore(today) && commentaire.isNotEmpty) return "Complété";
    if (d.isBefore(today) && commentaire.isEmpty) return "En retard";

    return "À faire";
  }

  Future<void> updateRdv(String docId, String commentaire, DateTime? date) async {
    String statut = computeStatut(date, commentaire);

    await rdvRef.doc(docId).update({
      "commentaire": commentaire,
      "date": date,
      "statut": statut,
    });
  }

  Future<void> deleteRdv(String docId) async {
    await rdvRef.doc(docId).update({
      "date": null,
      "commentaire": "",
      "statut": "À faire",
    });

    controllers[docId]?.clear();
    dates[docId] = null;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: rdvRef.where('eleveId', isEqualTo: widget.eleveId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final rdvs = snapshot.data!.docs;

        if (rdvs.isEmpty) {
          return const Center(child: Text("Aucun rendez-vous", style: TextStyle(color: Colors.black)));
        }

        return ListView.builder(

            itemCount: rdvs.length,
            itemBuilder: (context, index) {
              final doc = rdvs[index];
              final data = doc.data() as Map<String, dynamic>? ?? {};

              if (!controllers.containsKey(doc.id)) {
                controllers[doc.id] = TextEditingController(text: data['commentaire'] ?? "");
              }
              final controller = controllers[doc.id]!;

              if (!dates.containsKey(doc.id)) {
                dates[doc.id] = data['date'] != null
                    ? (data['date'] as Timestamp).toDate()
                    : null;
              }
              DateTime? date = dates[doc.id];
              String statut = computeStatut(date, controller.text);

              return Card(
                color: getStatutColor(statut),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Rendez-vous ${data['numero'] ?? 'N/A'} - ${data['theme'] ?? 'N/A'}"),
                      Text("Statut: $statut"),
                      const SizedBox(height: 8),
                      TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                          labelText: "Commentaire",
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                  date != null ? "${date.year}-${date.month}-${date.day}" : "Aucune date"),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: () async {
                              DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: date ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setState(() {
                                  dates[doc.id] = picked;
                                });
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () async {
                              await deleteRdv(doc.id);

                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            await updateRdv(doc.id, controller.text, dates[doc.id]);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Rendez-vous enregistré ✅")),
                            );
                          },
                          child: const Text("Enregistrer"),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );

      },
    );
  }
}