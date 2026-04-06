import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/notification_service.dart';

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
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      MissionNotificationService.verifierNotifications(
        context,
        testMode: true,
      );
    });
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

  String computeStatut(DateTime? date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (date == null) return "À faire";

    final d = DateTime(date.year, date.month, date.day);

    if (d.isAfter(today)) return "En retard";
    if (d.isAtSameMomentAs(today)) return "En cours";
    if (d.isBefore(today)) return "Complété";

    return "À faire";
  }

  Future<void> updateMission(
      String docId, String commentaire, DateTime? date) async {
    String statut = computeStatut(date);

    await missionsRef.doc(docId).update({
      "commentaire": commentaire,
      "date": date,
      "statut": statut,
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
      missionsRef.where('eleveId', isEqualTo: widget.eleveId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final missions = snapshot.data!.docs;

        return ListView.builder(
          itemCount: missions.length,
          itemBuilder: (context, index) {
            final doc = missions[index];
            final data = doc.data() as Map<String, dynamic>;

            if (!controllers.containsKey(doc.id)) {
              controllers[doc.id] =
                  TextEditingController(text: data['commentaires'] ?? "");
            }

            final controller = controllers[doc.id]!;

            DateTime? date = data['date'] != null
                ? (data['date'] as Timestamp).toDate()
                : null;

            String statut = computeStatut(date);

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
                      decoration:
                      const InputDecoration(labelText: "Commentaire"),
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
                              date != null
                                  ? "${date.year}-${date.month}-${date.day}"
                                  : "Aucune date",
                            ),
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
                                date = picked;
                              });

                              await updateMission(
                                  doc.id, controller.text, date);
                            }
                          },
                        ),

                        IconButton(
                          icon:
                          const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            setState(() {
                              date = null;
                            });

                            await updateMission(doc.id, controller.text, null);
                          },
                        ),
                      ],
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