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

  ExpenseItem({
    required this.id,
    required this.name,
    required this.monthlyCost,
  });

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
  final String summary; // AI generated one-line or short overview
  final double capitalEstimated;
  final double pricePerUnit;
  final int estMonthlySales;
  final List<String> salesAssumptions; // AI generated assumptions
  final double growthPctMonth; // projected monthly unit growth % (0-100 approx)
  final List<PlanItem> inventory;
  final List<Milestone> milestones;
  final List<ExpenseItem> expenses;
  final List<String> innovations; // distinctive innovation ideas
  final double grossMarginPct; // 0-100
  final double operatingMarginPct; // 0-100
  final double breakevenMonths; // months to breakeven
  final DateTime createdAt;
  final int planVersion; // schema version for forward evolution
  final List<double>
  projectedRevenueMonths; // 6-month forward revenue projection
  final List<double> grossProfitMonths; // 6-month gross profit projection
  final List<double> netProfitMonths; // 6-month net profit projection
  final List<double> cumulativeNetProfitMonths; // cumulative net profit
  final int?
  computedBreakevenMonth; // 1-based month number when cumulative net turns >=0
  final List<String>
  validationWarnings; // server-side flags for implausible values

  Plan({
    required this.id,
    required this.businessId,
    required this.title,
    this.summary = '',
    required this.capitalEstimated,
    required this.pricePerUnit,
    required this.estMonthlySales,
    this.salesAssumptions = const [],
    this.growthPctMonth = 0,
    this.inventory = const [],
    this.milestones = const [],
    this.expenses = const [],
    this.innovations = const [],
    this.grossMarginPct = 0,
    this.operatingMarginPct = 0,
    this.breakevenMonths = 0,
    required this.createdAt,
    this.planVersion = 1,
    this.projectedRevenueMonths = const [],
    this.grossProfitMonths = const [],
    this.netProfitMonths = const [],
    this.cumulativeNetProfitMonths = const [],
    this.computedBreakevenMonth,
    this.validationWarnings = const [],
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
  double get monthlyNetProfit =>
      monthlyRevenue - monthlyCostOfGoods - monthlyOperatingExpenses;

  Map<String, dynamic> toMap() => {
    'businessId': businessId,
    'title': title,
    'titleLower': title.trim().toLowerCase(),
    'summary': summary,
    'capitalEstimated': capitalEstimated,
    'pricePerUnit': pricePerUnit,
    'estMonthlySales': estMonthlySales,
    'salesAssumptions': salesAssumptions,
    'growthPctMonth': growthPctMonth,
    'inventory': inventory.map((i) => i.toMap()).toList(),
    'milestones': milestones.map((m) => m.toMap()).toList(),
    'expenses': expenses.map((e) => e.toMap()).toList(),
    'innovations': innovations,
    'grossMarginPct': grossMarginPct,
    'operatingMarginPct': operatingMarginPct,
    'breakevenMonths': breakevenMonths,
    'createdAt': Timestamp.fromDate(createdAt),
    'planVersion': planVersion,
    'projectedRevenueMonths': projectedRevenueMonths,
    'grossProfitMonths': grossProfitMonths,
    'netProfitMonths': netProfitMonths,
    'cumulativeNetProfitMonths': cumulativeNetProfitMonths,
    'computedBreakevenMonth': computedBreakevenMonth,
    'validationWarnings': validationWarnings,
  };

  factory Plan.fromMap(String id, Map<String, dynamic> m) => Plan(
    id: id,
    businessId: (m['businessId'] ?? '').toString(),
    title: (m['title'] ?? '').toString(),
    summary: (m['summary'] ?? '').toString(),
    capitalEstimated: (m['capitalEstimated'] ?? 0).toDouble(),
    pricePerUnit: (m['pricePerUnit'] ?? 0).toDouble(),
    estMonthlySales: (m['estMonthlySales'] ?? 0) as int,
    salesAssumptions: (m['salesAssumptions'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList(),
    growthPctMonth: (m['growthPctMonth'] ?? 0).toDouble(),
    inventory: (m['inventory'] as List<dynamic>? ?? [])
        .map((e) => PlanItem.fromMap(Map<String, dynamic>.from(e)))
        .toList(),
    milestones: (m['milestones'] as List<dynamic>? ?? [])
        .map((e) => Milestone.fromMap(Map<String, dynamic>.from(e)))
        .toList(),
    expenses: (m['expenses'] as List<dynamic>? ?? [])
        .map((e) => ExpenseItem.fromMap(Map<String, dynamic>.from(e)))
        .toList(),
    innovations: (m['innovations'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList(),
    grossMarginPct: (m['grossMarginPct'] ?? 0).toDouble(),
    operatingMarginPct: (m['operatingMarginPct'] ?? 0).toDouble(),
    breakevenMonths: (m['breakevenMonths'] ?? 0).toDouble(),
    createdAt: m['createdAt'] is Timestamp
        ? (m['createdAt'] as Timestamp).toDate()
        : DateTime.now(),
    planVersion: (m['planVersion'] ?? 1) as int,
    projectedRevenueMonths:
        (m['projectedRevenueMonths'] as List<dynamic>? ?? []).map((e) {
          try {
            return (e is num) ? e.toDouble() : double.parse(e.toString());
          } catch (_) {
            return 0.0;
          }
        }).toList(),
    grossProfitMonths: (m['grossProfitMonths'] as List<dynamic>? ?? []).map((
      e,
    ) {
      try {
        return (e is num) ? e.toDouble() : double.parse(e.toString());
      } catch (_) {
        return 0.0;
      }
    }).toList(),
    netProfitMonths: (m['netProfitMonths'] as List<dynamic>? ?? []).map((e) {
      try {
        return (e is num) ? e.toDouble() : double.parse(e.toString());
      } catch (_) {
        return 0.0;
      }
    }).toList(),
    cumulativeNetProfitMonths:
        (m['cumulativeNetProfitMonths'] as List<dynamic>? ?? []).map((e) {
          try {
            return (e is num) ? e.toDouble() : double.parse(e.toString());
          } catch (_) {
            return 0.0;
          }
        }).toList(),
    computedBreakevenMonth: m['computedBreakevenMonth'] == null
        ? null
        : int.tryParse(m['computedBreakevenMonth'].toString()),
    validationWarnings: (m['validationWarnings'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList(),
  );

  // Compute 6-month revenue projection if not stored
  Plan withComputedProjection() {
    if (projectedRevenueMonths.isNotEmpty &&
        grossProfitMonths.isNotEmpty &&
        netProfitMonths.isNotEmpty)
      return this;
    final growth = growthPctMonth.clamp(0, 300); // cap unrealistic
    final List<double> rev = [];
    final List<double> gross = [];
    final List<double> net = [];
    final List<double> cumulative = [];
    final avgUnitCost = inventory.isEmpty
        ? 0
        : inventory.map((i) => i.unitCost).fold<double>(0, (s, e) => s + e) /
              inventory.length;
    final fixed = monthlyOperatingExpenses; // already sums expenses
    double cum = 0;
    double units = estMonthlySales.toDouble();
    for (int i = 0; i < 6; i++) {
      final monthRevenue = units * pricePerUnit;
      final revenueVal = double.parse(monthRevenue.toStringAsFixed(2));
      final cogs = revenueVal == 0 ? 0 : (units * avgUnitCost);
      final grossVal = double.parse((revenueVal - cogs).toStringAsFixed(2));
      final netVal = double.parse((grossVal - fixed).toStringAsFixed(2));
      cum = double.parse((cum + netVal).toStringAsFixed(2));
      rev.add(revenueVal);
      gross.add(grossVal);
      net.add(netVal);
      cumulative.add(cum);
      units = units * (1 + growth / 100.0);
    }
    return Plan(
      id: id,
      businessId: businessId,
      title: title,
      summary: summary,
      capitalEstimated: capitalEstimated,
      pricePerUnit: pricePerUnit,
      estMonthlySales: estMonthlySales,
      salesAssumptions: salesAssumptions,
      growthPctMonth: growthPctMonth,
      inventory: inventory,
      milestones: milestones,
      expenses: expenses,
      innovations: innovations,
      grossMarginPct: grossMarginPct,
      operatingMarginPct: operatingMarginPct,
      breakevenMonths: breakevenMonths,
      createdAt: createdAt,
      planVersion: planVersion,
      projectedRevenueMonths: rev,
      grossProfitMonths: gross,
      netProfitMonths: net,
      cumulativeNetProfitMonths: cumulative,
      computedBreakevenMonth: cumulative.indexWhere((v) => v >= 0) == -1
          ? null
          : (cumulative.indexWhere((v) => v >= 0) + 1),
    );
  }
}
