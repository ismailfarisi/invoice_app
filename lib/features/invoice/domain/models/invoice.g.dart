// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invoice.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InvoiceAdapter extends TypeAdapter<Invoice> {
  @override
  final int typeId = 0;

  @override
  Invoice read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Invoice(
      id: fields[0] as String,
      invoiceNumber: fields[1] as String,
      date: fields[2] as DateTime?,
      dueDate: fields[3] as DateTime?,
      client: fields[4] as Client,
      items: (fields[5] as List).cast<LineItem>(),
      subtotal: fields[6] as double,
      taxAmount: fields[7] as double,
      discount: fields[8] as double,
      total: fields[9] as double,
      status: fields[10] as InvoiceStatus,
      notes: fields[11] as String?,
      terms: fields[12] as String?,
      termsAndConditions: fields[13] as String?,
      salesPerson: fields[14] as String?,
      isVatApplicable: fields[15] as bool?,
      currency: fields[16] as String?,
      placeOfSupply: fields[17] as String?,
      deliveryNote: fields[18] as String?,
      paymentTerms: fields[19] as String?,
      supplierReference: fields[20] as String?,
      otherReference: fields[21] as String?,
      buyersOrderNumber: fields[22] as String?,
      buyersOrderDate: fields[23] as DateTime?,
      isSynced: fields[24] as bool,
      updatedAt: fields[25] as DateTime?,
      userId: fields[26] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Invoice obj) {
    writer
      ..writeByte(27)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.invoiceNumber)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.dueDate)
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
      ..write(obj.deliveryNote)
      ..writeByte(19)
      ..write(obj.paymentTerms)
      ..writeByte(20)
      ..write(obj.supplierReference)
      ..writeByte(21)
      ..write(obj.otherReference)
      ..writeByte(22)
      ..write(obj.buyersOrderNumber)
      ..writeByte(23)
      ..write(obj.buyersOrderDate)
      ..writeByte(24)
      ..write(obj.isSynced)
      ..writeByte(25)
      ..write(obj.updatedAt)
      ..writeByte(26)
      ..write(obj.userId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvoiceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ClientAdapter extends TypeAdapter<Client> {
  @override
  final int typeId = 2;

  @override
  Client read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Client(
      id: fields[0] as String,
      name: fields[1] as String,
      email: fields[2] as String,
      address: fields[3] as String?,
      phone: fields[4] as String?,
      contactPerson: fields[5] as String?,
      taxId: fields[6] as String?,
      isSynced: fields[7] as bool,
      updatedAt: fields[8] as DateTime?,
      userId: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Client obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.address)
      ..writeByte(4)
      ..write(obj.phone)
      ..writeByte(5)
      ..write(obj.contactPerson)
      ..writeByte(6)
      ..write(obj.taxId)
      ..writeByte(7)
      ..write(obj.isSynced)
      ..writeByte(8)
      ..write(obj.updatedAt)
      ..writeByte(9)
      ..write(obj.userId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClientAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LineItemAdapter extends TypeAdapter<LineItem> {
  @override
  final int typeId = 3;

  @override
  LineItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LineItem(
      description: fields[0] as String,
      quantity: fields[1] as double,
      unitPrice: fields[2] as double,
      total: fields[3] as double,
      unit: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, LineItem obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.description)
      ..writeByte(1)
      ..write(obj.quantity)
      ..writeByte(2)
      ..write(obj.unitPrice)
      ..writeByte(3)
      ..write(obj.total)
      ..writeByte(4)
      ..write(obj.unit);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LineItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class InvoiceStatusAdapter extends TypeAdapter<InvoiceStatus> {
  @override
  final int typeId = 1;

  @override
  InvoiceStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return InvoiceStatus.draft;
      case 1:
        return InvoiceStatus.sent;
      case 2:
        return InvoiceStatus.paid;
      case 3:
        return InvoiceStatus.overdue;
      case 4:
        return InvoiceStatus.cancelled;
      default:
        return InvoiceStatus.draft;
    }
  }

  @override
  void write(BinaryWriter writer, InvoiceStatus obj) {
    switch (obj) {
      case InvoiceStatus.draft:
        writer.writeByte(0);
        break;
      case InvoiceStatus.sent:
        writer.writeByte(1);
        break;
      case InvoiceStatus.paid:
        writer.writeByte(2);
        break;
      case InvoiceStatus.overdue:
        writer.writeByte(3);
        break;
      case InvoiceStatus.cancelled:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvoiceStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
