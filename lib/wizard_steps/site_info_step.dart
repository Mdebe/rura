import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../database/db_helper.dart';

/// Step 4 — Collects basic site identity and administrative location.
class SiteInfoStep extends StatefulWidget {
  final TextEditingController siteNameController;
  final TextEditingController siteCodeController;
  final TextEditingController householdHeadController; // Need this for surname

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
      'uThungulu',
      'Zululand',
    ],
  };

  static const Map<String, List<String>> municipalitiesByDistrict = {
    'Amajuba': ['Newcastle', 'Dannhauser', 'eMadlangeni'],
    'eThekwini Metro': ['eThekwini'],
    'Harry Gwala': ['Dr Nkosazana Dlamini Zuma', 'Greater Kokstad', 'Ubuhlebezwe', 'uMzimkhulu'],
    'iLembe': ['KwaDukuza', 'Mandeni', 'Maphumulo', 'Ndwedwe'],
    'King Cetshwayo': ['City of uMhlathuze', 'Mthonjaneni', 'Nkandla', 'uMfolozi', 'uMlalazi'],
    'Ugu': ['Hibiscus Coast', 'Umuziwabantu', 'uMdoni', 'uMuziwabantu', 'Ray Nkonyeni'],
    'uMgungundlovu': ['Msunduzi', 'uMngeni', 'Mpofana', 'Mkhambathini', 'Richmond', 'Impendle', 'uMshwathi'],
    'uMkhanyakude': ['Jozini', 'Big Five Hlabisa', 'Mtubatuba', 'The Big Five False Bay', 'uMhlabuyalingana'],
    'uMzinyathi': ['Endumeni', 'Nquthu', 'Msinga', 'uMvoti'],
    'uThukela': ['Alfred Duma', 'Inkosi Langalibalele', 'Okhahlamba'],
    'uThungulu': ['Mandeni', 'Mthonjaneni', 'Nkandla', 'uMlalazi', 'City of uMhlathuze'],
    'Zululand': ['AbaQulusi', 'eDumbe', 'Nongoma', 'Phongolo', 'Ulundi', 'uPhongolo'],
  };

  static const Map<String, List<String>> wardsByMunicipality = {
    'eThekwini': ['Ward 1', 'Ward 2', 'Ward 3', 'Ward 4', 'Ward 5', 'Ward 6', 'Ward 7', 'Ward 8', 'Ward 9', 'Ward 10'],
    'Msunduzi': ['Ward 1', 'Ward 2', 'Ward 3', 'Ward 4', 'Ward 5', 'Ward 6', 'Ward 7'],
    'uMngeni': ['Ward 1', 'Ward 2', 'Ward 3', 'Ward 4'],
    'Newcastle': ['Ward 1', 'Ward 2', 'Ward 3', 'Ward 4', 'Ward 5'],
    'KwaDukuza': ['Ward 1', 'Ward 2', 'Ward 3', 'Ward 4', 'Ward 5'],
    'Ray Nkonyeni': ['Ward 1', 'Ward 2', 'Ward 3', 'Ward 4'],
    'City of uMhlathuze': ['Ward 1', 'Ward 2', 'Ward 3', 'Ward 4', 'Ward 5', 'Ward 6'],
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
    _selectedProvince = widget.provinceController.text.isNotEmpty ? widget.provinceController.text : null;
    _selectedDistrict = widget.districtController.text.isNotEmpty ? widget.districtController.text : null;
    _selectedMunicipality = widget.municipalityController.text.isNotEmpty ? widget.municipalityController.text : null;
    _selectedWard = widget.wardController.text.isNotEmpty ? widget.wardController.text : null;

    // Listen to changes to auto-generate code
    widget.villageController.addListener(_generateSiteCode);
    widget.wardController.addListener(_generateSiteCode);
    widget.householdHeadController.addListener(_generateSiteCode);

    _loadNextAutoId();
  }

  @override
  void dispose() {
    widget.villageController.removeListener(_generateSiteCode);
    widget.wardController.removeListener(_generateSiteCode);
    widget.householdHeadController.removeListener(_generateSiteCode);
    super.dispose();
  }

  Future<void> _loadNextAutoId() async {
    final stats = await DBHelper.instance.getFieldStats();
    setState(() {
      _nextAutoId = (stats['totalSites'] ?? 0) + 1;
    });
  }

  void _generateSiteCode() async {
    if (_generatingCode) return;
    final village = widget.villageController.text.trim();
    final ward = widget.wardController.text.trim();
    final head = widget.householdHeadController.text.trim();

    if (village.isEmpty || ward.isEmpty || head.isEmpty) {
      widget.siteCodeController.text = '';
      setState(() {});
      return;
    }

    setState(() => _generatingCode = true);

    // Extract surname: last word in household head
    final surname = head.split(' ').last;

    // Sanitize: remove spaces, special chars, uppercase
    String clean(String s) => s.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();

    final code = '${clean(village)}-${clean(surname)}-${clean(ward)}-${_nextAutoId.toString().padLeft(4, '0')}';

    widget.siteCodeController.text = code;
    setState(() => _generatingCode = false);
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

  @override
  Widget build(BuildContext context) {
    InputDecoration decoration(String label, {IconData? icon}) {
      return InputDecoration(
        labelText: label,
        prefixIcon: icon == null ? null : Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Site Information', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Record the site identity and administrative location.'),
        const SizedBox(height: 24),

        TextFormField(
          controller: widget.siteNameController,
          decoration: decoration('Site / Household Name', icon: Icons.home_work_outlined),
          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: widget.householdHeadController,
          decoration: decoration('Household Head Full Name', icon: Icons.person_outline),
          validator: (v) => v == null || v.trim().isEmpty ? 'Required for ID generation' : null,
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: widget.siteCodeController,
          readOnly: true,
          decoration: decoration('Digital ID / Site Code', icon: Icons.qr_code).copyWith(
            suffixIcon: _generatingCode
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _generateSiteCode,
                    tooltip: 'Regenerate ID',
                  ),
          ),
        ),

        if (widget.siteCodeController.text.isNotEmpty) ...[
          const SizedBox(height: 16),
          Center(
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: QrImageView(
                  data: widget.siteCodeController.text,
                  version: QrVersions.auto,
                  size: 160,
                  backgroundColor: Colors.white,
                  embeddedImage: const AssetImage('assets/logo.png'), // optional
                  embeddedImageStyle: const QrEmbeddedImageStyle(size: Size(40, 40)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: SelectableText(
              widget.siteCodeController.text,
              style: TextStyle(
                color: Colors.green.shade800,
                fontWeight: FontWeight.w700,
                fontSize: 14,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        const Text('Administrative Area', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 16),

        DropdownButtonFormField<String>(
          initialValue: _selectedProvince,
          decoration: decoration('Province', icon: Icons.map_outlined),
          items: provinces.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
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
          validator: (value) => value == null || value.isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 12),

        DropdownButtonFormField<String>(
          initialValue: _selectedDistrict,
          decoration: decoration('District', icon: Icons.location_city_outlined),
          items: _districtOptions.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
          onChanged: (value) {
            setState(() {
              _selectedDistrict = value;
              _selectedMunicipality = null;
              _selectedWard = null;
              widget.districtController.text = value ?? '';
              widget.municipalityController.clear();
              widget.wardController.clear();
            });
          },
          validator: (value) => value == null || value.isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 12),

        DropdownButtonFormField<String>(
          initialValue: _selectedMunicipality,
          decoration: decoration('Municipality', icon: Icons.account_balance_outlined),
          items: _municipalityOptions.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
          onChanged: (value) {
            setState(() {
              _selectedMunicipality = value;
              _selectedWard = null;
              widget.municipalityController.text = value ?? '';
              widget.wardController.clear();
            });
          },
          validator: (value) => value == null || value.isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 12),

        DropdownButtonFormField<String>(
          initialValue: _selectedWard,
          decoration: decoration('Ward', icon: Icons.pin_drop_outlined),
          items: _wardOptions.map((w) => DropdownMenuItem(value: w, child: Text(w))).toList(),
          onChanged: (value) {
            setState(() {
              _selectedWard = value;
              widget.wardController.text = value ?? '';
            });
          },
          validator: (value) => value == null || value.isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 12),

        TextFormField(
          controller: widget.traditionalAuthorityController,
          decoration: decoration('Traditional Authority', icon: Icons.groups_outlined),
        ),
        const SizedBox(height: 12),

        TextFormField(
          controller: widget.villageController,
          decoration: decoration('Village', icon: Icons.location_on_outlined),
          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 12),

        TextFormField(
          controller: widget.sectionController,
          decoration: decoration('Section / Area', icon: Icons.grid_view_outlined),
        ),
        const SizedBox(height: 24),

        const Text('Location Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 16),

        TextFormField(
          controller: widget.landmarkController,
          decoration: decoration('Nearest Landmark', icon: Icons.place_outlined),
        ),
        const SizedBox(height: 12),

        TextFormField(
          controller: widget.addressController,
          maxLines: 2,
          decoration: decoration('Physical Address', icon: Icons.home_outlined),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}