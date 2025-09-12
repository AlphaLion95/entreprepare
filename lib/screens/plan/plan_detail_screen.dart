import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/plan.dart';
import '../../services/plan_service.dart';
import '../../services/ai_plan_service.dart';

class PlanDetailScreen extends StatefulWidget {
  final Plan plan;
  const PlanDetailScreen({super.key, required this.plan});

  @override
  State<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends State<PlanDetailScreen> {
  late Plan _plan;
  bool _regenLoading = false;
  final _planService = PlanService();
  final _aiPlanService = AiPlanService();

  @override
  void initState() {
    super.initState();
    _plan = widget.plan.withComputedProjection();
  }

  Future<void> _toggleMilestone(Milestone m, bool? val) async {
    final updated = _plan.milestones.map((ms)=> ms.id == m.id ? Milestone(id: ms.id, title: ms.title, done: val ?? false) : ms).toList();
    setState(()=> _plan = Plan(
      id: _plan.id,
      businessId: _plan.businessId,
      title: _plan.title,
      summary: _plan.summary,
      capitalEstimated: _plan.capitalEstimated,
      pricePerUnit: _plan.pricePerUnit,
      estMonthlySales: _plan.estMonthlySales,
      salesAssumptions: _plan.salesAssumptions,
      growthPctMonth: _plan.growthPctMonth,
      inventory: _plan.inventory,
      milestones: updated,
      expenses: _plan.expenses,
      innovations: _plan.innovations,
      grossMarginPct: _plan.grossMarginPct,
      operatingMarginPct: _plan.operatingMarginPct,
      breakevenMonths: _plan.breakevenMonths,
      createdAt: _plan.createdAt,
      planVersion: _plan.planVersion,
      projectedRevenueMonths: _plan.projectedRevenueMonths,
      grossProfitMonths: _plan.grossProfitMonths,
      netProfitMonths: _plan.netProfitMonths,
      cumulativeNetProfitMonths: _plan.cumulativeNetProfitMonths,
      computedBreakevenMonth: _plan.computedBreakevenMonth,
      validationWarnings: _plan.validationWarnings,
    ));
    try {
  await _planService.updatePlan(_plan);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save milestone: $e')));
      }
    }
  }

  Future<void> _regenerateFinancials() async {
    setState(()=> _regenLoading = true);
    try {
      // Provide current plan serialized as context
      final contextJson = {
        'title': _plan.title,
        'summary': _plan.summary,
        'pricing': {'pricePerUnit': _plan.pricePerUnit, 'capitalRequired': _plan.capitalEstimated},
        'sales': {'estMonthlyUnits': _plan.estMonthlySales, 'assumptions': _plan.salesAssumptions, 'growthPctMonth': _plan.growthPctMonth},
        'inventory': _plan.inventory.map((i)=> {'name': i.name, 'qty': i.qty, 'unitCost': i.unitCost}).toList(),
        'expenses': _plan.expenses.map((e)=> {'name': e.name, 'monthlyCost': e.monthlyCost}).toList(),
        'milestones': _plan.milestones.map((m)=> m.title).toList(),
        'innovations': _plan.innovations,
        'metrics': {'grossMarginPct': _plan.grossMarginPct, 'operatingMarginPct': _plan.operatingMarginPct, 'breakevenMonths': _plan.breakevenMonths},
      };
      final resp = await _aiPlanService.regenerateFinancials(context: contextJson.toString());
      // Merge updated financial data into _plan
      final pricing = resp['pricing'] as Map? ?? {};
      final sales = resp['sales'] as Map? ?? {};
      final metrics = resp['metrics'] as Map? ?? {};
      final projRev = (resp['projectedRevenueMonths'] as List? ?? []).map((e)=> (e is num)? e.toDouble(): double.tryParse(e.toString()) ?? 0).toList();
      final grossProf = (resp['grossProfitMonths'] as List? ?? []).map((e)=> (e is num)? e.toDouble(): double.tryParse(e.toString()) ?? 0).toList();
      final netProf = (resp['netProfitMonths'] as List? ?? []).map((e)=> (e is num)? e.toDouble(): double.tryParse(e.toString()) ?? 0).toList();
      final cumNet = (resp['cumulativeNetProfitMonths'] as List? ?? []).map((e)=> (e is num)? e.toDouble(): double.tryParse(e.toString()) ?? 0).toList();
      final updatedPlan = Plan(
        id: _plan.id,
        businessId: _plan.businessId,
        title: _plan.title,
        summary: _plan.summary,
        capitalEstimated: (pricing['capitalRequired'] ?? _plan.capitalEstimated).toDouble(),
        pricePerUnit: (pricing['pricePerUnit'] ?? _plan.pricePerUnit).toDouble(),
        estMonthlySales: (sales['estMonthlyUnits'] ?? _plan.estMonthlySales) is int ? (sales['estMonthlyUnits'] ?? _plan.estMonthlySales) as int : int.tryParse((sales['estMonthlyUnits'] ?? _plan.estMonthlySales).toString()) ?? _plan.estMonthlySales,
        salesAssumptions: (sales['assumptions'] as List? ?? _plan.salesAssumptions).map((e)=> e.toString()).toList(),
        growthPctMonth: (sales['growthPctMonth'] ?? _plan.growthPctMonth).toDouble(),
        inventory: _plan.inventory, // not replaced in partial regen
        milestones: _plan.milestones,
        expenses: _plan.expenses, // keep original list shapes (server returns aggregated)
        innovations: _plan.innovations,
        grossMarginPct: (metrics['grossMarginPct'] ?? _plan.grossMarginPct).toDouble(),
        operatingMarginPct: (metrics['operatingMarginPct'] ?? _plan.operatingMarginPct).toDouble(),
        breakevenMonths: (metrics['breakevenMonths'] ?? _plan.breakevenMonths).toDouble(),
        createdAt: _plan.createdAt,
        planVersion: (resp['planVersion'] ?? _plan.planVersion) is int ? resp['planVersion'] as int : int.tryParse((resp['planVersion'] ?? _plan.planVersion).toString()) ?? _plan.planVersion,
        projectedRevenueMonths: projRev,
        grossProfitMonths: grossProf,
        netProfitMonths: netProf,
        cumulativeNetProfitMonths: cumNet,
        computedBreakevenMonth: resp['computedBreakevenMonth'] == null ? null : int.tryParse(resp['computedBreakevenMonth'].toString()),
        validationWarnings: (resp['validationWarnings'] as List? ?? []).map((e)=> e.toString()).toList(),
      );
      setState(()=> _plan = updatedPlan);
      await _planService.updatePlan(updatedPlan);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Financials regenerated')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Regeneration failed: $e')));
      }
    } finally {
      if (mounted) setState(()=> _regenLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _plan.withComputedProjection();
    String money(double v) => NumberFormat.simpleCurrency().format(v);
  final proj = p.projectedRevenueMonths;
  final gross = p.grossProfitMonths;
  final net = p.netProfitMonths;
  final cumulative = p.cumulativeNetProfitMonths;
  final breakeven = p.computedBreakevenMonth;
    return Scaffold(
      appBar: AppBar(title: Text(p.title), actions: [
        if (_regenLoading)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Center(child: SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2))),
          )
        else
          IconButton(
            tooltip: 'Regenerate financials',
            icon: const Icon(Icons.refresh),
            onPressed: _regenerateFinancials,
          )
      ]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (p.validationWarnings.isNotEmpty)
              _WarningsPanel(warnings: p.validationWarnings),
            if (p.summary.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(p.summary, style: Theme.of(context).textTheme.bodyLarge),
              ),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _metricCard('Price/Unit', money(p.pricePerUnit)),
                _metricCard('Est. Monthly Units', p.estMonthlySales.toString()),
                _metricCard('Growth %/mo', p.growthPctMonth.toStringAsFixed(1)),
                _metricCard('Gross Margin %', p.grossMarginPct.toStringAsFixed(1)),
                _metricCard('Op Margin %', p.operatingMarginPct.toStringAsFixed(1)),
                _metricCard('Breakeven (mo)', p.breakevenMonths.toStringAsFixed(1)),
                _metricCard('Capital Needed', money(p.capitalEstimated)),
                _metricCard('Monthly Revenue', money(p.monthlyRevenue)),
                _metricCard('Monthly Net', money(p.monthlyNetProfit)),
              ],
            ),
            const SizedBox(height: 24),
            _sectionTitle(context, 'Sales Assumptions'),
            if (p.salesAssumptions.isEmpty)
              const Text('None')
            else
              Column(
                children: p.salesAssumptions
                    .map((a) => ListTile(leading: const Icon(Icons.chevron_right), title: Text(a)))
                    .toList(),
              ),
            const SizedBox(height: 24),
            _sectionTitle(context, '6-Month Revenue & Profit Projections'),
            if (proj.isEmpty)
              const Text('Projection unavailable')
            else ...[
              _projectionTable(label: 'Revenue', vals: proj, money: money),
              if (gross.isNotEmpty) _projectionTable(label: 'Gross Profit', vals: gross, money: money),
              if (net.isNotEmpty) _projectionTable(label: 'Net Profit', vals: net, money: money),
              if (cumulative.isNotEmpty)
                _projectionTable(label: 'Cumulative Net', vals: cumulative, money: money, highlightIndex: breakeven != null ? breakeven - 1 : null),
              const SizedBox(height: 12),
              _sectionTitle(context, 'Trend Chart'),
              const SizedBox(height: 8),
              SizedBox(
                height: 160,
                child: _LineChart(
                  series: [
                    _ChartSeries('Revenue', Colors.blue, proj),
                    _ChartSeries('Net', Colors.green, net),
                    _ChartSeries('Cumulative', Colors.purple, cumulative),
                  ],
                ),
              ),
              if (breakeven != null)
                Padding(
                  padding: const EdgeInsets.only(top:8.0),
                  child: Text('Computed breakeven month: M$breakeven', style: const TextStyle(fontWeight: FontWeight.w600)),
                )
            ],
            const SizedBox(height: 24),
            _sectionTitle(context, 'Inventory'),
            if (p.inventory.isEmpty)
              const Text('None')
            else
              Column(
                children: p.inventory.map((i)=>ListTile(
                  dense: true,
                  title: Text(i.name),
                  subtitle: Text('Qty ${i.qty} @ ${money(i.unitCost)}'),
                )).toList(),
              ),
            const SizedBox(height: 24),
            _sectionTitle(context, 'Expenses'),
            if (p.expenses.isEmpty)
              const Text('None')
            else
              Column(
                children: p.expenses.map((e)=>ListTile(
                  dense: true,
                  title: Text(e.name),
                  trailing: Text(money(e.monthlyCost)),
                )).toList(),
              ),
            const SizedBox(height: 24),
            _sectionTitle(context, 'Milestones'),
            if (p.milestones.isEmpty)
              const Text('None')
            else
              Column(
                children: p.milestones.map((m)=>CheckboxListTile(
                  value: m.done,
                  onChanged: (val) => _toggleMilestone(m, val),
                  title: Text(m.title),
                  dense: true,
                  controlAffinity: ListTileControlAffinity.leading,
                )).toList(),
              ),
            const SizedBox(height: 24),
            _sectionTitle(context, 'Innovations'),
            if (p.innovations.isEmpty) const Text('None') else Column(
              children: p.innovations.map((i)=>ListTile(
                dense: true,
                leading: const Icon(Icons.auto_awesome),
                title: Text(i),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricCard(String label, String value) {
    return SizedBox(
      width: 150,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _projectionTable({required String label, required List<double> vals, required String Function(double) money, int? highlightIndex}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Row(children: List.generate(vals.length, (i)=> Expanded(child: Text('M${i+1}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))))),
            const SizedBox(height: 6),
            Row(children: vals.asMap().entries.map((e) {
              final idx = e.key; final v = e.value;
              final highlighted = highlightIndex != null && idx == highlightIndex;
              return Expanded(child: Container(
                decoration: highlighted ? BoxDecoration(color: Colors.green.withOpacity(0.12), borderRadius: BorderRadius.circular(4)) : null,
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(money(v), textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: highlighted ? FontWeight.bold : FontWeight.normal, color: highlighted ? Colors.green.shade800 : null)),
              ));
            }).toList()),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) => Text(text, style: Theme.of(context).textTheme.titleMedium);
}

class _ChartSeries {
  final String label;
  final Color color;
  final List<double> values;
  _ChartSeries(this.label, this.color, this.values);
}

class _LineChart extends StatelessWidget {
  final List<_ChartSeries> series;
  const _LineChart({required this.series});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _LineChartPainter(series),
        );
      },
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<_ChartSeries> series;
  _LineChartPainter(this.series);

  @override
  void paint(Canvas canvas, Size size) {
    final allValues = series.expand((s)=>s.values).toList();
    if (allValues.isEmpty) return;
    final minV = allValues.reduce((a,b)=> a<b?a:b);
    final maxV = allValues.reduce((a,b)=> a>b?a:b);
    final range = (maxV - minV).abs() < 1e-6 ? 1 : (maxV - minV);
    final leftPad = 4.0;
    final bottomPad = 4.0;
    final usableW = size.width - leftPad*2;
    final usableH = size.height - bottomPad*2;
    final paintAxis = Paint()..color = Colors.grey.shade300..strokeWidth = 1;
    // axes
    canvas.drawLine(Offset(leftPad, bottomPad), Offset(leftPad, bottomPad+usableH), paintAxis);
    canvas.drawLine(Offset(leftPad, bottomPad+usableH), Offset(leftPad+usableW, bottomPad+usableH), paintAxis);
    for (final s in series) {
      if (s.values.length < 2) continue;
      final paintLine = Paint()
        ..color = s.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..isAntiAlias = true;
      final path = Path();
      for (var i=0;i<s.values.length;i++) {
        final x = leftPad + (i/(s.values.length-1))*usableW;
        final norm = (s.values[i]-minV)/range;
        final y = bottomPad + usableH - norm*usableH;
        if (i==0) path.moveTo(x,y); else path.lineTo(x,y);
      }
      canvas.drawPath(path, paintLine);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) => true;
}

class _WarningsPanel extends StatelessWidget {
  final List<String> warnings;
  const _WarningsPanel({required this.warnings});

  static const Map<String,String> _map = {
    'price_per_unit_non_positive': 'Price per unit is zero or negative – adjust pricing.',
    'growth_pct_implausible': 'Growth percentage extremely high – verify sales assumptions.',
    'negative_inventory_unit_cost': 'Inventory item has negative unit cost.',
    'negative_expense_monthly_cost': 'An expense has a negative monthly cost.',
    'capital_required_negative': 'Capital required is negative – set to a non-negative value.',
    'units_array_length_not_6': 'Sales projection array not 6 months long.',
    'derivation_error': 'Server failed to derive projections; retry regeneration.'
  };

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
                SizedBox(width: 6),
                Text('Validation Warnings', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 6),
            ...warnings.map((w){
              final msg = _map[w] ?? w;
              return Padding(
                padding: const EdgeInsets.only(bottom:4),
                child: Text('• $msg', style: const TextStyle(fontSize: 12)),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
