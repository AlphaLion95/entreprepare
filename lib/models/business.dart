class Business {
  final String title;
  final List<String> personality;
  final List<String> budget;
  final List<String> time;
  final List<String> skills;
  final List<String> environment;
  final String description;
  final String cost;
  final String earnings;
  final List<String> initialSteps;
  final String? docId;

  Business({
    required this.title,
    required this.personality,
    required this.budget,
    required this.time,
    required this.skills,
    required this.environment,
    required this.description,
    required this.cost,
    required this.earnings,
    required this.initialSteps,
    this.docId,
  });

  factory Business.fromMap(Map<String, dynamic> map, {String? docId}) {
    return Business(
      title: map['title'] ?? '',
      personality: List<String>.from(map['personality'] ?? []),
      budget: List<String>.from(map['budget'] ?? []),
      time: List<String>.from(map['time'] ?? []),
      skills: List<String>.from(map['skills'] ?? []),
      environment: List<String>.from(map['environment'] ?? []),
      description: map['description'] ?? '',
      cost: map['cost'] ?? '',
      earnings: map['earnings'] ?? '',
      initialSteps: List<String>.from(map['initialSteps'] ?? []),
      docId: docId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'personality': personality,
      'budget': budget,
      'time': time,
      'skills': skills,
      'environment': environment,
      'description': description,
      'cost': cost,
      'earnings': earnings,
      'initialSteps': initialSteps,
    };
  }
}
