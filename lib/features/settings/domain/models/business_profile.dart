import 'package:hive/hive.dart';

part 'business_profile.g.dart';

@HiveType(typeId: 5)
class BusinessProfile {
  @HiveField(0)
  final String companyName;
  @HiveField(1)
  final String? email;
  @HiveField(2)
  final String? phone;
  @HiveField(3)
  final String? address;
  @HiveField(4)
  final String? taxId;
  @HiveField(5)
  final String? logoPath;
  @HiveField(6)
  final String currency;
  @HiveField(7)
  final String? bankDetails;
  @HiveField(8)
  final String? website;
  @HiveField(9)
  final String? mobile;
  @HiveField(10)
  final bool isSynced;
  @HiveField(11)
  final DateTime? updatedAt;
  @HiveField(12)
  final String? userId;

  BusinessProfile({
    required this.companyName,
    this.email,
    this.phone,
    this.address,
    this.taxId,
    this.logoPath,
    this.currency = 'USD',
    this.bankDetails,
    this.website,
    this.mobile,
    this.isSynced = false,
    this.updatedAt,
    this.userId,
  });

  Map<String, dynamic> toJson() {
    return {
      'companyName': companyName,
      'email': email,
      'phone': phone,
      'address': address,
      'taxId': taxId,
      'logoPath': logoPath,
      'currency': currency,
      'bankDetails': bankDetails,
      'website': website,
      'mobile': mobile,
      'isSynced': isSynced,
      'updatedAt': updatedAt?.toIso8601String(),
      'user_id': userId,
    };
  }

  factory BusinessProfile.fromJson(Map<String, dynamic> json) {
    return BusinessProfile(
      companyName: json['companyName'],
      email: json['email'],
      phone: json['phone'],
      address: json['address'],
      taxId: json['taxId'],
      logoPath: json['logoPath'],
      currency: json['currency'] ?? 'USD',
      bankDetails: json['bankDetails'],
      website: json['website'],
      mobile: json['mobile'],
      isSynced: json['isSynced'] ?? false,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      userId: json['user_id'],
    );
  }
}
