import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MissionsSection extends StatefulWidget {
  final String eleveId;
  const MissionsSection({super.key, required this.eleveId});

  @override
  State<MissionsSection> createState() => _MissionsSectionState();
}

class _MissionsSectionState extends State<MissionsSection> {
  final CollectionReference missionsRef =
  FirebaseFirestore.instance.collection('missions');

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

  String computeStatut(DateTime? dateEffectuee, String commentaire) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (dateEffectuee == null) return "À faire";

    final d = DateTime(dateEffectuee.year, dateEffectuee.month, dateEffectuee.day);

    if (d.isAfter(today)) return "En retard";
    if (d.isAtSameMomentAs(today)) return "En cours";
    if (d.isBefore(today)) return "Complété";

    return "À faire";
  }

  Future<void> updateMission(String docId, String commentaire, DateTime? dateEffectuee) async {
    String statut = computeStatut(dateEffectuee, commentaire);
    await missionsRef.doc(docId).update({
      "commentaire": commentaire,
      "dateEffectuee": dateEffectuee,
      "statut": statut,
    });
  }

  Future<void> deleteMission(String docId) async {
    await missionsRef.doc(docId).update({
      "dateEffectuee": null,
      "commentaire": "",
      "statut": "À faire",
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: missionsRef.where('eleveId', isEqualTo: widget.eleveId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final missions = snapshot.data!.docs;

        if (missions.isEmpty) {
          return const Center(child: Text("Aucune mission", style: TextStyle(color: Colors.black)));
        }

        return Expanded(
          child: ListView.builder(
            itemCount: missions.length,
            itemBuilder: (context, index) {
              final doc = missions[index];
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
              DateTime? dateEffectuee = dates[doc.id];
              String statut = computeStatut(dateEffectuee, controller.text);

              return Card(
                color: getStatutColor(statut),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Mission ${data['numero'] ?? 'N/A'}"),
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
                              child: Text(dateEffectuee != null
                                  ? "${dateEffectuee.year}-${dateEffectuee.month}-${dateEffectuee.day}"
                                  : "Aucune date"),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: () async {
                              DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: dateEffectuee ?? DateTime.now(),
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
                              await deleteMission(doc.id);
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            await updateMission(doc.id, controller.text, dates[doc.id]);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Mission enregistrée ✅")),
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
          ),
        );
      },
    );
  }
}