// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lpo.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LpoAdapter extends TypeAdapter<Lpo> {
  @override
  final int typeId = 9;

  @override
  Lpo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Lpo(
      id: fields[0] as String,
      lpoNumber: fields[1] as String,
      date: fields[2] as DateTime?,
      expectedDeliveryDate: fields[3] as DateTime?,
      vendor: fields[4] as Client,
      items: (fields[5] as List).cast<LineItem>(),
      subtotal: fields[6] as double,
      taxAmount: fields[7] as double,
      discount: fields[8] as double,
      total: fields[9] as double,
      status: fields[10] as LpoStatus,
      notes: fields[11] as String?,
      terms: fields[12] as String?,
      termsAndConditions: fields[13] as String?,
      salesPerson: fields[14] as String?,
      isVatApplicable: fields[15] as bool?,
      currency: fields[16] as String?,
      placeOfSupply: fields[17] as String?,
      paymentTerms: fields[18] as String?,
      otherReference: fields[19] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Lpo obj) {
    writer
      ..writeByte(20)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.lpoNumber)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.expectedDeliveryDate)
      ..writeByte(4)
      ..write(obj.vendor)
      ..writeByte(5)
      ..write(obj.items)
      ..writeByte(6)
      ..write(obj.subtotal)
      ..writeByte(7)
      ..write(obj.taxAmount)
      ..writeByte(8)
      ..write(obj.discount)
      ..writeByte(9)
      ..write(obj.total)
      ..writeByte(10)
      ..write(obj.status)
      ..writeByte(11)
      ..write(obj.notes)
      ..writeByte(12)
      ..write(obj.terms)
      ..writeByte(13)
      ..write(obj.termsAndConditions)
      ..writeByte(14)
      ..write(obj.salesPerson)
      ..writeByte(15)
      ..write(obj.isVatApplicable)
      ..writeByte(16)
      ..write(obj.currency)
      ..writeByte(17)
      ..write(obj.placeOfSupply)
      ..writeByte(18)
      ..write(obj.paymentTerms)
      ..writeByte(19)
      ..write(obj.otherReference);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LpoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LpoStatusAdapter extends TypeAdapter<LpoStatus> {
  @override
  final int typeId = 8;

  @override
  LpoStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return LpoStatus.draft;
      case 1:
        return LpoStatus.sent;
      case 2:
        return LpoStatus.approved;
      case 3:
        return LpoStatus.rejected;
      case 4:
        return LpoStatus.completed;
      default:
        return LpoStatus.draft;
    }
  }

  @override
  void write(BinaryWriter writer, LpoStatus obj) {
    switch (obj) {
      case LpoStatus.draft:
        writer.writeByte(0);
        break;
      case LpoStatus.sent:
        writer.writeByte(1);
        break;
      case LpoStatus.approved:
        writer.writeByte(2);
        break;
      case LpoStatus.rejected:
        writer.writeByte(3);
        break;
      case LpoStatus.completed:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LpoStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
