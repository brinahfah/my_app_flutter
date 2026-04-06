import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'notification_display_service.dart';

class MissionNotificationService {
  static Future<void> verifier(BuildContext context, String eleveId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('missions')
        .where('eleveId', isEqualTo: eleveId)
        .get();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (var doc in snapshot.docs) {
      final data = doc.data();

      if (data['date'] == null) continue;

      DateTime missionDate = (data['date'] as Timestamp).toDate();
      DateTime dateOnly = DateTime(
        missionDate.year,
        missionDate.month,
        missionDate.day,
      );

      int diff = dateOnly.difference(today).inDays;

      Map notif = Map<String, dynamic>.from(
        data['notificationsEnvoyees'] ??
            {
              "1_semaine_avant": false,
              "jour_j": false,
              "7_jours_apres": false,
            },
      );

      bool updated = false;

      if (diff == 7 && notif["1_semaine_avant"] == false) {
        await NotificationDisplayService.showNotification(
          context,
          title: "Mission à venir",
          body: "Mission ${data['numero']} dans 1 semaine",
        );
        notif["1_semaine_avant"] = true;
        updated = true;
      }

      if (diff == 0 && notif["jour_j"] == false) {
        await NotificationDisplayService.showNotification(
          context,
          title: "Mission aujourd'hui",
          body: "Mission ${data['numero']} aujourd'hui",
        );
        notif["jour_j"] = true;
        updated = true;
      }

      if (diff == -7 && notif["7_jours_apres"] == false) {
        await NotificationDisplayService.showNotification(
          context,
          title: "Mission en retard",
          body: "Mission ${data['numero']} en retard",
        );
        notif["7_jours_apres"] = true;
        updated = true;
      }

      if (updated) {
        await doc.reference.update({
          "notificationsEnvoyees": notif,
        });
      }
    }
  }

}