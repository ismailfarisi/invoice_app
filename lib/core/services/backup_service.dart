import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_invoice_app/features/invoice/domain/models/invoice.dart';
import 'package:flutter_invoice_app/features/lpo/domain/models/lpo.dart';
import 'package:flutter_invoice_app/features/product/domain/models/product.dart';
import 'package:flutter_invoice_app/features/proforma/domain/models/proforma.dart';
import 'package:flutter_invoice_app/features/quotation/domain/models/quotation.dart';
import 'package:flutter_invoice_app/features/settings/domain/models/business_profile.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

class BackupService {
  static const String _invoiceBox = 'invoices';
  static const String _quotationBox = 'quotations';
  static const String _clientBox = 'clients';
  static const String _productBox = 'products';
  static const String _settingsBox = 'settings';
  static const String _lpoBox = 'lpos';
  static const String _proformaBox = 'proformas';

  Future<void> exportData() async {
    try {
      final invoices = Hive.box<Invoice>(
        _invoiceBox,
      ).values.map((e) => e.toJson()).toList();
      final quotations = Hive.box<Quotation>(
        _quotationBox,
      ).values.map((e) => e.toJson()).toList();
      final clients = Hive.box<Client>(
        _clientBox,
      ).values.map((e) => e.toJson()).toList();
      final products = Hive.box<Product>(
        _productBox,
      ).values.map((e) => e.toJson()).toList();
      final settings = Hive.box<BusinessProfile>(
        _settingsBox,
      ).values.map((e) => e.toJson()).toList();
      final lpos = Hive.box<Lpo>(
        _lpoBox,
      ).values.map((e) => e.toJson()).toList();
      final proformas = Hive.box<ProformaInvoice>(
        _proformaBox,
      ).values.map((e) => e.toJson()).toList();

      final backupData = {
        'version': 1,
        'timestamp': DateTime.now().toIso8601String(),
        'invoices': invoices,
        'quotations': quotations,
        'clients': clients,
        'products': products,
        'settings': settings,
        'lpos': lpos,
        'proformas': proformas,
      };

      final jsonString = jsonEncode(backupData);
      final directory = await getTemporaryDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${directory.path}/invoice_app_backup_$timestamp.json');
      await file.writeAsString(jsonString);

      await Share.shareXFiles([XFile(file.path)], text: 'Invoice App Backup');
    } catch (e) {
      throw Exception('Export failed: $e');
    }
  }

  Future<void> importData() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any);

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();
        final Map<String, dynamic> data = jsonDecode(jsonString);

        if (data['version'] != 1) {
          throw Exception('Unsupported backup version');
        }

        // Clear existing data
        await Hive.box<Invoice>(_invoiceBox).clear();
        await Hive.box<Quotation>(_quotationBox).clear();
        await Hive.box<Client>(_clientBox).clear();
        await Hive.box<Product>(_productBox).clear();
        await Hive.box<BusinessProfile>(_settingsBox).clear();
        await Hive.box<Lpo>(_lpoBox).clear();
        await Hive.box<ProformaInvoice>(_proformaBox).clear();

        // Restore data
        if (data['invoices'] != null) {
          final box = Hive.box<Invoice>(_invoiceBox);
          for (var item in data['invoices']) {
            final invoice = Invoice.fromJson(item);
            await box.put(invoice.id, invoice);
          }
        }
        if (data['quotations'] != null) {
          final box = Hive.box<Quotation>(_quotationBox);
          for (var item in data['quotations']) {
            final quotation = Quotation.fromJson(item);
            await box.put(quotation.id, quotation);
          }
        }
        if (data['clients'] != null) {
          final box = Hive.box<Client>(_clientBox);
          for (var item in data['clients']) {
            final client = Client.fromJson(item);
            await box.put(client.id, client);
          }
        }
        if (data['products'] != null) {
          final box = Hive.box<Product>(_productBox);
          for (var item in data['products']) {
            final product = Product.fromJson(item);
            await box.put(product.id, product);
          }
        }
        if (data['settings'] != null) {
          final box = Hive.box<BusinessProfile>(_settingsBox);
          for (var item in data['settings']) {
            final profile = BusinessProfile.fromJson(item);
            // Settings uses a fixed key 'profile'
            await box.put('profile', profile);
          }
        }
        if (data['lpos'] != null) {
          final box = Hive.box<Lpo>(_lpoBox);
          for (var item in data['lpos']) {
            final lpo = Lpo.fromJson(item);
            await box.put(lpo.id, lpo);
          }
        }
        if (data['proformas'] != null) {
          final box = Hive.box<ProformaInvoice>(_proformaBox);
          for (var item in data['proformas']) {
            final proforma = ProformaInvoice.fromJson(item);
            await box.put(proforma.id, proforma);
          }
        }
      }
    } catch (e) {
      throw Exception('Import failed: $e');
    }
  }
}
