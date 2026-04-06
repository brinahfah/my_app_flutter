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

  // 🔥 DATE PICKER CUSTOM
  Future<DateTime?> showCustomDatePicker(DateTime initialDate) async {
    DateTime selectedDate = initialDate;

    return await showDialog<DateTime>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("${selectedDate.year}-${selectedDate.month}"),

                  Row(
                    children: [
                      // ⬅️ mois précédent
                      IconButton(
                        onPressed: () {
                          setStateDialog(() {
                            selectedDate = DateTime(
                                selectedDate.year, selectedDate.month - 1, 1);
                          });
                        },
                        icon: const Text("⬅️"),
                      ),

                      // ➡️ mois suivant
                      IconButton(
                        onPressed: () {
                          setStateDialog(() {
                            selectedDate = DateTime(
                                selectedDate.year, selectedDate.month + 1, 1);
                          });
                        },
                        icon: const Text("➡️"),
                      ),

                      // 📅 choisir année
                      IconButton(
                        onPressed: () async {
                          final year = await showDialog<int>(
                            context: context,
                            builder: (_) {
                              return AlertDialog(
                                title: const Text("Choisir une année"),
                                content: SizedBox(
                                  width: 200,
                                  height: 200,
                                  child: ListView.builder(
                                    itemCount: 100,
                                    itemBuilder: (_, i) {
                                      int y = 2000 + i;
                                      return ListTile(
                                        title: Text("$y"),
                                        onTap: () {
                                          Navigator.pop(context, y);
                                        },
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          );

                          if (year != null) {
                            setStateDialog(() {
                              selectedDate =
                                  DateTime(year, selectedDate.month, 1);
                            });
                          }
                        },
                        icon: const Text("📅"),
                      ),

                      // ⌨️ saisie manuelle
                      IconButton(
                        onPressed: () async {
                          TextEditingController ctrl =
                          TextEditingController(
                              text:
                              "${selectedDate.year}-${selectedDate.month}-${selectedDate.day}");

                          final result = await showDialog<DateTime>(
                            context: context,
                            builder: (_) {
                              return AlertDialog(
                                title: const Text("Saisir une date"),
                                content: TextField(
                                  controller: ctrl,
                                  decoration: const InputDecoration(
                                      hintText: "YYYY-MM-DD"),
                                ),
                                actions: [
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context),
                                      child: const Text("Annuler")),
                                  TextButton(
                                    onPressed: () {
                                      try {
                                        final parts =
                                        ctrl.text.split("-");
                                        final d = DateTime(
                                          int.parse(parts[0]),
                                          int.parse(parts[1]),
                                          int.parse(parts[2]),
                                        );
                                        Navigator.pop(context, d);
                                      } catch (_) {}
                                    },
                                    child: const Text("OK"),
                                  ),
                                ],
                              );
                            },
                          );

                          if (result != null) {
                            setStateDialog(() {
                              selectedDate = result;
                            });
                          }
                        },
                        icon: const Text("⌨️"),
                      ),
                    ],
                  )
                ],
              ),

              content: SizedBox(
                height: 250,
                child: GridView.builder(
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                  ),
                  itemCount: 31,
                  itemBuilder: (_, i) {
                    int day = i + 1;
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(
                            context,
                            DateTime(selectedDate.year,
                                selectedDate.month, day));
                      },
                      child: Center(child: Text("$day")),
                    );
                  },
                ),
              ),

              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("❌ Annuler")),
                TextButton(
                    onPressed: () => Navigator.pop(context, selectedDate),
                    child: const Text("✔️ OK")),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: missionsRef
          .where('eleveId', isEqualTo: widget.eleveId)
          .snapshots(),
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

                          // 🔥 UTILISATION DU CUSTOM PICKER
                          TextButton(
                            onPressed: () async {
                              DateTime? picked =
                              await showCustomDatePicker(
                                  dateEffectuee ?? DateTime.now());

                              if (picked != null) {
                                setState(() {
                                  dateEffectuee = picked;
                                });

                                await updateMission(
                                    doc.id, controller.text, dateEffectuee);
                              }
                            },
                            child: const Text("📅",
                                style: TextStyle(fontSize: 24)),
                          ),

                          TextButton(
                            onPressed: () async {
                              await deleteMission(
                                  doc.id, controller.text, dateEffectuee);
                            },
                            child: const Text("🗑️",
                                style: TextStyle(fontSize: 24)),
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