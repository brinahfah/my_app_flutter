import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../pages/page/mission.dart';
import '../pages/page/rendez_vous.dart';
import '../services/notification_display_service.dart' hide NotificationDisplayService;
import '../pages/page/commentaire_final.dart';

/// =========================
/// 🔔 NOTIFICATION DISPLAY
/// =========================
class NotificationDisplayService {
  static Future<void> showNotification(
      BuildContext context, {
        required String title,
        required String body,
      }) async {
    if (Theme.of(context).platform == TargetPlatform.android ||
        Theme.of(context).platform == TargetPlatform.iOS) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            )
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("$title\n$body"),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}

/// =========================
/// 🔔 RDV NOTIFICATIONS
/// =========================
class NotificationService {
  static Future<void> verifierNotifications(
      BuildContext context, {
        bool testMode = false,
      }) async {
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
        data['notificationsEnvoyees'] ?? {
          "1_semaine_avant": false,
          "jour_j": false,
          "7_jours_apres": false,
        },
      );

      bool updated = false;

      // 📅 1 semaine avant
      if (!notif["1_semaine_avant"]) {
        int diff = dateOnly.difference(today).inDays;
        if (diff == 7 || testMode) {
          await NotificationDisplayService.showNotification(
            context,
            title: "Rendez-vous à venir",
            body: "Le RDV '${data['theme']}' arrive dans 1 semaine",
          );
          notif["1_semaine_avant"] = true;
          updated = true;
        }
      }

      // 📅 Jour J
      if (!notif["jour_j"]) {
        int diff = dateOnly.difference(today).inDays;
        if (diff == 0 || testMode) {
          await NotificationDisplayService.showNotification(
            context,
            title: "Rendez-vous aujourd'hui",
            body: "Le RDV '${data['theme']}' est prévu aujourd'hui",
          );
          notif["jour_j"] = true;
          updated = true;
        }
      }

      // 📅 7 jours après (retard)
      if (!notif["7_jours_apres"]) {
        int diff = dateOnly.difference(today).inDays;
        if (diff == -7 || testMode) {
          await NotificationDisplayService.showNotification(
            context,
            title: "Rendez-vous en retard",
            body: "Le RDV '${data['theme']}' est en retard",
          );
          notif["7_jours_apres"] = true;
          updated = true;
        }
      }

      if (updated) {
        await doc.reference.update({
          "notificationsEnvoyees": notif,
        });
      }
    }
  }
}

/// =========================
/// 🔔 MISSIONS NOTIFICATIONS
/// =========================
class MissionNotificationService {
  static Future<void> verifierNotifications(
      BuildContext context, {
        bool testMode = false,
      }) async {
    final snapshot =
    await FirebaseFirestore.instance.collection('missions').get();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (var doc in snapshot.docs) {
      final data = doc.data();

      if (data['date'] == null) continue;

      DateTime missionDate = (data['date'] as Timestamp).toDate();
      DateTime dateOnly =
      DateTime(missionDate.year, missionDate.month, missionDate.day);

      Map notif = Map<String, dynamic>.from(
        data['notificationsEnvoyees'] ?? {
          "1_semaine_avant": false,
          "jour_j": false,
          "7_jours_apres": false,
        },
      );

      bool updated = false;

      int diff = dateOnly.difference(today).inDays;

      // 📅 1 semaine avant
      if (!notif["1_semaine_avant"] && (diff == 7 || testMode)) {
        await NotificationDisplayService.showNotification(
          context,
          title: "Mission à venir",
          body: "La mission ${data['numero']} arrive dans 1 semaine",
        );
        notif["1_semaine_avant"] = true;
        updated = true;
      }

      // 📅 Jour J
      if (!notif["jour_j"] &&
          (diff == 0 || testMode) &&
          (data['commentaire'] == null || data['commentaire'].isEmpty)) {
        await NotificationDisplayService.showNotification(
          context,
          title: "Mission aujourd'hui",
          body: "La mission ${data['numero']} doit être réalisée aujourd'hui",
        );
        notif["jour_j"] = true;
        updated = true;
      }

      // 📅 En retard
      if (!notif["7_jours_apres"] &&
          (diff == -7 || testMode) &&
          (data['commentaire'] == null || data['commentaire'].isEmpty)) {
        await NotificationDisplayService.showNotification(
          context,
          title: "Mission en retard",
          body: "La mission ${data['numero']} est en retard",
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

/// =========================
/// 🔔 COMMENTAIRES ELEVE
/// =========================
class CommentaireNotificationService {
  static Future<void> verifierNotification(
      BuildContext context,
      String eleveId,
      ) async {
    final doc = await FirebaseFirestore.instance
        .collection('eleves')
        .doc(eleveId)
        .get();

    if (!doc.exists) return;

    final data = doc.data()!;

    String? commentaire = data['commentaireFinal'];

    Map notif = Map<String, dynamic>.from(
      data['notificationCommentaire'] ?? {
        "rappel": false,
        "valide": false,
      },
    );

    bool updated = false;

    // ❌ pas de commentaire
    if (!notif["rappel"] &&
        (commentaire == null || commentaire.isEmpty)) {
      await NotificationDisplayService.showNotification(
        context,
        title: "Commentaire manquant",
        body: "Veuillez renseigner le commentaire final",
      );
      notif["rappel"] = true;
      updated = true;
    }

    // ✅ commentaire ajouté
    if (!notif["valide"] &&
        (commentaire != null && commentaire.isNotEmpty)) {
      await NotificationDisplayService.showNotification(
        context,
        title: "Commentaire enregistré",
        body: "Le commentaire final est bien ajouté",
      );
      notif["valide"] = true;
      updated = true;
    }

    if (updated) {
      await FirebaseFirestore.instance
          .collection('eleves')
          .doc(eleveId)
          .update({
        "notificationCommentaire": notif,
      });
    }
  }
}