class Mission {
  String annee;
  DateTime dateMission;
  String statut;
  String commentaire;

  Mission({
    required this.annee,
    required this.dateMission,
    this.statut = '',
    this.commentaire = '',
  });

  String getStatut() => statut;

  void setStatut(String nouveauStatut) {
    statut = nouveauStatut;
  }

  void ajouterCommentaire(String newCommentaire) {
    commentaire += '\n$newCommentaire';
  }

  DateTime getDateMission() => dateMission;
}