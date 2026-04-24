import 'package:flutter/material.dart';
import '../models/plan_model.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';

class PricingBottomSheet extends StatefulWidget {
  final String gymId;

  const PricingBottomSheet({super.key, required this.gymId});

  @override
  State<PricingBottomSheet> createState() => _PricingBottomSheetState();
}

class _PricingBottomSheetState extends State<PricingBottomSheet> {
  late Future<List<Plan>> _futurePlans;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _futurePlans = _apiService.fetchGymPlans(widget.gymId);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.scaffoldBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              height: 5,
              width: 50,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const Text(
            'Membership Plans',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textMain),
          ),
          const SizedBox(height: 16),

          // Content
          Flexible(
            child: FutureBuilder<List<Plan>>(
              future: _futurePlans,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(color: AppColors.primaryLight),
                  );
                } else if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white54)),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Text('No pricing plans available.', style: TextStyle(color: AppColors.textMuted)),
                  );
                }

                final plans = snapshot.data!;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(left: 20, right: 20, bottom: 40),
                  itemCount: plans.length,
                  itemBuilder: (context, index) {
                    return _buildPlanCard(plans[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(Plan plan) {
    // Determine the best price to show
    final displayPrice = plan.offerPrice > 0 ? plan.offerPrice : plan.price;
    final hasDiscount = plan.offerPrice > 0 && plan.offerPrice < plan.price;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name.toUpperCase(),
                      style: const TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plan.tagline.isNotEmpty ? plan.tagline : '${plan.durationMonths} Months Plan',
                      style: const TextStyle(color: AppColors.textMain, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (hasDiscount)
                    Text(
                      '₹${plan.price.toStringAsFixed(0)}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 14, decoration: TextDecoration.lineThrough),
                    ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('₹', style: TextStyle(color: AppColors.textMain, fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(
                        displayPrice.toStringAsFixed(0),
                        style: const TextStyle(color: AppColors.textMain, fontSize: 28, fontWeight: FontWeight.w900, height: 1),
                      ),
                    ],
                  ),
                  Text(
                    '/${plan.billingCycle}',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              )
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Colors.white10, height: 1),
          ),
          _buildFeatureRow(Icons.check_circle_rounded, '${plan.durationMonths} Months Access', true),
          if (plan.includesTrainer) _buildFeatureRow(Icons.check_circle_rounded, 'Personal Trainer Included', true),
          if (plan.includesDietPlan) _buildFeatureRow(Icons.check_circle_rounded, 'Custom Diet Plan', true),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Select Plan', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text, bool included) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: included ? AppColors.primaryLight : Colors.white24),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              color: included ? AppColors.textMain : AppColors.textMuted,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}