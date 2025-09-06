class SuggestedPlanTemplate {
  final double capital;
  final double pricePerUnit;
  final int estMonthlySales;
  final List<Map<String, dynamic>> inventory; // { name, qty, unitCost }
  final List<String> milestones;

  const SuggestedPlanTemplate({
    required this.capital,
    required this.pricePerUnit,
    required this.estMonthlySales,
    required this.inventory,
    required this.milestones,
  });
}

SuggestedPlanTemplate? getTemplateForTitle(String title) {
  final t = title.toLowerCase();

  SuggestedPlanTemplate tmpl(
    double capital,
    double price,
    int sales,
    double perUnitCost,
    List<String> ms,
  ) => SuggestedPlanTemplate(
    capital: capital,
    pricePerUnit: price,
    estMonthlySales: sales,
    inventory: [
      {'name': 'Per-unit variable cost', 'qty': 1, 'unitCost': perUnitCost},
    ],
    milestones: ms,
  );

  if (t.contains('web dev') || t.contains('web') && t.contains('free')) {
    return tmpl(1000, 1500, 2, 50, [
      'Build a portfolio site',
      'Create profiles on freelance platforms',
      'Land first client',
      'Collect testimonials',
      'Refine pricing packages',
    ]);
  }
  if (t.contains('data entry')) {
    return tmpl(200, 200, 5, 3, [
      'Set up profiles on platforms',
      'Create data accuracy checklist',
      'Secure first 3 clients',
      'Automate common tasks',
    ]);
  }
  if (t.contains('graphic') && t.contains('design')) {
    return tmpl(300, 200, 6, 10, [
      'Build a design portfolio',
      'Define service packages',
      'Reach out to 20 prospects',
      'Publish case studies',
    ]);
  }
  if (t.contains('boutique') || t.contains('clothing')) {
    return tmpl(40000, 45, 800, 20, [
      'Source suppliers',
      'Secure retail or online storefront',
      'Launch initial collection',
      'Run opening campaign',
      'Optimize inventory turns',
    ]);
  }
  if (t.contains('event planner')) {
    return tmpl(5000, 3000, 4, 500, [
      'Build vendor network',
      'Create sample packages',
      'Book first paid event',
      'Gather reviews and referrals',
    ]);
  }
  if (t.contains('social media')) {
    return tmpl(300, 500, 6, 20, [
      'Define content pillars',
      'Create sample calendar',
      'Acquire 3 retainer clients',
      'Measure and optimize KPIs',
    ]);
  }
  if (t.contains('food truck')) {
    return tmpl(80000, 12, 3000, 5, [
      'Finalize menu and pricing',
      'Acquire truck and permits',
      'Test locations/events',
      'Launch social promos',
    ]);
  }
  if (t.contains('restaurant') || t.contains('cafe')) {
    return tmpl(150000, 15, 8000, 6, [
      'Secure location and licenses',
      'Finalize menu & suppliers',
      'Hire and train staff',
      'Soft opening and feedback',
    ]);
  }
  if (t.contains('tech startup')) {
    return tmpl(50000, 30, 1500, 5, [
      'Validate problem and market',
      'Build MVP',
      'Onboard first 100 users',
      'Iterate to product-market fit',
    ]);
  }
  if (t.contains('mobile app')) {
    return tmpl(3000, 4000, 2, 200, [
      'Define app scope and MVP',
      'Build prototype',
      'Get first client launch',
      'Collect feedback and iterate',
    ]);
  }
  if (t.contains('e-commerce') || t.contains('ecommerce')) {
    return tmpl(5000, 25, 2000, 12, [
      'Choose niche & suppliers',
      'Launch storefront',
      'Run ads and optimize funnel',
      'Scale logistics & CS',
    ]);
  }
  if (t.contains('dropshipping')) {
    return tmpl(1000, 30, 1000, 18, [
      'Find reliable suppliers',
      'Validate product-market fit',
      'Launch store & ads',
      'Optimize ROAS and LTV',
    ]);
  }
  if (t.contains('youtube')) {
    return tmpl(1500, 700, 3, 50, [
      'Define niche and schedule',
      'Publish 10 videos',
      'Reach 1k subscribers',
      'Pitch first sponsors',
    ]);
  }
  if (t.contains('fitness') || t.contains('trainer')) {
    return tmpl(500, 40, 120, 5, [
      'Get certifications',
      'Define training packages',
      'Get 5 recurring clients',
      'Collect testimonials',
    ]);
  }
  if (t.contains('tutor') || t.contains('tutoring')) {
    return tmpl(300, 25, 160, 3, [
      'Define curriculum',
      'Set up tutoring profiles',
      'Get first 10 students',
      'Collect reviews',
    ]);
  }
  if (t.contains('handmade') || t.contains('craft')) {
    return tmpl(800, 30, 200, 12, [
      'Create product line',
      'Set up marketplace listings',
      'Launch social promos',
      'Join craft fairs',
    ]);
  }
  if (t.contains('travel blog') ||
      (t.contains('travel') && t.contains('blog'))) {
    return tmpl(2000, 500, 4, 50, [
      'Publish 20 articles',
      'Reach 10k monthly readers',
      'Pitch sponsorships',
      'Build affiliate partnerships',
    ]);
  }
  if (t.contains('photography')) {
    return tmpl(4000, 600, 8, 100, [
      'Build portfolio & packages',
      'Partner with event planners',
      'Book first 5 shoots',
      'Upsell prints/albums',
    ]);
  }
  if (t.contains('consult')) {
    return tmpl(3000, 5000, 2, 300, [
      'Define niche and offers',
      'Publish case studies',
      'Acquire 2 anchor clients',
      'Build referral pipeline',
    ]);
  }
  if (t.contains('game') || (t.contains('app') && t.contains('studio'))) {
    return tmpl(30000, 20000, 1, 2000, [
      'Assemble team',
      'Prototype core loop',
      'Secure first contract/funding',
      'Soft launch and iterate',
    ]);
  }

  // Generic fallback
  return tmpl(1000, 100, 50, 20, [
    'Validate market and pricing',
    'Set up basic operations',
    'Acquire first customers',
    'Collect feedback and refine',
  ]);
}
