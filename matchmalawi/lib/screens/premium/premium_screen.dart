import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../models/subscription_model.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  String _selectedPlan = 'platinum';
  String _selectedPaymentMethod = '';
  final _phoneController = TextEditingController();
  bool _isProcessing = false;

  final Map<String, IconData> _planIcons = {
    'gold': Icons.star_rounded,
    'platinum': Icons.diamond_rounded,
    'diamond': Icons.auto_awesome_rounded,
  };

  final Map<String, Color> _planColors = {
    'gold': const Color(0xFFFFD700),
    'platinum': const Color(0xFFE5E4E2),
    'diamond': const Color(0xFFB9F2FF),
  };

  final List<Map<String, dynamic>> _paymentMethods = [
    {'id': 'airtel', 'name': 'Airtel Money', 'icon': Icons.phone_android, 'ussd': '*777#'},
    {'id': 'tnm', 'name': 'TNM Mpamba', 'icon': Icons.phone_android, 'ussd': '*444#'},
    {'id': 'visa', 'name': 'Visa / Mastercard', 'icon': Icons.credit_card, 'ussd': null},
  ];

  final List<Map<String, String>> _faqs = [
    {
      'q': 'How do I cancel my subscription?',
      'a': 'Go to Settings > Premium > Manage Subscription to cancel. You will retain access until the end of your billing period.',
    },
    {
      'q': 'Can I change my plan?',
      'a': 'Yes, you can upgrade or downgrade at any time. Changes take effect at the start of your next billing cycle.',
    },
    {
      'q': 'Is my payment secure?',
      'a': 'All payments are processed through secure, encrypted channels. We never store your payment details.',
    },
    {
      'q': 'How do mobile money payments work?',
      'a': 'After selecting a plan, you will receive a USSD prompt on your phone to confirm the payment via Airtel Money or TNM Mpamba.',
    },
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  double _getSelectedPrice() {
    final plan = SubscriptionModel.plans[_selectedPlan];
    return (plan?['price'] ?? 0).toDouble();
  }

  Future<void> _processSubscription() async {
    if (_selectedPaymentMethod.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment method'), backgroundColor: AppTheme.errorColor),
      );
      return;
    }

    if ((_selectedPaymentMethod == 'airtel' || _selectedPaymentMethod == 'tnm') &&
        _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your phone number'), backgroundColor: AppTheme.errorColor),
      );
      return;
    }

    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(seconds: 3));
    setState(() => _isProcessing = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subscription activated successfully!'), backgroundColor: AppTheme.successColor),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('Premium')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroSection(),
            const SizedBox(height: 24),
            if (user?.isPremiumActive == true) _buildCurrentPlanBanner(user!),
            _buildPlansSection(),
            const SizedBox(height: 24),
            _buildPaymentSection(),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _processSubscription,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                  ),
                  child: _isProcessing
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
                          'Subscribe Now - MWK ${_getSelectedPrice().toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () {},
                child: const Text('Restore Purchase', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
              ),
            ),
            const SizedBox(height: 24),
            _buildFAQSection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.accentColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.diamond_rounded, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 16),
          const Text(
            'Find Your Perfect Match Faster',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Unlock all premium features and boost your profile visibility.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.9)),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPlanBanner(dynamic user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.successColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.successColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppTheme.successColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Current Plan', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                Text(
                  '${user.premiumPlan ?? "N/A"} - Expires ${user.premiumExpiry != null ? "${user.premiumExpiry!.day}/${user.premiumExpiry!.month}/${user.premiumExpiry!.year}" : "N/A"}',
                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlansSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Choose a Plan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 4),
          const Text('All plans are billed monthly', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          const SizedBox(height: 16),
          ...SubscriptionModel.plans.entries.map((entry) {
            final planId = entry.key;
            final plan = entry.value;
            final isSelected = _selectedPlan == planId;
            final color = _planColors[planId] ?? AppTheme.primaryColor;
            final isBestValue = planId == 'platinum';

            return GestureDetector(
              onTap: () => setState(() => _selectedPlan = planId),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryColor : AppTheme.dividerColor,
                    width: isSelected ? 2.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4))]
                      : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(_planIcons[planId], color: color, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(plan['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                                  if (isBestValue) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(colors: [AppTheme.primaryColor, AppTheme.accentColor]),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text('BEST VALUE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'MWK ${plan['price']}',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                            ),
                            Text('/${plan['duration']} days', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: (plan['features'] as List).map((feature) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_rounded, size: 14, color: AppTheme.successColor),
                            const SizedBox(width: 4),
                            Text(feature, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Payment Method', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 16),
          ..._paymentMethods.map((method) {
            final isSelected = _selectedPaymentMethod == method['id'];
            return GestureDetector(
              onTap: () => setState(() => _selectedPaymentMethod = method['id']),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryColor : AppTheme.dividerColor,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(method['icon'] as IconData, color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            method['name'],
                            style: TextStyle(fontSize: 15, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal, color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary),
                          ),
                        ),
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: isSelected ? AppTheme.primaryColor : AppTheme.textHint, width: 2),
                          ),
                          child: isSelected
                              ? const Center(child: Icon(Icons.circle, size: 12, color: AppTheme.primaryColor))
                              : null,
                        ),
                      ],
                    ),
                    if (isSelected && method['ussd'] != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            const Text('Dial this USSD code to pay:', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                            const SizedBox(height: 4),
                            Text(
                              method['ussd']!,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryColor, letterSpacing: 2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
          if (_selectedPaymentMethod == 'airtel' || _selectedPaymentMethod == 'tnm') ...[
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: const Icon(Icons.phone_outlined, color: AppTheme.primaryColor),
                hintText: 'e.g. 0991234567',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.dividerColor)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.dividerColor)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFAQSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Frequently Asked Questions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 16),
          ..._faqs.map((faq) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                title: Text(faq['q']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                children: [
                  Text(faq['a']!, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.5)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
