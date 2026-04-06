import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/notification_display_service.dart';


// 🔔 Service notification commentaire
class CommentaireNotificationService {
  static Future<void> verifierNotification(
      BuildContext context,
      String eleveId,
      ) async {
    final eleveRef =
    FirebaseFirestore.instance.collection('eleves').doc(eleveId);

    final doc = await eleveRef.get();

    if (!doc.exists) return;

    var data = doc.data() as Map<String, dynamic>;

    String? commentaire = data['commentaireFinal'];

    Map notif = data['notificationCommentaire'] ?? {
      "rappel": false,
      "valide": false,
    };

    bool updated = false;

    // 🔹 Pas de commentaire → rappel
    if ((commentaire == null || commentaire.isEmpty) &&
        notif["rappel"] == false) {
      await NotificationDisplayService.showNotification(
        context,
        title: "Commentaire manquant",
        body: "Veuillez renseigner le commentaire final de l'étudiant",
      );

      notif["rappel"] = true;
      updated = true;
    }

    // 🔹 Commentaire rempli → confirmation
    if ((commentaire != null && commentaire.isNotEmpty) &&
        notif["valide"] == false) {
      await NotificationDisplayService.showNotification(
        context,
        title: "Commentaire enregistré",
        body: "Le commentaire final a bien été ajouté",
      );

      notif["valide"] = true;
      updated = true;
    }

    if (updated) {
      await eleveRef.update({"notificationCommentaire": notif});
    }
  }
}

class CommentaireSection extends StatefulWidget {
  final String eleveId;
  final String commentaireInitial;

  const CommentaireSection({
    super.key,
    required this.eleveId,
    required this.commentaireInitial,
  });

  @override
  State<CommentaireSection> createState() => _CommentaireSectionState();
}

class _CommentaireSectionState extends State<CommentaireSection> {
  final CollectionReference elevesRef =
  FirebaseFirestore.instance.collection('eleves');

  String? selectedComment;
  bool dropdownOpened = false; // 🔹 pour l'icône v / ^

  final List<String> commentaires = [
    "Tous les rendez-vous et toutes les missions ont été réalisés dans les délais.",
    "Les rendez-vous ont été réalisés mais certaines missions n'ont pas été finalisées.",
    "Certaines missions n'ont pas été réalisées en raison de difficultés techniques.",
    "Des retards ont été constatés dans la réalisation des missions.",
    "Les rendez-vous n'ont pas tous été effectués.",
    "Le suivi global de l'étudiant reste satisfaisant malgré quelques retards.",
  ];

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    if (commentaires.contains(widget.commentaireInitial)) {
      selectedComment = widget.commentaireInitial;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      CommentaireNotificationService.verifierNotification(
        context,
        widget.eleveId,
      );
    });
  }

  Future<void> saveCommentaire() async {
    if (_formKey.currentState?.validate() ?? false) {
      await elevesRef.doc(widget.eleveId).update({
        "commentaireFinal": selectedComment,
        "notificationCommentaire": {
          "rappel": true,
          "valide": false,
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Commentaire enregistré"),
        ),
      );

      CommentaireNotificationService.verifierNotification(
        context,
        widget.eleveId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Navigator.canPop(context)
            ? Padding(
          padding: const EdgeInsets.all(8),
          child: squareButton("←", Colors.blue, () {
            Navigator.pop(context);
          }),
        )
            : null,
        title: const Text("Commentaire final"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Commentaire final",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // 🔽 Dropdown avec icône v / ^
              DropdownButtonFormField<String>(
                isExpanded: true,
                hint: const Text("Choisir un commentaire"),
                value: commentaires.contains(selectedComment)
                    ? selectedComment
                    : null,
                items: commentaires.map((comment) {
                  return DropdownMenuItem<String>(
                    value: comment,
                    child: Text(
                      comment,
                      softWrap: true,
                    ),
                  );
                }).toList(),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                icon: Icon(dropdownOpened ? Icons.arrow_drop_up : Icons.arrow_drop_down),
                onTap: () {
                  setState(() {
                    dropdownOpened = !dropdownOpened;
                  });
                },
                onChanged: (value) {
                  setState(() {
                    selectedComment = value;
                    dropdownOpened = false; // fermer après sélection
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Le commentaire final est obligatoire";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: saveCommentaire,
                  child: const Text("Enregistrer"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 🔹 Fonction bouton carré
Widget squareButton(String text, Color color, VoidCallback onPressed) {
  return ElevatedButton(
    onPressed: onPressed,
    style: ElevatedButton.styleFrom(
      backgroundColor: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(0),
      minimumSize: const Size(40, 40),
    ),
    child: Text(
      text,
      style: const TextStyle(color: Colors.white, fontSize: 20),
    ),
  );
}