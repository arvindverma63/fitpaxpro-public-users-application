class Plan {
  final String id;
  final String name;
  final String tagline;
  final double price;
  final double offerPrice;
  final int durationMonths;
  final String billingCycle;
  final bool includesDietPlan;
  final bool includesTrainer;

  Plan({
    required this.id,
    required this.name,
    required this.tagline,
    required this.price,
    required this.offerPrice,
    required this.durationMonths,
    required this.billingCycle,
    required this.includesDietPlan,
    required this.includesTrainer,
  });

  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Standard Plan',
      tagline: json['tagline'] ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0.0') ?? 0.0,
      offerPrice: double.tryParse(json['offer_price']?.toString() ?? '0.0') ?? 0.0,
      durationMonths: json['duration_months'] ?? 1,
      billingCycle: json['billing_cycle'] ?? 'monthly',
      includesDietPlan: json['includes_diet_plan'] == true,
      includesTrainer: json['includes_trainer'] == true,
    );
  }
}