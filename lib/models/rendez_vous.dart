class RendezVous {
  String theme;
  DateTime date;
  List<String> statut;
  String commentaire;

  RendezVous({
    required this.theme,
    required this.date,
    this.statut = const [],
    this.commentaire = '',
  });

  void ajouterCommentaire(String newCommentaire) {
    commentaire += '\n$newCommentaire';
  }

  void setStatut(List<String> nouveauxStatuts) {
    statut = nouveauxStatuts;
  }
}