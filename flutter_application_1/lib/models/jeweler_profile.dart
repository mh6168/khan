class JewelerProfile {
  const JewelerProfile({
    required this.id,
    required this.status,
    this.storeName,
    this.fullName,
    this.phone,
    this.location,
    this.description,
    this.logoUrl,
  });

  factory JewelerProfile.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    return JewelerProfile(
      id: id,
      status: _stringValue(data['status']) ?? '',
      storeName: _stringValue(data['storeName']),
      fullName: _stringValue(data['fullName']),
      phone: _stringValue(data['phone']),
      location: _stringValue(data['storeAddress']),
      description: _stringValue(data['description']),
      logoUrl: _stringValue(data['logoUrl']),
    );
  }

  final String id;
  final String status;
  final String? storeName;
  final String? fullName;
  final String? phone;
  final String? location;
  final String? description;
  final String? logoUrl;

  bool get isVerified => status == 'approved';

  String get displayName =>
      storeName ?? fullName ?? 'KHAN jeweler';

  static String? _stringValue(dynamic value) {
    return value is String && value.trim().isNotEmpty ? value.trim() : null;
  }
}
