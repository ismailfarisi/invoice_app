// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quotation.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class QuotationAdapter extends TypeAdapter<Quotation> {
  @override
  final int typeId = 7;

  @override
  Quotation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Quotation(
      id: fields[0] as String,
      quotationNumber: fields[1] as String,
      date: fields[2] as DateTime,
      validUntil: fields[3] as DateTime?,
      client: fields[4] as Client,
      items: (fields[5] as List).cast<LineItem>(),
      subtotal: fields[6] as double,
      taxAmount: fields[7] as double,
      discount: fields[8] as double,
      total: fields[9] as double,
      status: fields[10] as QuotationStatus,
      notes: fields[11] as String?,
      terms: fields[12] as String?,
      enquiryRef: fields[13] as String?,
      project: fields[14] as String?,
      termsAndConditions: fields[15] as String?,
      salesPerson: fields[16] as String?,
      isVatApplicable: fields[17] as bool?,
      currency: fields[18] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Quotation obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.quotationNumber)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.validUntil)
      ..writeByte(4)
      ..write(obj.client)
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
      ..write(obj.enquiryRef)
      ..writeByte(14)
      ..write(obj.project)
      ..writeByte(15)
      ..write(obj.termsAndConditions)
      ..writeByte(16)
      ..write(obj.salesPerson)
      ..writeByte(17)
      ..write(obj.isVatApplicable)
      ..writeByte(18)
      ..write(obj.currency);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuotationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class QuotationStatusAdapter extends TypeAdapter<QuotationStatus> {
  @override
  final int typeId = 6;

  @override
  QuotationStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return QuotationStatus.draft;
      case 1:
        return QuotationStatus.sent;
      case 2:
        return QuotationStatus.accepted;
      case 3:
        return QuotationStatus.rejected;
      case 4:
        return QuotationStatus.expired;
      default:
        return QuotationStatus.draft;
    }
  }

  @override
  void write(BinaryWriter writer, QuotationStatus obj) {
    switch (obj) {
      case QuotationStatus.draft:
        writer.writeByte(0);
        break;
      case QuotationStatus.sent:
        writer.writeByte(1);
        break;
      case QuotationStatus.accepted:
        writer.writeByte(2);
        break;
      case QuotationStatus.rejected:
        writer.writeByte(3);
        break;
      case QuotationStatus.expired:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuotationStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
