import 'package:cloud_firestore/cloud_firestore.dart';

/// The category of a registered site. Mirrors the "By Site Type" section
/// of the dashboard (House / Business / Church / School).
enum SiteType { house, business, church, school }

extension SiteTypeX on SiteType {
  String get label {
    switch (this) {
      case SiteType.house:
        return 'House';
      case SiteType.business:
        return 'Business';
      case SiteType.church:
        return 'Church';
      case SiteType.school:
        return 'School';
    }
  }

  static SiteType fromString(String value) {
    return SiteType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SiteType.house,
    );
  }
}

/// A single registered census record. This is the row shape stored in
/// the local SQLite `sites` table.
class Site {
  final int? id;
  final String? firestoreId; // NEW: Firebase doc ID
  final bool isSynced; // NEW: Sync status flag
  final String name;
  final String village;
  final SiteType type;
  final DateTime registeredAt;
  final String? imagePath;
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? landmark;
  final String? description;
  final String? householdHead;
  final int? householdSize;
  // New demographic fields
  final int? males;
  final int? females;
  final int? pensioners;
  final int? chronicMembers;
  final String? phoneNumber;
  final String? services;
  final String? notes;
  final String siteCode;
  final String province;
  final String district;
  final String municipality;
  final String ward;
  final String traditionalAuthority;
  final String section;
  final String directions;
  final double? distanceFromLandmark;

  const Site({
    this.id,
    this.firestoreId,
    this.isSynced = false,
    required this.siteCode,
    required this.name,
    required this.province,
    required this.district,
    required this.municipality,
    required this.ward,
    required this.traditionalAuthority,
    required this.village,
    required this.section,
    required this.type,
    required this.registeredAt,
    this.imagePath,
    this.latitude,
    this.longitude,
    this.address,
    this.landmark,
    this.distanceFromLandmark,
    required this.directions,
    this.description,
    this.householdHead,
    this.householdSize,
    this.males,
    this.females,
    this.pensioners,
    this.chronicMembers,
    this.phoneNumber,
    this.services,
    this.notes,
  });

  Site copyWith({
    int? id,
    String? firestoreId,
    bool? isSynced,
    String? name,
    String? village,
    SiteType? type,
    DateTime? registeredAt,
    String? imagePath,
    double? latitude,
    double? longitude,
    String? address,
    String? landmark,
    String? description,
    String? householdHead,
    int? householdSize,
    int? males,
    int? females,
    int? pensioners,
    int? chronicMembers,
    String? phoneNumber,
    String? services,
    String? notes,
    String? siteCode,
    String? province,
    String? district,
    String? municipality,
    String? ward,
    String? traditionalAuthority,
    String? section,
    String? directions,
    double? distanceFromLandmark,
  }) {
    return Site(
      id: id?? this.id,
      firestoreId: firestoreId?? this.firestoreId,
      isSynced: isSynced?? this.isSynced,
      siteCode: siteCode?? this.siteCode,
      name: name?? this.name,
      province: province?? this.province,
      district: district?? this.district,
      municipality: municipality?? this.municipality,
      ward: ward?? this.ward,
      traditionalAuthority: traditionalAuthority?? this.traditionalAuthority,
      village: village?? this.village,
      section: section?? this.section,
      type: type?? this.type,
      registeredAt: registeredAt?? this.registeredAt,
      imagePath: imagePath?? this.imagePath,
      latitude: latitude?? this.latitude,
      longitude: longitude?? this.longitude,
      address: address?? this.address,
      landmark: landmark?? this.landmark,
      distanceFromLandmark: distanceFromLandmark?? this.distanceFromLandmark,
      directions: directions?? this.directions,
      description: description?? this.description,
      householdHead: householdHead?? this.householdHead,
      householdSize: householdSize?? this.householdSize,
      males: males?? this.males,
      females: females?? this.females,
      pensioners: pensioners?? this.pensioners,
      chronicMembers: chronicMembers?? this.chronicMembers,
      phoneNumber: phoneNumber?? this.phoneNumber,
      services: services?? this.services,
      notes: notes?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firestore_id': firestoreId,
      'isSynced': isSynced? 1 : 0,
      'name': name,
      'village': village,
      'type': type.name,
      'registered_at': registeredAt.toIso8601String(),
      'image_path': imagePath,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'landmark': landmark,
      'description': description,
      'household_head': householdHead,
      'household_size': householdSize,
      'males': males,
      'females': females,
      'pensioners': pensioners,
      'chronic_members': chronicMembers,
      'phone_number': phoneNumber,
      'services': services,
      'notes': notes,
      'site_code': siteCode,
      'province': province,
      'district': district,
      'municipality': municipality,
      'ward': ward,
      'traditional_authority': traditionalAuthority,
      'section': section,
      'distance_from_landmark': distanceFromLandmark,
      'directions': directions,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'siteCode': siteCode,
      'name': name,
      'village': village,
      'type': type.name,
      'registeredAt': Timestamp.fromDate(registeredAt),
      'province': province,
      'district': district,
      'municipality': municipality,
      'ward': ward,
      'traditionalAuthority': traditionalAuthority,
      'section': section,
      'directions': directions,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'landmark': landmark,
      'distanceFromLandmark': distanceFromLandmark,
      'description': description,
      'householdHead': householdHead,
      'householdSize': householdSize,
      'males': males,
      'females': females,
      'pensioners': pensioners,
      'chronicMembers': chronicMembers,
      'phoneNumber': phoneNumber,
      'services': services,
      'notes': notes,
      'imagePath': imagePath,
    };
  }

  static String? _toString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }

  static DateTime _toDateTime(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value)?? DateTime.now();
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return DateTime.now();
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static SiteType _toSiteType(dynamic value) {
    if (value is SiteType) return value;
    if (value is String && value.isNotEmpty) {
      return SiteTypeX.fromString(value);
    }
    return SiteType.house;
  }

  factory Site.fromMap(Map<String, dynamic> map) {
    return Site(
      id: _toInt(map['id']),
      firestoreId: _toString(map['firestore_id']),
      isSynced: (_toInt(map['isSynced'])?? 0) == 1,
      name: _toString(map['name'])?? '',
      village: _toString(map['village'])?? '',
      type: _toSiteType(map['type']),
      registeredAt: _toDateTime(map['registered_at']),
      imagePath: _toString(map['image_path']),
      latitude: _toDouble(map['latitude']),
      longitude: _toDouble(map['longitude']),
      address: _toString(map['address']),
      landmark: _toString(map['landmark']),
      description: _toString(map['description']),
      householdHead: _toString(map['household_head']),
      householdSize: _toInt(map['household_size']),
      males: _toInt(map['males']),
      females: _toInt(map['females']),
      pensioners: _toInt(map['pensioners']),
      chronicMembers: _toInt(map['chronic_members']),
      phoneNumber: _toString(map['phone_number']),
      services: _toString(map['services']),
      notes: _toString(map['notes']),
      siteCode: _toString(map['site_code'])?? '',
      province: _toString(map['province'])?? '',
      district: _toString(map['district'])?? '',
      municipality: _toString(map['municipality'])?? '',
      ward: _toString(map['ward'])?? '',
      traditionalAuthority: _toString(map['traditional_authority'])?? '',
      section: _toString(map['section'])?? '',
      directions: _toString(map['directions'])?? '',
      distanceFromLandmark: _toDouble(map['distance_from_landmark']),
    );
  }

  factory Site.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Site(
      id: null,
      firestoreId: doc.id,
      isSynced: true,
      siteCode: data['siteCode']?? '',
      name: data['name']?? '',
      village: data['village']?? '',
      type: _toSiteType(data['type']),
      registeredAt: (data['registeredAt'] as Timestamp).toDate(),
      imagePath: data['imagePath'],
      latitude: _toDouble(data['latitude']),
      longitude: _toDouble(data['longitude']),
      address: data['address'],
      landmark: data['landmark'],
      description: data['description'],
      householdHead: data['householdHead'],
      householdSize: _toInt(data['householdSize']),
      males: _toInt(data['males']),
      females: _toInt(data['females']),
      pensioners: _toInt(data['pensioners']),
      chronicMembers: _toInt(data['chronicMembers']),
      phoneNumber: data['phoneNumber'],
      services: data['services'],
      notes: data['notes'],
      province: data['province']?? '',
      district: data['district']?? '',
      municipality: data['municipality']?? '',
      ward: data['ward']?? '',
      traditionalAuthority: data['traditionalAuthority']?? '',
      section: data['section']?? '',
      directions: data['directions']?? '',
      distanceFromLandmark: _toDouble(data['distanceFromLandmark']),
    );
  }
}

/// Aggregate counts used to populate the dashboard summary card.
class DashboardStats {
  final int totalSites;
  final int registeredToday;
  final int registeredThisWeek;
  final int villageCount;
  final Map<SiteType, int> countsByType;
  final Map<String, int> countsByVillage;

  const DashboardStats({
    required this.totalSites,
    required this.registeredToday,
    required this.registeredThisWeek,
    required this.villageCount,
    required this.countsByType,
    required this.countsByVillage,
  });

  factory DashboardStats.empty() => const DashboardStats(
        totalSites: 0,
        registeredToday: 0,
        registeredThisWeek: 0,
        villageCount: 0,
        countsByType: {},
        countsByVillage: {},
      );
}