import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_theme.dart';

/// Step 5 — collects household head, size, demographics, income, and contact details.
class HouseholdInfoStep extends StatefulWidget {
  final TextEditingController householdHeadController;
  final TextEditingController householdSizeController;
  final TextEditingController phoneController;
  final TextEditingController malesController;
  final TextEditingController femalesController;
  final TextEditingController childrenController; // under 18
  final TextEditingController adultsController; // 18-64
  final TextEditingController pensionersController;
  final TextEditingController chronicController;

  // New: Income & employment
  final ValueNotifier<String?> incomeBracketNotifier;
  final TextEditingController employedController;
  final TextEditingController unemployedController;
  final TextEditingController grantRecipientsController;

  const HouseholdInfoStep({
    super.key,
    required this.householdHeadController,
    required this.householdSizeController,
    required this.phoneController,
    required this.malesController,
    required this.femalesController,
    required this.childrenController,
    required this.adultsController,
    required this.pensionersController,
    required this.chronicController,
    required this.incomeBracketNotifier,
    required this.employedController,
    required this.unemployedController,
    required this.grantRecipientsController,
  });

  @override
  State<HouseholdInfoStep> createState() => _HouseholdInfoStepState();
}

class _HouseholdInfoStepState extends State<HouseholdInfoStep> {
  String? _validationError;

  // SA indigent policy brackets
  static const List<String> _incomeBrackets = [
    'R0 - R800',
    'R801 - R3,500',
    'R3,501 - R7,500',
    'R7,501+',
    'Prefer not to say',
  ];

  @override
  void initState() {
    super.initState();
    widget.malesController.addListener(_validateTotals);
    widget.femalesController.addListener(_validateTotals);
    widget.childrenController.addListener(_validateTotals);
    widget.adultsController.addListener(_validateTotals);
    widget.pensionersController.addListener(_validateTotals);
    widget.employedController.addListener(_validateTotals);
    widget.unemployedController.addListener(_validateTotals);
  }

  @override
  void dispose() {
    widget.malesController.removeListener(_validateTotals);
    widget.femalesController.removeListener(_validateTotals);
    widget.childrenController.removeListener(_validateTotals);
    widget.adultsController.removeListener(_validateTotals);
    widget.pensionersController.removeListener(_validateTotals);
    widget.employedController.removeListener(_validateTotals);
    widget.unemployedController.removeListener(_validateTotals);
    super.dispose();
  }

  void _validateTotals() {
    final males = int.tryParse(widget.malesController.text) ?? 0;
    final females = int.tryParse(widget.femalesController.text) ?? 0;
    final children = int.tryParse(widget.childrenController.text) ?? 0;
    final adults = int.tryParse(widget.adultsController.text) ?? 0;
    final pensioners = int.tryParse(widget.pensionersController.text) ?? 0;
    final total = int.tryParse(widget.householdSizeController.text) ?? 0;
    final employed = int.tryParse(widget.employedController.text) ?? 0;
    final unemployed = int.tryParse(widget.unemployedController.text) ?? 0;

    String? error;
    final genderTotal = males + females;
    final ageTotal = children + adults + pensioners;
    final workingAge = adults + pensioners;
    final employmentTotal = employed + unemployed;

    if (genderTotal > 0 && genderTotal != total) {
      error = 'Males + Females ($genderTotal) ≠ Total ($total)';
    } else if (ageTotal > 0 && ageTotal != total) {
      error = 'Age groups ($ageTotal) ≠ Total ($total)';
    } else if (employmentTotal > workingAge && workingAge > 0) {
      error =
          'Employed + Unemployed ($employmentTotal) > Working age ($workingAge)';
    }

    if (mounted && error != _validationError) {
      setState(() => _validationError = error);
    }
  }

  void _autoCalculateTotal() {
    final males = int.tryParse(widget.malesController.text) ?? 0;
    final females = int.tryParse(widget.femalesController.text) ?? 0;
    final total = males + females;
    if (total > 0) {
      widget.householdSizeController.text = total.toString();
    }
  }

  Future<void> _callPhone() async {
    final phone = widget.phoneController.text.trim();
    if (phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  InputDecoration _decoration(String label, {IconData? icon, String? helper}) {
    return InputDecoration(
      labelText: label,
      helperText: helper,
      prefixIcon: icon == null ? null : Icon(icon, size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 700;
        final padding = isTablet ? 24.0 : 16.0;

        return ListView(
          padding: EdgeInsets.all(padding),
          children: [
            _buildHeader(isTablet),
            SizedBox(height: isTablet ? 32 : 24),
            _buildHeadSection(isTablet),
            SizedBox(height: isTablet ? 28 : 20),
            _buildDemographicsSection(isTablet),
            SizedBox(height: isTablet ? 28 : 20),
            _buildHealthSection(isTablet),
            SizedBox(height: isTablet ? 28 : 20),
            _buildIncomeSection(isTablet), // New section
            SizedBox(height: isTablet ? 28 : 20),
            _buildContactSection(isTablet),
            if (_validationError != null) ...[
              const SizedBox(height: 16),
              _buildErrorBanner(),
            ],
          ],
        );
      },
    );
  }

  Widget _buildHeader(bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Household Information',
          style: TextStyle(
            fontSize: isTablet ? 32 : 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Capture household composition, income status and contact details for service delivery.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: isTablet ? 15 : 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildHeadSection(bool isTablet) {
    return _section(
      title: 'Household Head',
      icon: Icons.person_rounded,
      isTablet: isTablet,
      children: [
        TextFormField(
          controller: widget.householdHeadController,
          textCapitalization: TextCapitalization.words,
          decoration: _decoration('Full Name'),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: widget.householdSizeController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration:
              _decoration(
                'Total Household Size',
                icon: Icons.groups_rounded,
              ).copyWith(
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calculate_rounded, size: 20),
                  onPressed: _autoCalculateTotal,
                  tooltip: 'Auto-calculate from gender',
                ),
              ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Required';
            final n = int.tryParse(v);
            if (n == null || n == 0) return 'Must be > 0';
            if (n > 50) return 'Verify if > 50 people';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDemographicsSection(bool isTablet) {
    return _section(
      title: 'Gender Breakdown',
      icon: Icons.wc_rounded,
      isTablet: isTablet,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: widget.malesController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: _decoration('Males', icon: Icons.male_rounded),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: widget.femalesController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: _decoration('Females', icon: Icons.female_rounded),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Age Breakdown',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: isTablet ? 15 : 14,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: widget.childrenController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: _decoration(
                  'Children',
                  icon: Icons.child_care_rounded,
                ).copyWith(helperText: 'Under 18'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: widget.adultsController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: _decoration(
                  'Adults',
                  icon: Icons.work_rounded,
                ).copyWith(helperText: '18-64'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: widget.pensionersController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: _decoration(
            'Elderly / Pensioners',
            icon: Icons.elderly_rounded,
          ).copyWith(helperText: '65+ or receiving old age grant'),
        ),
      ],
    );
  }

  Widget _buildHealthSection(bool isTablet) {
    return _section(
      title: 'Health Status',
      icon: Icons.medical_services_rounded,
      isTablet: isTablet,
      children: [
        TextFormField(
          controller: widget.chronicController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration:
              _decoration(
                'Chronic Illness',
                icon: Icons.health_and_safety_rounded,
              ).copyWith(
                helperText:
                    'Members with diabetes, HIV, TB, hypertension, etc.',
              ),
        ),
      ],
    );
  }

  Widget _buildIncomeSection(bool isTablet) {
    return _section(
      title: 'Income & Employment Status',
      icon: Icons.payments_rounded,
      isTablet: isTablet,
      children: [
        ValueListenableBuilder<String?>(
          valueListenable: widget.incomeBracketNotifier,
          builder: (context, value, _) {
            return DropdownButtonFormField<String>(
              value: value,
              decoration: _decoration(
                'Monthly Household Income',
                icon: Icons.account_balance_wallet_rounded,
              ).copyWith(helperText: 'Used for indigent qualification'),
              items: _incomeBrackets
                  .map(
                    (bracket) =>
                        DropdownMenuItem(value: bracket, child: Text(bracket)),
                  )
                  .toList(),
              onChanged: (v) => widget.incomeBracketNotifier.value = v,
              validator: (v) =>
                  v == null ? 'Please select income bracket' : null,
            );
          },
        ),
        const SizedBox(height: 16),
        Text(
          'Employment Breakdown',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: isTablet ? 15 : 14,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: widget.employedController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: _decoration(
                  'Employed',
                  icon: Icons.work_history_rounded,
                ).copyWith(helperText: 'Full/part-time'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: widget.unemployedController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: _decoration(
                  'Unemployed',
                  icon: Icons.person_off_rounded,
                ).copyWith(helperText: 'Seeking work'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: widget.grantRecipientsController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: _decoration(
            'Grant Recipients',
            icon: Icons.volunteer_activism_rounded,
          ).copyWith(helperText: 'Child support, disability, old age, etc.'),
        ),
      ],
    );
  }

  Widget _buildContactSection(bool isTablet) {
    return _section(
      title: 'Contact Information',
      icon: Icons.contact_phone_rounded,
      isTablet: isTablet,
      children: [
        TextFormField(
          controller: widget.phoneController,
          keyboardType: TextInputType.phone,
          decoration: _decoration('Phone Number', icon: Icons.phone_rounded)
              .copyWith(
                suffixIcon: IconButton(
                  icon: const Icon(Icons.call_rounded, size: 20),
                  onPressed: _callPhone,
                  tooltip: 'Call',
                ),
              ),
          validator: (v) {
            if (v != null &&
                v.isNotEmpty &&
                v.replaceAll(RegExp(r'\D'), '').length < 10) {
              return 'Enter valid 10-digit number';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _section({
    required String title,
    required IconData icon,
    required bool isTablet,
    required List<Widget> children,
  }) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: isTablet ? 18 : 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_rounded, color: AppColors.error, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _validationError!,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
