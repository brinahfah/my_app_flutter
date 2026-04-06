import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

// 🔹 Affichage des notifications
class NotificationDisplayService {
  static Future<void> showNotification(
      BuildContext context, {
        required String title,
        required String body,
      }) async {
    if (kIsWeb || (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$title\n$body'),
          duration: const Duration(seconds: 5),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
  }
}

// 🔹 Vérification des notifications
class NotificationService {
  static Future<void> verifierNotifications(
      BuildContext context, {
        bool testMode = false,
      }) async {
    final rdvRef = FirebaseFirestore.instance.collection('meets');
    final snapshot = await rdvRef.get();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      if (data['date'] == null) continue;

      DateTime rdvDate = (data['date'] as Timestamp).toDate();
      DateTime dateOnly = DateTime(rdvDate.year, rdvDate.month, rdvDate.day);

      int diffDays = dateOnly.difference(today).inDays;

      Map notif = data['notificationsEnvoyees'] ?? {
        "1_semaine_avant": false,
        "jour_j": false,
        "7_jours_apres": false,
      };

      bool updated = false;

      if ((diffDays == 7 || testMode) && notif["1_semaine_avant"] == false) {
        await NotificationDisplayService.showNotification(
          context,
          title: "Rendez-vous à venir",
          body: "Le RDV '${data['theme']}' aura lieu dans 1 semaine",
        );
        notif["1_semaine_avant"] = true;
        updated = true;
      }

      if ((diffDays == 0 || testMode) &&
          notif["jour_j"] == false &&
          data['statut'] != "Complété") {
        await NotificationDisplayService.showNotification(
          context,
          title: "Rendez-vous aujourd'hui",
          body: "Le RDV '${data['theme']}' doit être effectué aujourd'hui",
        );
        notif["jour_j"] = true;
        updated = true;
      }

      if ((diffDays == -7 || testMode) &&
          notif["7_jours_apres"] == false &&
          data['statut'] != "Complété") {
        await NotificationDisplayService.showNotification(
          context,
          title: "Rendez-vous en retard",
          body: "Le RDV '${data['theme']}' est en retard de 7 jours",
        );
        notif["7_jours_apres"] = true;
        updated = true;
      }

      if (updated) {
        await doc.reference.update({"notificationsEnvoyees": notif});
      }
    }
  }
}

// 🔹 Section RDV
class RendezVousSection extends StatefulWidget {
  final String eleveId;
  const RendezVousSection({super.key, required this.eleveId});

  @override
  State<RendezVousSection> createState() => _RendezVousSectionState();
}

class _RendezVousSectionState extends State<RendezVousSection> {
  final CollectionReference rdvRef =
  FirebaseFirestore.instance.collection('meets');

  Map<String, TextEditingController> controllers = {};

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.verifierNotifications(context, testMode: true);
    });
  }

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

  Future<void> updateRdv(
      String docId, String commentaire, DateTime? date) async {
    String statut = computeStatut(date, commentaire);

    await rdvRef.doc(docId).update({
      "commentaire": commentaire,
      "date": date,
      "statut": statut,
    });
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

        return Expanded(
          child: ListView.builder(
            itemCount: rdvs.length,
            itemBuilder: (context, index) {
              final doc = rdvs[index];
              final data = doc.data() as Map<String, dynamic>;

              if (!controllers.containsKey(doc.id)) {
                controllers[doc.id] =
                    TextEditingController(text: data['commentaire'] ?? "");
              }

              final controller = controllers[doc.id]!;

              DateTime? date = data['date'] != null
                  ? (data['date'] as Timestamp).toDate()
                  : null;

              String statut = computeStatut(date, controller.text);

              return Card(
                color: getStatutColor(statut),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Rendez-vous ${data['numero']} - ${data['theme']}"),
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

                                await updateRdv(
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

                              await updateRdv(doc.id, controller.text, null);
                            },
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