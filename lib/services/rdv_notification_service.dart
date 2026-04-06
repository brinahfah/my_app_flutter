import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'notification_display_service.dart';

class RdvNotificationService {
  static Future<void> verifierNotifications(BuildContext context) async {
    final snapshot =
    await FirebaseFirestore.instance.collection('meets').get();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data['date'] == null) continue;

      DateTime rdvDate = (data['date'] as Timestamp).toDate();
      DateTime dateOnly =
      DateTime(rdvDate.year, rdvDate.month, rdvDate.day);

      Map notif = Map<String, dynamic>.from(
        data['notificationsEnvoyees'] ??
            {
              "1_semaine_avant": false,
              "jour_j": false,
              "7_jours_apres": false,
            },
      );

      int diff = dateOnly.difference(today).inDays;
      bool updated = false;

      if (!notif["1_semaine_avant"] && diff == 7) {
        await NotificationDisplayService.showNotification(
          context,
          title: "Rendez-vous à venir",
          body: "Le RDV '${data['theme']}' arrive dans 1 semaine",
        );
        notif["1_semaine_avant"] = true;
        updated = true;
      }

      if (!notif["jour_j"] && diff == 0) {
        await NotificationDisplayService.showNotification(
          context,
          title: "Rendez-vous aujourd'hui",
          body: "Le RDV '${data['theme']}' est aujourd'hui",
        );
        notif["jour_j"] = true;
        updated = true;
      }

      if (!notif["7_jours_apres"] && diff == -7) {
        await NotificationDisplayService.showNotification(
          context,
          title: "Rendez-vous en retard",
          body: "Le RDV '${data['theme']}' est en retard",
        );
        notif["7_jours_apres"] = true;
        updated = true;
      }

      if (updated) {
        await doc.reference.update({"notificationsEnvoyees": notif});
      }
    }
  }

  static Future<void> verifier(BuildContext context) async {}
}