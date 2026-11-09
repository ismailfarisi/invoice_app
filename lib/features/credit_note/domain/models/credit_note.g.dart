// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'credit_note.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CreditNoteAdapter extends TypeAdapter<CreditNote> {
  @override
  final int typeId = 12;

  @override
  CreditNote read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CreditNote(
      id: fields[0] as String,
      creditNoteNumber: fields[1] as String,
      date: fields[2] as DateTime,
      invoiceId: fields[3] as String,
      invoiceNumber: fields[4] as String,
      invoiceDate: fields[5] as DateTime?,
      client: fields[6] as Client,
      items: (fields[7] as List).cast<LineItem>(),
      subtotal: fields[8] as double,
      vatRate: fields[9] as double,
      taxAmount: fields[10] as double,
      total: fields[11] as double,
      reason: fields[12] as String,
      isVatApplicable: fields[13] == null ? true : fields[13] as bool,
      currency: fields[14] == null ? 'AED' : fields[14] as String,
      placeOfSupply: fields[15] as String?,
      salesPerson: fields[16] as String?,
      isVoided: fields[17] == null ? false : fields[17] as bool,
      isSynced: fields[18] == null ? false : fields[18] as bool,
      updatedAt: fields[19] as DateTime?,
      userId: fields[20] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, CreditNote obj) {
    writer
      ..writeByte(21)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.creditNoteNumber)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.invoiceId)
      ..writeByte(4)
      ..write(obj.invoiceNumber)
      ..writeByte(5)
      ..write(obj.invoiceDate)
      ..writeByte(6)
      ..write(obj.client)
      ..writeByte(7)
      ..write(obj.items)
      ..writeByte(8)
      ..write(obj.subtotal)
      ..writeByte(9)
      ..write(obj.vatRate)
      ..writeByte(10)
      ..write(obj.taxAmount)
      ..writeByte(11)
      ..write(obj.total)
      ..writeByte(12)
      ..write(obj.reason)
      ..writeByte(13)
      ..write(obj.isVatApplicable)
      ..writeByte(14)
      ..write(obj.currency)
      ..writeByte(15)
      ..write(obj.placeOfSupply)
      ..writeByte(16)
      ..write(obj.salesPerson)
      ..writeByte(17)
      ..write(obj.isVoided)
      ..writeByte(18)
      ..write(obj.isSynced)
      ..writeByte(19)
      ..write(obj.updatedAt)
      ..writeByte(20)
      ..write(obj.userId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreditNoteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
