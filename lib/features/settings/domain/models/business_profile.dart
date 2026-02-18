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
  final double? defaultVatRate;
  @HiveField(11)
  final bool? googleSheetsSyncEnabled;
  @HiveField(12)
  final String? googleSheetsSpreadsheetId;
  @HiveField(13)
  final String? googleSheetsServiceAccountJson;
  @HiveField(14, defaultValue: false)
  final bool isSynced;
  @HiveField(15)
  final DateTime? updatedAt;
  @HiveField(16)
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
    this.defaultVatRate = 5.0,
    this.googleSheetsSyncEnabled = false,
    this.googleSheetsSpreadsheetId,
    this.googleSheetsServiceAccountJson,
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
      'defaultVatRate': defaultVatRate,
      'googleSheetsSyncEnabled': googleSheetsSyncEnabled,
      'googleSheetsSpreadsheetId': googleSheetsSpreadsheetId,
      'googleSheetsServiceAccountJson': googleSheetsServiceAccountJson,
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
      defaultVatRate: (json['defaultVatRate'] as num?)?.toDouble() ?? 5.0,
      googleSheetsSyncEnabled: json['googleSheetsSyncEnabled'] ?? false,
      googleSheetsSpreadsheetId: json['googleSheetsSpreadsheetId'],
      googleSheetsServiceAccountJson: json['googleSheetsServiceAccountJson'],
    );
  }

  BusinessProfile copyWith({
    String? companyName,
    String? email,
    String? phone,
    String? address,
    String? taxId,
    String? logoPath,
    String? currency,
    String? bankDetails,
    String? website,
    String? mobile,
    double? defaultVatRate,
    bool? googleSheetsSyncEnabled,
    String? googleSheetsSpreadsheetId,
    String? googleSheetsServiceAccountJson,
  }) {
    return BusinessProfile(
      companyName: companyName ?? this.companyName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      taxId: taxId ?? this.taxId,
      logoPath: logoPath ?? this.logoPath,
      currency: currency ?? this.currency,
      bankDetails: bankDetails ?? this.bankDetails,
      website: website ?? this.website,
      mobile: mobile ?? this.mobile,
      defaultVatRate: defaultVatRate ?? this.defaultVatRate,
      googleSheetsSyncEnabled:
          googleSheetsSyncEnabled ?? this.googleSheetsSyncEnabled,
      googleSheetsSpreadsheetId:
          googleSheetsSpreadsheetId ?? this.googleSheetsSpreadsheetId,
      googleSheetsServiceAccountJson:
          googleSheetsServiceAccountJson ?? this.googleSheetsServiceAccountJson,
    );
  }
}
