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
  });
}
