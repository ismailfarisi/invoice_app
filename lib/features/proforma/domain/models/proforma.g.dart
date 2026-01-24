// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'proforma.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProformaInvoiceAdapter extends TypeAdapter<ProformaInvoice> {
  @override
  final int typeId = 11;

  @override
  ProformaInvoice read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProformaInvoice(
      id: fields[0] as String,
      proformaNumber: fields[1] as String,
      date: fields[2] as DateTime,
      validUntil: fields[3] as DateTime?,
      client: fields[4] as Client,
      items: (fields[5] as List).cast<LineItem>(),
      subtotal: fields[6] as double,
      taxAmount: fields[7] as double,
      discount: fields[8] as double,
      total: fields[9] as double,
      status: fields[10] as ProformaStatus,
      notes: fields[11] as String?,
      terms: fields[12] as String?,
      termsAndConditions: fields[13] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ProformaInvoice obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.proformaNumber)
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
      ..write(obj.termsAndConditions);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProformaInvoiceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ProformaStatusAdapter extends TypeAdapter<ProformaStatus> {
  @override
  final int typeId = 10;

  @override
  ProformaStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ProformaStatus.draft;
      case 1:
        return ProformaStatus.sent;
      case 2:
        return ProformaStatus.accepted;
      case 3:
        return ProformaStatus.rejected;
      case 4:
        return ProformaStatus.converted;
      default:
        return ProformaStatus.draft;
    }
  }

  @override
  void write(BinaryWriter writer, ProformaStatus obj) {
    switch (obj) {
      case ProformaStatus.draft:
        writer.writeByte(0);
        break;
      case ProformaStatus.sent:
        writer.writeByte(1);
        break;
      case ProformaStatus.accepted:
        writer.writeByte(2);
        break;
      case ProformaStatus.rejected:
        writer.writeByte(3);
        break;
      case ProformaStatus.converted:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProformaStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
