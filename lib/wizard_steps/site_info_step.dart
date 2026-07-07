import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../database/db_helper.dart';
import '../../theme/app_theme.dart';

/// Step 4 — Collects basic site identity and administrative location.
class SiteInfoStep extends StatefulWidget {
  final TextEditingController siteNameController;
  final TextEditingController siteCodeController;
  final TextEditingController householdHeadController;
  final TextEditingController provinceController;
  final TextEditingController districtController;
  final TextEditingController municipalityController;
  final TextEditingController wardController;
  final TextEditingController traditionalAuthorityController;
  final TextEditingController villageController;
  final TextEditingController sectionController;
  final TextEditingController landmarkController;
  final TextEditingController distanceController;
  final TextEditingController addressController;
  final TextEditingController directionsController;

  const SiteInfoStep({
    super.key,
    required this.siteNameController,
    required this.siteCodeController,
    required this.householdHeadController,
    required this.provinceController,
    required this.districtController,
    required this.municipalityController,
    required this.wardController,
    required this.traditionalAuthorityController,
    required this.villageController,
    required this.sectionController,
    required this.landmarkController,
    required this.distanceController,
    required this.addressController,
    required this.directionsController,
  });

  @override
  State<SiteInfoStep> createState() => _SiteInfoStepState();
}

class _SiteInfoStepState extends State<SiteInfoStep> {
  static const List<String> provinces = ['KwaZulu-Natal'];

  static const Map<String, List<String>> districtsByProvince = {
    'KwaZulu-Natal': [
      'Amajuba',
      'eThekwini Metro',
      'Harry Gwala',
      'iLembe',
      'King Cetshwayo',
      'Ugu',
      'uMgungundlovu',
      'uMkhanyakude',
      'uMzinyathi',
      'uThukela',
      'Zululand',
    ],
  };

  static const Map<String, List<String>> municipalitiesByDistrict = {
    'Amajuba': ['Newcastle', 'Dannhauser', 'eMadlangeni'],
    'eThekwini Metro': ['eThekwini'],
    'Harry Gwala': [
      'Dr Nkosazana Dlamini Zuma',
      'Greater Kokstad',
      'Ubuhlebezwe',
      'uMzimkhulu',
    ],
    'iLembe': ['KwaDukuza', 'Mandeni', 'Maphumulo', 'Ndwedwe'],
    'King Cetshwayo': [
      'City of uMhlathuze',
      'Mthonjaneni',
      'Nkandla',
      'uMfolozi',
      'uMlalazi',
    ],
    'Ugu': ['Ray Nkonyeni', 'Umuziwabantu', 'uMdoni', 'Umzumbe'],
    'uMgungundlovu': [
      'Msunduzi',
      'uMngeni',
      'Mpofana',
      'Mkhambathini',
      'Richmond',
      'Impendle',
      'uMshwathi',
    ],
    'uMkhanyakude': [
      'Jozini',
      'Big Five Hlabisa',
      'Mtubatuba',
      'uMhlabuyalingana',
    ],
    'uMzinyathi': ['Endumeni', 'Nquthu', 'Msinga', 'uMvoti'],
    'uThukela': ['Alfred Duma', 'Inkosi Langalibalele', 'Okhahlamba'],
    'Zululand': ['AbaQulusi', 'eDumbe', 'Nongoma', 'uPhongolo', 'Ulundi'],
  };

  static final Map<String, List<String>> wardsByMunicipality = {
    'eThekwini': List.generate(110, (i) => 'Ward ${i + 1}'),
    'Msunduzi': List.generate(39, (i) => 'Ward ${i + 1}'),
    'uMngeni': List.generate(13, (i) => 'Ward ${i + 1}'),
    'Newcastle': List.generate(34, (i) => 'Ward ${i + 1}'),
    'KwaDukuza': List.generate(29, (i) => 'Ward ${i + 1}'),
    'Ray Nkonyeni': List.generate(36, (i) => 'Ward ${i + 1}'),
    'City of uMhlathuze': List.generate(34, (i) => 'Ward ${i + 1}'),
  };

  String? _selectedProvince;
  String? _selectedDistrict;
  String? _selectedMunicipality;
  String? _selectedWard;
  int _nextAutoId = 1;
  bool _generatingCode = false;

  @override
  void initState() {
    super.initState();
    _selectedProvince = widget.provinceController.text.isNotEmpty
        ? widget.provinceController.text
        : 'KwaZulu-Natal';
    _selectedDistrict = widget.districtController.text.isNotEmpty
        ? widget.districtController.text
        : null;
    _selectedMunicipality = widget.municipalityController.text.isNotEmpty
        ? widget.municipalityController.text
        : null;
    _selectedWard = widget.wardController.text.isNotEmpty
        ? widget.wardController.text
        : null;

    widget.villageController.addListener(_generateSiteCode);
    widget.wardController.addListener(_generateSiteCode);
    widget.householdHeadController.addListener(_generateSiteCode);
    widget.siteNameController.addListener(_generateSiteCode);

    _loadNextAutoId();
    _generateSiteCode();
  }

  @override
  void dispose() {
    widget.villageController.removeListener(_generateSiteCode);
    widget.wardController.removeListener(_generateSiteCode);
    widget.householdHeadController.removeListener(_generateSiteCode);
    widget.siteNameController.removeListener(_generateSiteCode);
    super.dispose();
  }

  Future<void> _loadNextAutoId() async {
    final stats = await DBHelper.instance.getFieldStats();
    if (mounted) {
      setState(() {
        _nextAutoId = (stats['totalSites'] ?? 0) + 1;
      });
    }
  }

  /// Format: VIL-SUR-0001
  /// VIL = 3 letters from village, SUR = 3 letters from surname, 0001 = sequential
  void _generateSiteCode() async {
    if (_generatingCode) return;

    final village = widget.villageController.text.trim();
    final head = widget.householdHeadController.text.trim();
    widget.wardController.text.trim();

    if (village.isEmpty || head.isEmpty) {
      widget.siteCodeController.text = '';
      if (mounted) setState(() {});
      return;
    }

    setState(() => _generatingCode = true);

    // Extract surname: last word, remove special chars, take first 3 letters
    final surname = head
        .split(' ')
        .last
        .replaceAll(RegExp(r'[^A-Za-z]'), '')
        .toUpperCase();
    final surnameCode = surname.length >= 3
        ? surname.substring(0, 3)
        : surname.padRight(3, 'X');

    // Village code: first 3 letters
    final villageCode = village
        .replaceAll(RegExp(r'[^A-Za-z]'), '')
        .toUpperCase();
    final vilCode = villageCode.length >= 3
        ? villageCode.substring(0, 3)
        : villageCode.padRight(3, 'X');

    // Format: VIL-SUR-0001
    final code =
        '$vilCode-$surnameCode-${_nextAutoId.toString().padLeft(4, '0')}';

    widget.siteCodeController.text = code;
    if (mounted) setState(() => _generatingCode = false);
  }

  List<String> get _districtOptions {
    if (_selectedProvince == null) return const [];
    return districtsByProvince[_selectedProvince!] ?? const [];
  }

  List<String> get _municipalityOptions {
    if (_selectedDistrict == null) return const [];
    return municipalitiesByDistrict[_selectedDistrict!] ?? const [];
  }

  List<String> get _wardOptions {
    if (_selectedMunicipality == null) return const [];
    return wardsByMunicipality[_selectedMunicipality!] ?? const [];
  }

  void _copyCode() {
    if (widget.siteCodeController.text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: widget.siteCodeController.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Digital ID copied'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareCode() {
    if (widget.siteCodeController.text.isEmpty) return;
    Share.share(
      'Site Digital ID: ${widget.siteCodeController.text}\n'
      'Location: ${widget.villageController.text}, ${widget.wardController.text}',
      subject: 'Site Registration',
    );
  }

  InputDecoration _decoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
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
            _buildIdentitySection(isTablet),
            SizedBox(height: isTablet ? 32 : 24),
            _buildAdminSection(isTablet),
            SizedBox(height: isTablet ? 32 : 24),
            _buildLocationSection(isTablet),
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
          'Site Information',
          style: TextStyle(
            fontSize: isTablet ? 32 : 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Record site identity and administrative location for accurate mapping.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: isTablet ? 15 : 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildIdentitySection(bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Site Identity', isTablet),
        const SizedBox(height: 16),
        TextFormField(
          controller: widget.siteNameController,
          decoration: _decoration(
            'Site / Household Name',
            icon: Icons.home_work_rounded,
          ),
          textCapitalization: TextCapitalization.words,
          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: widget.householdHeadController,
          decoration: _decoration(
            'Household Head Full Name',
            icon: Icons.person_rounded,
          ),
          textCapitalization: TextCapitalization.words,
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Required for ID' : null,
        ),
        const SizedBox(height: 14),
        _buildDigitalIdCard(isTablet),
      ],
    );
  }

  Widget _buildDigitalIdCard(bool isTablet) {
    final hasCode = widget.siteCodeController.text.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.primary.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.qr_code_rounded, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Digital Site ID',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: isTablet ? 16 : 15,
                      ),
                    ),
                    Text(
                      'Auto-generated from details',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (_generatingCode)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  onPressed: hasCode ? _generateSiteCode : null,
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Regenerate',
                ),
            ],
          ),
          if (hasCode) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: QrImageView(
                    data: widget.siteCodeController.text,
                    version: QrVersions.auto,
                    size: isTablet ? 140 : 120,
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.all(8),
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: AppColors.primary,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        widget.siteCodeController.text,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: isTablet ? 18 : 16,
                          letterSpacing: 1.5,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _iconButton(
                            icon: Icons.copy_rounded,
                            label: 'Copy',
                            onTap: _copyCode,
                          ),
                          const SizedBox(width: 8),
                          _iconButton(
                            icon: Icons.share_rounded,
                            label: 'Share',
                            onTap: _shareCode,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Complete Village & Household Head to generate ID',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }

  Widget _iconButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 8),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }

  Widget _buildAdminSection(bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Administrative Area', isTablet),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _selectedProvince,
          decoration: _decoration('Province', icon: Icons.map_rounded),
          items: provinces
              .map((p) => DropdownMenuItem(value: p, child: Text(p)))
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedProvince = value;
              _selectedDistrict = null;
              _selectedMunicipality = null;
              _selectedWard = null;
              widget.provinceController.text = value ?? '';
              widget.districtController.clear();
              widget.municipalityController.clear();
              widget.wardController.clear();
            });
          },
          validator: (value) => value == null ? 'Required' : null,
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          initialValue: _selectedDistrict,
          decoration: _decoration(
            'District',
            icon: Icons.location_city_rounded,
          ),
          items: _districtOptions
              .map((d) => DropdownMenuItem(value: d, child: Text(d)))
              .toList(),
          onChanged: _selectedProvince == null
              ? null
              : (value) {
                  setState(() {
                    _selectedDistrict = value;
                    _selectedMunicipality = null;
                    _selectedWard = null;
                    widget.districtController.text = value ?? '';
                    widget.municipalityController.clear();
                    widget.wardController.clear();
                  });
                },
          validator: (value) => value == null ? 'Required' : null,
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          initialValue: _selectedMunicipality,
          decoration: _decoration(
            'Municipality',
            icon: Icons.account_balance_rounded,
          ),
          items: _municipalityOptions
              .map((m) => DropdownMenuItem(value: m, child: Text(m)))
              .toList(),
          onChanged: _selectedDistrict == null
              ? null
              : (value) {
                  setState(() {
                    _selectedMunicipality = value;
                    _selectedWard = null;
                    widget.municipalityController.text = value ?? '';
                    widget.wardController.clear();
                  });
                },
          validator: (value) => value == null ? 'Required' : null,
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          initialValue: _selectedWard,
          decoration: _decoration('Ward', icon: Icons.pin_drop_rounded),
          items: _wardOptions
              .map((w) => DropdownMenuItem(value: w, child: Text(w)))
              .toList(),
          onChanged: _selectedMunicipality == null
              ? null
              : (value) {
                  setState(() {
                    _selectedWard = value;
                    widget.wardController.text = value ?? '';
                  });
                },
          validator: (value) => value == null ? 'Required' : null,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: widget.traditionalAuthorityController,
          decoration: _decoration(
            'Traditional Authority',
            icon: Icons.groups_rounded,
          ),
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: widget.villageController,
          decoration: _decoration('Village', icon: Icons.location_on_rounded),
          textCapitalization: TextCapitalization.words,
          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: widget.sectionController,
          decoration: _decoration(
            'Section / Area',
            icon: Icons.grid_view_rounded,
          ),
          textCapitalization: TextCapitalization.words,
        ),
      ],
    );
  }

  Widget _buildLocationSection(bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Location Details', isTablet),
        const SizedBox(height: 16),
        TextFormField(
          controller: widget.landmarkController,
          decoration: _decoration(
            'Nearest Landmark',
            icon: Icons.place_rounded,
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: widget.addressController,
          maxLines: 2,
          decoration: _decoration('Physical Address', icon: Icons.home_rounded),
          textCapitalization: TextCapitalization.sentences,
        ),
      ],
    );
  }

  Widget _sectionTitle(String title, bool isTablet) {
    return Text(
      title,
      style: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: isTablet ? 20 : 18,
      ),
    );
  }
}
