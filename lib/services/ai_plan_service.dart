import '../config/ai_config.dart';
import 'ai_api_client.dart';

class AiGeneratedPlanResult {
  final String title;
  final String summary;
  final double pricePerUnit;
  final double capitalRequired;
  final int estMonthlyUnits;
  final List<String> salesAssumptions;
  final double growthPctMonth;
  final List<AiPlanInventoryItem> inventory;
  final List<AiPlanExpenseItem> expenses;
  final List<String> milestones;
  final List<String> innovations;
  final double grossMarginPct;
  final double operatingMarginPct;
  final double breakevenMonths;
  final int planVersion;
  AiGeneratedPlanResult({
    required this.title,
    required this.summary,
    required this.pricePerUnit,
    required this.capitalRequired,
    required this.estMonthlyUnits,
    required this.salesAssumptions,
    required this.growthPctMonth,
    required this.inventory,
    required this.expenses,
    required this.milestones,
    required this.innovations,
    required this.grossMarginPct,
    required this.operatingMarginPct,
    required this.breakevenMonths,
    required this.planVersion,
  });
}

class AiPlanInventoryItem {
  final String name;
  final int qty;
  final double unitCost;
  AiPlanInventoryItem({required this.name, required this.qty, required this.unitCost});
}

class AiPlanExpenseItem {
  final String name;
  final double monthlyCost;
  AiPlanExpenseItem({required this.name, required this.monthlyCost});
}

class AiPlanService {
  late final AiApiClient _client;

  AiPlanService() {
    _client = AiApiClient(
      baseUrl: kAiMilestoneEndpoint,
      debug: kAiDebugLogging,
    );
  }
  Future<AiGeneratedPlanResult> generate({required String context, required String suggestion}) async {
    if (!(kAiRemoteEnabled && kAiMilestoneEndpoint.isNotEmpty)) {
      throw Exception('Remote AI disabled. Configure endpoints and enable.');
    }
    try {
      final data = await _client.postType('plan', {'context': context, 'suggestion': suggestion});
      if (data['plan'] is Map) {
        final p = data['plan'] as Map<String,dynamic>;
        final pricing = (p['pricing'] as Map?) ?? {};
        final sales = (p['sales'] as Map?) ?? {};
        final metrics = (p['metrics'] as Map?) ?? {};
        List<AiPlanInventoryItem> inv = [];
        if (p['inventory'] is List) {
          inv = (p['inventory'] as List)
              .map((e) => e is Map ? AiPlanInventoryItem(
                    name: (e['name'] ?? '').toString(),
                    qty: (e['qty'] ?? 0) is int ? e['qty'] as int : int.tryParse(e['qty'].toString()) ?? 0,
                    unitCost: (e['unitCost'] ?? 0).toDouble(),
                  ) : null)
              .whereType<AiPlanInventoryItem>()
              .toList();
        }
        List<AiPlanExpenseItem> exps = [];
        if (p['expenses'] is List) {
          exps = (p['expenses'] as List)
              .map((e) => e is Map ? AiPlanExpenseItem(
                    name: (e['name'] ?? '').toString(),
                    monthlyCost: (e['monthlyCost'] ?? 0).toDouble(),
                  ) : null)
              .whereType<AiPlanExpenseItem>()
              .toList();
        }
        return AiGeneratedPlanResult(
          title: (p['title'] ?? '').toString(),
            summary: (p['summary'] ?? '').toString(),
            pricePerUnit: (pricing['pricePerUnit'] ?? 0).toDouble(),
            capitalRequired: (pricing['capitalRequired'] ?? 0).toDouble(),
            estMonthlyUnits: (sales['estMonthlyUnits'] ?? 0) is int ? sales['estMonthlyUnits'] as int : int.tryParse(sales['estMonthlyUnits'].toString()) ?? 0,
            salesAssumptions: (sales['assumptions'] as List? ?? []).map((e)=>e.toString()).toList(),
            growthPctMonth: (sales['growthPctMonth'] ?? 0).toDouble(),
            inventory: inv,
            expenses: exps,
            milestones: (p['milestones'] as List? ?? []).map((e)=>e.toString()).toList(),
            innovations: (p['innovations'] as List? ?? []).map((e)=>e.toString()).toList(),
            grossMarginPct: (metrics['grossMarginPct'] ?? 0).toDouble(),
            operatingMarginPct: (metrics['operatingMarginPct'] ?? 0).toDouble(),
            breakevenMonths: (metrics['breakevenMonths'] ?? 0).toDouble(),
            planVersion: (data['planVersion'] ?? p['planVersion'] ?? 1) is int ? (data['planVersion'] ?? p['planVersion'] ?? 1) as int : int.tryParse((data['planVersion'] ?? p['planVersion'] ?? '1').toString()) ?? 1,
        );
      }
      throw Exception('Malformed AI plan response');
    } on AiApiException catch (e) {
      // Surface unsupported_type clearly so UI can hint redeploy or mismatch
      throw Exception('AI plan failed: ${e.code}${e.message!=null?': '+e.message!:''}');
    }
  }

  Future<Map<String, dynamic>> regenerateFinancials({required String context}) async {
    if (!(kAiRemoteEnabled && kAiMilestoneEndpoint.isNotEmpty)) {
      throw Exception('Remote AI disabled. Configure endpoints and enable.');
    }
    try {
      final data = await _client.postType('plan_financials', {'context': context});
      if (data['plan'] is Map) {
        final p = data['plan'] as Map<String,dynamic>;
        return {
          'pricing': p['pricing'] ?? {},
          'sales': p['sales'] ?? {},
          'expenses': p['expenses'] ?? {},
            'inventory': p['inventory'] ?? {},
          'metrics': p['metrics'] ?? {},
          'projectedRevenueMonths': p['projectedRevenueMonths'] ?? [],
          'grossProfitMonths': p['grossProfitMonths'] ?? [],
          'netProfitMonths': p['netProfitMonths'] ?? [],
          'cumulativeNetProfitMonths': p['cumulativeNetProfitMonths'] ?? [],
          'computedBreakevenMonth': p['computedBreakevenMonth'],
          'validationWarnings': p['validationWarnings'] ?? [],
          'planVersion': data['planVersion'] ?? 4,
        };
      }
      throw Exception('Malformed plan_financials response');
    } on AiApiException catch (e) {
      throw Exception('AI plan_financials failed: ${e.code}${e.message!=null?': '+e.message!:''}');
    }
  }
}
