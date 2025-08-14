class QuizQuestion {
  final String id; // unique key used when saving answers
  final String question;
  final List<String> options; // for choice-type
  final String type; // "choice" or "slider"
  // slider optional params
  final int? sliderMin;
  final int? sliderMax;
  final int? sliderDivisions;

  QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.type,
    this.sliderMin,
    this.sliderMax,
    this.sliderDivisions,
  });
}
