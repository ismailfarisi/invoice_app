// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'business_profile.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BusinessProfileAdapter extends TypeAdapter<BusinessProfile> {
  @override
  final int typeId = 5;

  @override
  BusinessProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BusinessProfile(
      companyName: fields[0] as String,
      email: fields[1] as String?,
      phone: fields[2] as String?,
      address: fields[3] as String?,
      taxId: fields[4] as String?,
      logoPath: fields[5] as String?,
      currency: fields[6] as String,
      bankDetails: fields[7] as String?,
      website: fields[8] as String?,
      mobile: fields[9] as String?,
      defaultVatRate: fields[10] as double?,
      googleSheetsSyncEnabled: fields[11] as bool?,
      googleSheetsSpreadsheetId: fields[12] as String?,
      googleSheetsServiceAccountJson: fields[13] as String?,
      isSynced: fields[14] as bool,
      updatedAt: fields[15] as DateTime?,
      userId: fields[16] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, BusinessProfile obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.companyName)
      ..writeByte(1)
      ..write(obj.email)
      ..writeByte(2)
      ..write(obj.phone)
      ..writeByte(3)
      ..write(obj.address)
      ..writeByte(4)
      ..write(obj.taxId)
      ..writeByte(5)
      ..write(obj.logoPath)
      ..writeByte(6)
      ..write(obj.currency)
      ..writeByte(7)
      ..write(obj.bankDetails)
      ..writeByte(8)
      ..write(obj.website)
      ..writeByte(9)
      ..write(obj.mobile)
      ..writeByte(10)
      ..write(obj.defaultVatRate)
      ..writeByte(11)
      ..write(obj.googleSheetsSyncEnabled)
      ..writeByte(12)
      ..write(obj.googleSheetsSpreadsheetId)
      ..writeByte(13)
      ..write(obj.googleSheetsServiceAccountJson)
      ..writeByte(14)
      ..write(obj.isSynced)
      ..writeByte(15)
      ..write(obj.updatedAt)
      ..writeByte(16)
      ..write(obj.userId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BusinessProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
