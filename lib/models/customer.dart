class Customer {
  final String branchName;
  final String cdam;
  final String fs;
  final String channel;
  final String salesRepId;
  final String salesRepName;
  final String customerCode;
  final String customerName;
  final String barangay;
  final String city;
  final String province;
  final String status;
  final String retailEnvironment;
  final String partyClassificationDescription;
  final String coverageDay;
  final String wklyCoverage;
  final int freqCount;
  final String freq;
  final double? latitude;
  final double? longitude;
  final String phone;
  final String firstName;
  final String lastName;
  final String address;
  final String tinNo;
  final String? editedFields;

  Customer({
    required this.branchName,
    required this.cdam,
    required this.fs,
    required this.channel,
    required this.salesRepId,
    required this.salesRepName,
    required this.customerCode,
    required this.customerName,
    required this.barangay,
    required this.city,
    required this.province,
    required this.status,
    required this.retailEnvironment,
    required this.partyClassificationDescription,
    required this.coverageDay,
    required this.wklyCoverage,
    required this.freqCount,
    required this.freq,
    this.latitude,
    this.longitude,
    required this.phone,
    required this.firstName,
    required this.lastName,
    required this.address,
    required this.tinNo,
    this.editedFields,
  });

  String get fullName {
    final full = '$firstName $lastName'.trim();
    return full;
  }

  factory Customer.fromJson(Map<String, dynamic> json) {
    final rawFirstName = (json['first_name'] ?? '').toString().trim();
    final rawLastName = (json['last_name'] ?? '').toString().trim();
    final legacyOwner = (json['owner'] ?? '').toString().trim();

    String resolvedFirstName = rawFirstName;
    String resolvedLastName = rawLastName;

    if (resolvedFirstName.isEmpty && resolvedLastName.isEmpty && legacyOwner.isNotEmpty) {
      final parts = legacyOwner.split(RegExp(r'\s+'));
      resolvedFirstName = parts.first;
      resolvedLastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    }

    return Customer(
      branchName: json['branch_name'] ?? '',
      cdam: json['cdam'] ?? '',
      fs: json['fs'] ?? '',
      channel: json['channel'] ?? '',
      salesRepId: json['sales_rep_id'] ?? '',
      salesRepName: json['sales_rep_name'] ?? '',
      customerCode: json['customer_code'] ?? '',
      customerName: json['customer_name'] ?? '',
      barangay: json['barangay'] ?? '',
      city: json['city'] ?? '',
      province: json['province'] ?? '',
      status: json['status'] ?? '',
      retailEnvironment: json['retail_environment'] ?? '',
      partyClassificationDescription: json['party_classification_description'] ?? '',
      coverageDay: json['coverage_day'] ?? '',
      wklyCoverage: json['wkly_coverage'] ?? '',
      freqCount: int.tryParse((json['freq_count'] ?? '').toString()) ?? 0,
      freq: json['freq'] ?? '',
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      phone: json['phone'] ?? '',
      firstName: resolvedFirstName,
      lastName: resolvedLastName,
      address: json['address'] ?? '',
      tinNo: (json['tin_no'] ?? json['tin no'] ?? '').toString(),
      editedFields: json['edited_fields'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'branch_name': branchName,
      'cdam': cdam,
      'fs': fs,
      'channel': channel,
      'sales_rep_id': salesRepId,
      'sales_rep_name': salesRepName,
      'customer_code': customerCode,
      'customer_name': customerName,
      'barangay': barangay,
      'city': city,
      'province': province,
      'status': status,
      'retail_environment': retailEnvironment,
      'party_classification_description': partyClassificationDescription,
      'coverage_day': coverageDay,
      'wkly_coverage': wklyCoverage,
      'freq_count': freqCount,
      'freq': freq,
      'latitude': latitude,
      'longitude': longitude,
      'phone': phone,
      'first_name': firstName,
      'last_name': lastName,
      'address': address,
      'tin_no': tinNo,
      'edited_fields': editedFields,
    };
  }

  Customer copyWith({
    String? branchName,
    String? cdam,
    String? fs,
    String? channel,
    String? salesRepId,
    String? salesRepName,
    String? customerCode,
    String? customerName,
    String? barangay,
    String? city,
    String? province,
    String? status,
    String? retailEnvironment,
    String? partyClassificationDescription,
    String? coverageDay,
    String? wklyCoverage,
    int? freqCount,
    String? freq,
    double? latitude,
    double? longitude,
    String? phone,
    String? firstName,
    String? lastName,
    String? address,
    String? tinNo,
    String? editedFields,
  }) {
    return Customer(
      branchName: branchName ?? this.branchName,
      cdam: cdam ?? this.cdam,
      fs: fs ?? this.fs,
      channel: channel ?? this.channel,
      salesRepId: salesRepId ?? this.salesRepId,
      salesRepName: salesRepName ?? this.salesRepName,
      customerCode: customerCode ?? this.customerCode,
      customerName: customerName ?? this.customerName,
      barangay: barangay ?? this.barangay,
      city: city ?? this.city,
      province: province ?? this.province,
      status: status ?? this.status,
      retailEnvironment: retailEnvironment ?? this.retailEnvironment,
      partyClassificationDescription: partyClassificationDescription ?? this.partyClassificationDescription,
      coverageDay: coverageDay ?? this.coverageDay,
      wklyCoverage: wklyCoverage ?? this.wklyCoverage,
      freqCount: freqCount ?? this.freqCount,
      freq: freq ?? this.freq,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      phone: phone ?? this.phone,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      address: address ?? this.address,
      tinNo: tinNo ?? this.tinNo,
      editedFields: editedFields ?? this.editedFields,
    );
  }
}