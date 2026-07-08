import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../database/db_helper.dart';
import '../models/site.dart';
import '../services/site_service.dart';
import '../theme/app_theme.dart';

import '../wizard_steps/site_type_step.dart';
import '../wizard_steps/gps_capture_step.dart';
import '../wizard_steps/photo_capture_step.dart';
import '../wizard_steps/site_info_step.dart';
import '../wizard_steps/household_info_step.dart';
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
  static const int _stepCount = 6; // Removed services step
  static const int _maxPhotos = 5;

  final _formKey = GlobalKey<FormState>();
  final _siteService = SiteService();

  // Site Info Controllers
  final _nameController = TextEditingController();
  final _siteCodeController = TextEditingController();
  final _provinceController = TextEditingController();
  final _districtController = TextEditingController();
  final _municipalityController = TextEditingController();
  final _wardController = TextEditingController();
  final _traditionalAuthorityController = TextEditingController();
  final _villageController = TextEditingController();
  final _sectionController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _distanceController = TextEditingController();
  final _addressController = TextEditingController();
  final _directionsController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Household Info Controllers
  final _householdHeadController = TextEditingController();
  final _householdSizeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _malesController = TextEditingController();
  final _femalesController = TextEditingController();
  final _childrenController = TextEditingController();
  final _adultsController = TextEditingController();
  final _pensionersController = TextEditingController();
  final _chronicController = TextEditingController();
  final _notesController = TextEditingController();

  final incomeBracketNotifier = ValueNotifier<String?>(null);
  final employedController = TextEditingController();
  final unemployedController = TextEditingController();
  final grantRecipientsController = TextEditingController();

  // State
  SiteType _selectedType = SiteType.house;
  int _currentStep = 0;
  bool _saving = false;

  // GPS State
  bool _gpsLoading = false;
  double? _latitude;
  double? _longitude;
  double? _accuracy;
  double? _altitude;
  double? _speed;
  double? _heading;
  DateTime? _capturedAt;
  String _gpsStatus = 'Tap to capture your current location';
  String? _gpsError;

  // Photo State
  bool _photoLoading = false;
  final List<String> _photoPaths = [];

  @override
  void initState() {
    super.initState();
    _provinceController.text = 'KwaZulu-Natal';
    _loadNextSiteId();
    // Default demographic counts to 0
    _malesController.text = '0';
    _femalesController.text = '0';
    _childrenController.text = '0';
    _adultsController.text = '0';
    _pensionersController.text = '0';
    _chronicController.text = '0';
  }

  Future<void> _loadNextSiteId() async {
    final stats = await DBHelper.instance.getFieldStats();
    final nextId = (stats['totalSites'] ?? 0) + 1;
    if (mounted) {
      setState(() {
        _siteCodeController.text = 'RURA-${nextId.toString().padLeft(4, '0')}';
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _siteCodeController.dispose();
    _provinceController.dispose();
    _districtController.dispose();
    _municipalityController.dispose();
    _wardController.dispose();
    _traditionalAuthorityController.dispose();
    _villageController.dispose();
    _sectionController.dispose();
    _landmarkController.dispose();
    _distanceController.dispose();
    _addressController.dispose();
    _directionsController.dispose();
    _descriptionController.dispose();
    _householdHeadController.dispose();
    _householdSizeController.dispose();
    _phoneController.dispose();
    _malesController.dispose();
    _femalesController.dispose();
    _childrenController.dispose();
    _adultsController.dispose();
    _pensionersController.dispose();
    _chronicController.dispose();
    _notesController.dispose();
    incomeBracketNotifier.dispose();
    employedController.dispose();
    unemployedController.dispose();
    grantRecipientsController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------

  Future<void> _captureLocation() async {
    setState(() {
      _gpsLoading = true;
      _gpsError = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _gpsLoading = false;
          _gpsStatus = 'Location services are disabled.';
          _gpsError = 'Please enable location services in settings.';
        });
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        setState(() {
          _gpsLoading = false;
          _gpsStatus = 'Location permission was not granted.';
          _gpsError = 'Enable location permission to capture GPS.';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
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
        _accuracy = position.accuracy;
        _altitude = position.altitude;
        _speed = position.speed * 3.6; // m/s to km/h
        _heading = position.heading;
        _capturedAt = DateTime.now();
        _addressController.text = resolvedAddress;
        _gpsStatus = 'GPS captured successfully';
        _gpsLoading = false;
        _gpsError = null;
      });
    } catch (e) {
      setState(() {
        _gpsLoading = false;
        _gpsStatus = 'Unable to capture location';
        _gpsError = 'Error: ${e.toString()}';
      });
    }
  }

  Future<void> _capturePhoto() async {
    if (_photoPaths.length >= _maxPhotos) return;
    setState(() => _photoLoading = true);

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (picked == null) {
        setState(() => _photoLoading = false);
        return;
      }

      final appDir = await getApplicationDocumentsDirectory();
      final targetPath = p.join(
        appDir.path,
        'site_${DateTime.now().millisecondsSinceEpoch}${p.extension(picked.path)}',
      );
      final savedFile = await File(picked.path).copy(targetPath);

      setState(() {
        _photoPaths.add(savedFile.path);
        _photoLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _photoLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Photo capture failed: $e')));
    }
  }

  Future<void> _pickFromGallery() async {
    if (_photoPaths.length >= _maxPhotos) return;
    setState(() => _photoLoading = true);

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (picked == null) {
        setState(() => _photoLoading = false);
        return;
      }

      final appDir = await getApplicationDocumentsDirectory();
      final targetPath = p.join(
        appDir.path,
        'site_${DateTime.now().millisecondsSinceEpoch}${p.extension(picked.path)}',
      );
      final savedFile = await File(picked.path).copy(targetPath);

      setState(() {
        _photoPaths.add(savedFile.path);
        _photoLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _photoLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gallery pick failed: $e')));
    }
  }

  void _deletePhoto(int index) {
    setState(() {
      _photoPaths.removeAt(index);
    });
  }

  Future<void> _openOsmMap() async {
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Capture GPS first.')));
      return;
    }

    final url = Uri.parse(
      'https://www.openstreetmap.org/?mlat=$_latitude&mlon=$_longitude&zoom=16',
    );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open OpenStreetMap.')),
      );
    }
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('GPS location is required.')),
          );
          return false;
        }
        if (_accuracy != null && _accuracy! > 20) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('GPS accuracy is too low. Move to open area.'),
            ),
          );
          return false;
        }
        return true;
      case 2:
        if (_photoPaths.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Capture at least one site photo.')),
          );
          return false;
        }
        return true;
      case 3:
        if (_nameController.text.trim().isEmpty ||
            _villageController.text.trim().isEmpty ||
            _wardController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Site name, village, and ward are required.'),
            ),
          );
          return false;
        }
        return true;
      case 4:
        if (_householdHeadController.text.trim().isEmpty ||
            _householdSizeController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Household head and size are required.'),
            ),
          );
          return false;
        }

        final size = int.tryParse(_householdSizeController.text.trim()) ?? 0;
        final males = int.tryParse(_malesController.text.trim()) ?? 0;
        final females = int.tryParse(_femalesController.text.trim()) ?? 0;
        final children = int.tryParse(_childrenController.text.trim()) ?? 0;
        final adults = int.tryParse(_adultsController.text.trim()) ?? 0;
        final pensioners = int.tryParse(_pensionersController.text.trim()) ?? 0;
        final chronic = int.tryParse(_chronicController.text.trim()) ?? 0;

        if (males + females > size) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Males + Females ($males + $females) cannot exceed total ($size).',
              ),
            ),
          );
          return false;
        }
        if (children + adults + pensioners > size) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Age groups ($children + $adults + $pensioners) cannot exceed total ($size).',
              ),
            ),
          );
          return false;
        }
        if (chronic > size) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Chronic members cannot exceed household size.'),
            ),
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
    final children = int.tryParse(_childrenController.text.trim());
    final adults = int.tryParse(_adultsController.text.trim());
    final pensioners = int.tryParse(_pensionersController.text.trim());
    final chronic = int.tryParse(_chronicController.text.trim());
    final distanceFromLandmark = double.tryParse(
      _distanceController.text.trim(),
    );

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
      imagePath: _photoPaths.isNotEmpty ? _photoPaths.first : null,
      imagePaths: _photoPaths.isNotEmpty ? _photoPaths : null,
      latitude: _latitude,
      longitude: _longitude,
      accuracy: _accuracy,
      altitude: _altitude,
      capturedAt: _capturedAt,
      address: _addressController.text.trim().isNotEmpty
          ? _addressController.text.trim()
          : null,
      landmark: _landmarkController.text.trim().isEmpty
          ? null
          : _landmarkController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      householdHead: _householdHeadController.text.trim().isEmpty
          ? null
          : _householdHeadController.text.trim(),
      householdSize: householdSize,
      males: males,
      females: females,
      children: children,
      adults: adults,
      pensioners: pensioners,
      chronicMembers: chronic,
      phoneNumber: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      services: null, // No services step
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      distanceFromLandmark: distanceFromLandmark,
      directions: _directionsController.text.trim(),
      incomeBracket: incomeBracketNotifier.value,
      employedCount: int.tryParse(employedController.text),
      unemployedCount: int.tryParse(unemployedController.text),
      grantRecipients: int.tryParse(grantRecipientsController.text),
    );

    try {
      final savedSite = await _siteService.saveSite(site);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              savedSite.isSynced
                  ? 'Site ${site.siteCode} saved to cloud'
                  : 'Site ${site.siteCode} saved locally. Will sync when online',
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ---------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register New Site'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
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
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
                const SizedBox(height: 12),
                Text(
                  'Step ${_currentStep + 1} of $_stepCount',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                Expanded(child: _buildStep()),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _previousStep,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Back'),
                        ),
                      ),
                    if (_currentStep > 0) const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _currentStep == _stepCount - 1
                            ? _saveSite
                            : _nextStep,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _currentStep == _stepCount - 1
                                    ? 'Save Site'
                                    : 'Continue',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
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
          accuracy: _accuracy,
          altitude: _altitude,
          speed: _speed,
          heading: _heading,
          capturedAt: _capturedAt,
          addressController: _addressController,
          gpsStatus: _gpsStatus,
          gpsLoading: _gpsLoading,
          errorMessage: _gpsError,
          onCapture: _captureLocation,
          onOpenMap: _openOsmMap,
          onClear: () => setState(() {
            _latitude = null;
            _longitude = null;
            _accuracy = null;
            _altitude = null;
            _speed = null;
            _heading = null;
            _capturedAt = null;
            _gpsStatus = 'Tap to capture your current location';
            _gpsError = null;
          }),
        );
      case 2:
        return PhotoCaptureStep(
          photoPaths: _photoPaths,
          photoLoading: _photoLoading,
          onCapturePhoto: _capturePhoto,
          onPickFromGallery: _pickFromGallery,
          onDeletePhoto: _deletePhoto,
          maxPhotos: _maxPhotos,
        );
      case 3:
        return SiteInfoStep(
          householdHeadController: _householdHeadController,
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
          childrenController: _childrenController,
          adultsController: _adultsController,
          pensionersController: _pensionersController,
          chronicController: _chronicController,
          incomeBracketNotifier: incomeBracketNotifier,
          employedController: employedController,
          unemployedController: unemployedController,
          grantRecipientsController: grantRecipientsController,
        );
      default:
        return ReviewStep(
          selectedType: _selectedType,
          name: _nameController.text.trim(),
          village: _villageController.text.trim(),
          ward: _wardController.text.trim(),
          address: _addressController.text.trim(),
          householdHead: _householdHeadController.text.trim(),
          householdSize: int.tryParse(_householdSizeController.text.trim()),
          phoneNumber: _phoneController.text.trim(),
          males: int.tryParse(_malesController.text.trim()),
          females: int.tryParse(_femalesController.text.trim()),
          children: int.tryParse(_childrenController.text.trim()),
          adults: int.tryParse(_adultsController.text.trim()),
          pensioners: int.tryParse(_pensionersController.text.trim()),
          chronicMembers: int.tryParse(_chronicController.text.trim()),
          incomeBracket: incomeBracketNotifier.value,
          employedCount: int.tryParse(employedController.text),
          unemployedCount: int.tryParse(unemployedController.text),
          grantRecipients: int.tryParse(grantRecipientsController.text),
          roadAccess: null, // Not implemented in this wizard
          landmarkAccesses: const [], // Not implemented in this wizard
          services: const [], // No services step
          notes: _notesController.text.trim(),
          photoPaths: _photoPaths,
          siteCode: _siteCodeController.text,
          latitude: _latitude,
          longitude: _longitude,
          accuracy: _accuracy,
        );
    }
  }
}
