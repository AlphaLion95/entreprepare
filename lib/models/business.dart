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
    // helper to normalize a field that may be String, Iterable, Map or already a List<String>
    List<String> _toStringList(dynamic v) {
      if (v == null) return <String>[];
      if (v is String) return [v];
      if (v is Iterable) return v.map((e) => e?.toString() ?? '').toList();
      if (v is Map) return v.values.map((e) => e?.toString() ?? '').toList();
      return [v.toString()];
    }

    return Business(
      title: map['title']?.toString() ?? '',
      personality: _toStringList(map['personality']),
      budget: _toStringList(map['budget']),
      time: _toStringList(map['time']),
      skills: _toStringList(map['skills']),
      environment: _toStringList(map['environment']),
      description: map['description']?.toString() ?? '',
      cost: map['cost']?.toString() ?? '',
      earnings: map['earnings']?.toString() ?? '',
      initialSteps: _toStringList(map['initialSteps']),
      docId: docId ?? (map['__docId']?.toString()),
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
