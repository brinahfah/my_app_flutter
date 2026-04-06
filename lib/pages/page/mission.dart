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
        return Colors.red;
      case "En cours":
        return Colors.green.shade400;
      default:
        return Colors.yellow;
    }
  }

  String computeStatut(DateTime? dateEffectuee, String commentaire) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (dateEffectuee == null) return "À faire";

    final d = DateTime(dateEffectuee.year, dateEffectuee.month, dateEffectuee.day);

    if (d.isAfter(today)) return "En retard";
    if (d.isAtSameMomentAs(today)) return "En cours";
    if (d.isBefore(today) && commentaire.isNotEmpty) return "Complété";
    if (d.isBefore(today) && commentaire.isEmpty) return "En retard";

    return "À faire";
  }

  Future<void> updateMission(
      String docId, String commentaire, DateTime? dateEffectuee) async {
    String statut = computeStatut(dateEffectuee, commentaire);

    await missionsRef.doc(docId).update({
      "commentaire": commentaire,
      "dateEffectuee": dateEffectuee,
      "statut": statut,
    });
  }

  Future<void> deleteMission(
      String docId, String commentaire, DateTime? dateEffectuee) async {
    // Confirmation avant suppression
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Confirmer la suppression"),
        content: const Text("Voulez-vous vraiment supprimer cette mission ?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text("Annuler")),
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text("Supprimer")),
        ],
      ),
    );

    if (confirm == true) {
      await updateMission(docId, commentaire, null);
    }
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

        return Expanded(
          child: ListView.builder(
            itemCount: missions.length,
            itemBuilder: (context, index) {
              final doc = missions[index];
              final data = doc.data() as Map<String, dynamic>;

              if (!controllers.containsKey(doc.id)) {
                controllers[doc.id] =
                    TextEditingController(text: data['commentaire'] ?? "");
              }

              final controller = controllers[doc.id]!;

              DateTime? dateEffectuee = data['dateEffectuee'] != null
                  ? (data['dateEffectuee'] as Timestamp).toDate()
                  : null;

              String statut = computeStatut(dateEffectuee, controller.text);

              return Card(
                color: getStatutColor(statut),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Mission ${data['numero']}"),
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
                                dateEffectuee != null
                                    ? "${dateEffectuee.year}-${dateEffectuee.month}-${dateEffectuee.day}"
                                    : "Aucune date",
                              ),
                            ),
                          ),

                          TextButton(
                            onPressed: () async {
                              DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: dateEffectuee ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );

                              if (picked != null) {
                                setState(() {
                                  dateEffectuee = picked;
                                });

                                await updateMission(
                                    doc.id, controller.text, dateEffectuee);
                              }
                            },
                            child: const Text("📅", style: TextStyle(fontSize: 24)),
                          ),

                          TextButton(
                            onPressed: () async {
                              await deleteMission(doc.id, controller.text, dateEffectuee);
                            },
                            child: const Text("🗑️", style: TextStyle(fontSize: 24)),
                          ),
                        ],
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
