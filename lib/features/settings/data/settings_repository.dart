import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_invoice_app/features/settings/domain/models/business_profile.dart';

final businessProfileRepositoryProvider = Provider((ref) => BusinessProfileRepository());

class BusinessProfileRepository {
  final Box<BusinessProfile> _box = Hive.box<BusinessProfile>('settings');

  BusinessProfile? getProfile() {
    return _box.get('profile');
  }

  Future<void> saveProfile(BusinessProfile profile) async {
    await _box.put('profile', profile);
  }
}
