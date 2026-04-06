import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'notification_display_service.dart';

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
      data['notificationCommentaire'] ??
          {
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

    // ✅ commentaire présent
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