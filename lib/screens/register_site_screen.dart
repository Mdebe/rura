import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../database/db_helper.dart';
import '../models/site.dart';
import '../theme/app_theme.dart';

import '../wizard_steps/site_type_step.dart';
import '../wizard_steps/gps_capture_step.dart';
import '../wizard_steps/photo_capture_step.dart';
import '../wizard_steps/site_info_step.dart';
import '../wizard_steps/household_info_step.dart';
import '../wizard_steps/services_step.dart';
import '../wizard_steps/review_step.dart';

/// Wizard shell for registering a new site. Owns all shared state
/// (controllers, GPS/photo results, current step) and delegates rendering
/// of each step to a dedicated widget in `wizard_steps/`.
class RegisterSiteScreen extends StatefulWidget {
  const RegisterSiteScreen({super.key});

  @override
  State<RegisterSiteScreen> createState() => _RegisterSiteScreenState();
}

class _RegisterSiteScreenState extends State<RegisterSiteScreen> {
  static const int _stepCount = 7;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _villageController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _householdHeadController = TextEditingController();
  final _householdSizeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _addressController = TextEditingController();
  
  // Demographic controllers for HouseholdInfoStep
  final _malesController = TextEditingController();
  final _femalesController = TextEditingController();
  final _pensionersController = TextEditingController();
  final _chronicController = TextEditingController();
  
  // Additional controllers used by SiteInfoStep
  final _siteCodeController = TextEditingController();
  final _provinceController = TextEditingController();
  final _districtController = TextEditingController();
  final _municipalityController = TextEditingController();
  final _wardController = TextEditingController();
  final _traditionalAuthorityController = TextEditingController();
  final _sectionController = TextEditingController();
  final _distanceController = TextEditingController();
  final _directionsController = TextEditingController();

  SiteType _selectedType = SiteType.house;
  int _currentStep = 0;
  bool _saving = false;
  bool _gpsLoading = false;
  bool _photoLoading = false;
  double? _latitude;
  double? _longitude;
  String? _photoPath;
  String _gpsStatus = 'Tap to capture your current location';
  final List<String> _services = [];

  @override
  void initState() {
    super.initState();
    _siteCodeController.text = 'RURA-${DateTime.now().millisecondsSinceEpoch}';
    // Default demographic counts to 0
    _malesController.text = '0';
    _femalesController.text = '0';
    _pensionersController.text = '0';
    _chronicController.text = '0';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _villageController.dispose();
    _landmarkController.dispose();
    _descriptionController.dispose();
    _householdHeadController.dispose();
    _householdSizeController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    _addressController.dispose();
    
    _malesController.dispose();
    _femalesController.dispose();
    _pensionersController.dispose();
    _chronicController.dispose();
    
    _siteCodeController.dispose();
    _provinceController.dispose();
    _districtController.dispose();
    _municipalityController.dispose();
    _wardController.dispose();
    _traditionalAuthorityController.dispose();
    _sectionController.dispose();
    _distanceController.dispose();
    _directionsController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------

  Future<void> _captureLocation() async {
    setState(() => _gpsLoading = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _gpsLoading = false;
          _gpsStatus = 'Location services are disabled.';
        });
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
        setState(() {
          _gpsLoading = false;
          _gpsStatus = 'Location permission was not granted.';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      final place = placemarks.isNotEmpty ? placemarks.first : null;
      final addressParts = [
        place?.street,
        place?.subLocality,
        place?.locality,
        place?.administrativeArea,
        place?.country,
      ].whereType<String>().where((value) => value.trim().isNotEmpty);
      final resolvedAddress = addressParts.join(', ');

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _addressController.text = resolvedAddress;
        _gpsStatus = 'GPS captured successfully.';
        _gpsLoading = false;
      });
    } catch (_) {
      setState(() {
        _gpsLoading = false;
        _gpsStatus = 'Unable to capture location right now.';
      });
    }
  }

  Future<void> _capturePhoto() async {
    setState(() => _photoLoading = true);

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
      if (picked == null) {
        setState(() => _photoLoading = false);
        return;
      }

      final appDir = await getApplicationDocumentsDirectory();
      final targetPath = p.join(appDir.path, '${DateTime.now().millisecondsSinceEpoch}${p.extension(picked.path)}');
      final savedFile = await File(picked.path).copy(targetPath);

      setState(() {
        _photoPath = savedFile.path;
        _photoLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _photoLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo capture failed.')));
    }
  }

  Future<void> _openOsmMap() async {
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Capture GPS first.')));
      return;
    }

    final url = Uri.parse('https://www.openstreetmap.org/?mlat=$_latitude&mlon=$_longitude&zoom=16');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open OpenStreetMap.')));
    }
  }

  void _toggleService(String service) {
    setState(() {
      if (_services.contains(service)) {
        _services.remove(service);
      } else {
        _services.add(service);
      }
    });
  }

  // ---------------------------------------------------------------------
  // Navigation / validation
  // ---------------------------------------------------------------------

  bool _validateStep() {
    switch (_currentStep) {
      case 0:
        return true;
      case 1:
        if (_latitude == null || _longitude == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('GPS location is required.')));
          return false;
        }
        return true;
      case 2:
        if (_photoPath == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Capture at least one site photo.')));
          return false;
        }
        return true;
      case 3:
        if (_nameController.text.trim().isEmpty || _villageController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Site name and village are required.')));
          return false;
        }
        return true;
      case 4:
        if (_householdHeadController.text.trim().isEmpty || _householdSizeController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Household head and size are required.')),
          );
          return false;
        }
        
        final size = int.tryParse(_householdSizeController.text.trim()) ?? 0;
        final males = int.tryParse(_malesController.text.trim()) ?? 0;
        final females = int.tryParse(_femalesController.text.trim()) ?? 0;
        final pensioners = int.tryParse(_pensionersController.text.trim()) ?? 0;
        final chronic = int.tryParse(_chronicController.text.trim()) ?? 0;
        
        if (males + females > size) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Males + Females cannot exceed total household size.')),
          );
          return false;
        }
        if (pensioners > size || chronic > size) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pensioners or chronic members cannot exceed household size.')),
          );
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _nextStep() {
    if (!_validateStep()) return;
    setState(() => _currentStep = (_currentStep + 1).clamp(0, _stepCount - 1));
  }

  void _previousStep() {
    setState(() => _currentStep = (_currentStep - 1).clamp(0, _stepCount - 1));
  }

  Future<void> _saveSite() async {
    if (!_validateStep()) return;
    setState(() => _saving = true);

    final householdSize = int.tryParse(_householdSizeController.text.trim());
    final males = int.tryParse(_malesController.text.trim());
    final females = int.tryParse(_femalesController.text.trim());
    final pensioners = int.tryParse(_pensionersController.text.trim());
    final chronic = int.tryParse(_chronicController.text.trim());
    final distanceFromLandmark = double.tryParse(_distanceController.text.trim());
    
    final site = Site(
      siteCode: _siteCodeController.text,
      name: _nameController.text.trim(),
      province: _provinceController.text.trim(),
      district: _districtController.text.trim(),
      municipality: _municipalityController.text.trim(),
      ward: _wardController.text.trim(),
      traditionalAuthority: _traditionalAuthorityController.text.trim(),
      village: _villageController.text.trim(),
      section: _sectionController.text.trim(),
      type: _selectedType,
      registeredAt: DateTime.now(),
      imagePath: _photoPath,
      latitude: _latitude,
      longitude: _longitude,
      address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
      landmark: _landmarkController.text.trim().isEmpty ? null : _landmarkController.text.trim(),
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      householdHead: _householdHeadController.text.trim().isEmpty ? null : _householdHeadController.text.trim(),
      householdSize: householdSize,
      males: males,
      females: females,
      pensioners: pensioners,
      chronicMembers: chronic,
      phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      services: _services.isEmpty ? null : _services.join(', '),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      distanceFromLandmark: distanceFromLandmark,
      directions: _directionsController.text.trim(),
    );

    await DBHelper.instance.insertSite(site);
    if (mounted) Navigator.pop(context, true);
  }

  // ---------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register New Site'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.maybePop(context)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: (_currentStep + 1) / _stepCount,
                  backgroundColor: AppColors.divider,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 10),
                Text('Step ${_currentStep + 1} of $_stepCount', style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Expanded(child: _buildStep()),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _previousStep,
                          child: const Text('Back'),
                        ),
                      ),
                    if (_currentStep > 0) const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _currentStep == _stepCount - 1 ? _saveSite : _nextStep,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(_currentStep == _stepCount - 1 ? 'Save Site' : 'Continue'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_currentStep) {
      case 0:
        return SiteTypeStep(
          selectedType: _selectedType,
          onTypeSelected: (type) => setState(() => _selectedType = type),
        );
      case 1:
        return GpsCaptureStep(
          latitude: _latitude,
          longitude: _longitude,
          addressController: _addressController,
          gpsStatus: _gpsStatus,
          gpsLoading: _gpsLoading,
          onCapture: _captureLocation,
          onOpenMap: _openOsmMap,
        );
      case 2:
        return PhotoCaptureStep(
          photoPath: _photoPath,
          photoLoading: _photoLoading,
          onCapturePhoto: _capturePhoto,
        );
      case 3:
        return SiteInfoStep(
          householdHeadController: _nameController,
          siteNameController: _nameController,
          siteCodeController: _siteCodeController,
          provinceController: _provinceController,
          districtController: _districtController,
          municipalityController: _municipalityController,
          wardController: _wardController,
          traditionalAuthorityController: _traditionalAuthorityController,
          villageController: _villageController,
          sectionController: _sectionController,
          landmarkController: _landmarkController,
          distanceController: _distanceController,
          addressController: _addressController,
          directionsController: _directionsController,
        );
      case 4:
        return HouseholdInfoStep(
          householdHeadController: _householdHeadController,
          householdSizeController: _householdSizeController,
          phoneController: _phoneController,
          malesController: _malesController,
          femalesController: _femalesController,
          pensionersController: _pensionersController,
          chronicController: _chronicController,
        );
      case 5:
        return ServicesStep(
          services: _services,
          notesController: _notesController,
          onToggleService: _toggleService,
        );
      default:
        return ReviewStep(
          selectedType: _selectedType,
          name: _nameController.text.trim(),
          village: _villageController.text.trim(),
          address: _addressController.text.trim(),
          householdHead: _householdHeadController.text.trim(),
          services: _services,
          photoPath: _photoPath,
        );
    }
  }
}