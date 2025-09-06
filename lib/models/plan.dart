import 'package:cloud_firestore/cloud_firestore.dart';

class PlanItem {
  final String id;
  final String name;
  final int qty;
  final double unitCost;

  PlanItem({
    required this.id,
    required this.name,
    required this.qty,
    required this.unitCost,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'qty': qty,
    'unitCost': unitCost,
  };

  factory PlanItem.fromMap(Map<String, dynamic> m) => PlanItem(
    id: m['id'] ?? '',
    name: (m['name'] ?? '').toString(),
    qty: (m['qty'] ?? 0) as int,
    unitCost: (m['unitCost'] ?? 0).toDouble(),
  );
}

class ExpenseItem {
  final String id;
  final String name;
  final double monthlyCost;

  ExpenseItem({required this.id, required this.name, required this.monthlyCost});

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'monthlyCost': monthlyCost,
      };

  factory ExpenseItem.fromMap(Map<String, dynamic> m) => ExpenseItem(
        id: m['id'] ?? '',
        name: (m['name'] ?? '').toString(),
        monthlyCost: (m['monthlyCost'] ?? 0).toDouble(),
      );
}

class Milestone {
  final String id;
  String title;
  bool done;

  Milestone({required this.id, required this.title, this.done = false});

  Map<String, dynamic> toMap() => {'id': id, 'title': title, 'done': done};

  factory Milestone.fromMap(Map<String, dynamic> m) => Milestone(
    id: m['id'] ?? '',
    title: (m['title'] ?? '').toString(),
    done: (m['done'] ?? false) as bool,
  );
}

class Plan {
  final String id;
  final String businessId;
  final String title;
  final double capitalEstimated;
  final double pricePerUnit;
  final int estMonthlySales;
  final List<PlanItem> inventory;
  final List<Milestone> milestones;
  final List<ExpenseItem> expenses;
  final DateTime createdAt;

  Plan({
    required this.id,
    required this.businessId,
    required this.title,
    required this.capitalEstimated,
    required this.pricePerUnit,
    required this.estMonthlySales,
    this.inventory = const [],
    this.milestones = const [],
  this.expenses = const [],
    required this.createdAt,
  });

  double get monthlyRevenue => pricePerUnit * estMonthlySales;

  double get monthlyCostOfGoods {
    if (inventory.isEmpty) return 0;
    final avgUnitCost =
        inventory.map((i) => i.unitCost).fold<double>(0, (s, e) => s + e) /
        inventory.length;
    return avgUnitCost * estMonthlySales;
  }

  double get monthlyProfit => monthlyRevenue - monthlyCostOfGoods;
  double get monthlyOperatingExpenses =>
      expenses.fold<double>(0.0, (s, e) => s + e.monthlyCost);
  double get monthlyNetProfit => monthlyRevenue - monthlyCostOfGoods - monthlyOperatingExpenses;

  Map<String, dynamic> toMap() => {
    'businessId': businessId,
    'title': title,
    'titleLower': title.trim().toLowerCase(),
    'capitalEstimated': capitalEstimated,
    'pricePerUnit': pricePerUnit,
    'estMonthlySales': estMonthlySales,
    'inventory': inventory.map((i) => i.toMap()).toList(),
    'milestones': milestones.map((m) => m.toMap()).toList(),
  'expenses': expenses.map((e) => e.toMap()).toList(),
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory Plan.fromMap(String id, Map<String, dynamic> m) => Plan(
    id: id,
    businessId: (m['businessId'] ?? '').toString(),
    title: (m['title'] ?? '').toString(),
    capitalEstimated: (m['capitalEstimated'] ?? 0).toDouble(),
    pricePerUnit: (m['pricePerUnit'] ?? 0).toDouble(),
    estMonthlySales: (m['estMonthlySales'] ?? 0) as int,
    inventory: (m['inventory'] as List<dynamic>? ?? [])
        .map((e) => PlanItem.fromMap(Map<String, dynamic>.from(e)))
        .toList(),
    milestones: (m['milestones'] as List<dynamic>? ?? [])
        .map((e) => Milestone.fromMap(Map<String, dynamic>.from(e)))
        .toList(),
  expenses: (m['expenses'] as List<dynamic>? ?? [])
    .map((e) => ExpenseItem.fromMap(Map<String, dynamic>.from(e)))
    .toList(),
    createdAt: m['createdAt'] is Timestamp
        ? (m['createdAt'] as Timestamp).toDate()
        : DateTime.now(),
  );
}
