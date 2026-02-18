import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_invoice_app/core/services/google_sheets_service.dart';
import 'package:flutter_invoice_app/features/settings/domain/models/business_profile.dart';
import 'package:flutter_invoice_app/features/settings/data/settings_repository.dart';
import 'package:flutter_invoice_app/features/invoice/data/invoice_repository.dart';
import 'package:flutter_invoice_app/features/client/data/client_repository.dart';
import 'package:flutter_invoice_app/features/product/data/product_repository.dart';
import 'package:flutter_invoice_app/features/lpo/data/lpo_repository.dart';
import 'package:flutter_invoice_app/features/proforma/data/proforma_repository.dart';
import 'package:flutter_invoice_app/features/quotation/data/quotation_repository.dart';

final googleSheetsServiceProvider = Provider((ref) => GoogleSheetsService());

final syncServiceProvider = Provider((ref) => SyncService(ref));

class SyncService {
  final Ref _ref;
  final _googleSheetsService = GoogleSheetsService();
  Timer? _debounceTimer;
  String? _lastError;
  bool _isSyncing = false;

  SyncService(this._ref) {
    _initMonitoring();
  }

  String? get lastError => _lastError;
  bool get isSyncing => _isSyncing;

  void _initMonitoring() {
    // Listen to changes in all relevant repositories for type-safe monitoring
    _ref.read(invoiceRepositoryProvider).listenable.addListener(_scheduleSync);
    _ref.read(clientRepositoryProvider).listenable.addListener(_scheduleSync);
    _ref.read(productRepositoryProvider).listenable.addListener(_scheduleSync);
    _ref
        .read(quotationRepositoryProvider)
        .listenable
        .addListener(_scheduleSync);
    _ref
        .read(businessProfileRepositoryProvider)
        .listenable
        .addListener(_scheduleSync);

    // Repositories that open boxes asynchronously
    _ref
        .read(lpoRepositoryProvider)
        .getListenable()
        .then((listenable) => listenable.addListener(_scheduleSync));
    _ref
        .read(proformaRepositoryProvider)
        .getListenable()
        .then((listenable) => listenable.addListener(_scheduleSync));
  }

  void _scheduleSync() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () {
      syncAll();
    });
  }

  Future<void> syncAll() async {
    final settingsRepo = _ref.read(businessProfileRepositoryProvider);
    final profile = settingsRepo.getProfile();

    if (profile == null ||
        profile.googleSheetsSyncEnabled != true ||
        profile.googleSheetsServiceAccountJson == null) {
      return;
    }

    _isSyncing = true;
    _lastError = null;

    try {
      final authenticated = await _googleSheetsService.authenticate(
        profile.googleSheetsServiceAccountJson!,
      );
      if (!authenticated) {
        _lastError = 'Authentication failed. Check your Service Account JSON.';
        _isSyncing = false;
        return;
      }

      String? spreadsheetId = profile.googleSheetsSpreadsheetId;
      if (spreadsheetId == null || spreadsheetId.isEmpty) {
        spreadsheetId = await _googleSheetsService.createSpreadsheet(
          'Invoice App Sync - ${profile.companyName}',
        );
        if (spreadsheetId != null) {
          final updatedProfile = profile.copyWith(
            googleSheetsSpreadsheetId: spreadsheetId,
          );
          // We need copyWith for BusinessProfile
          await settingsRepo.saveProfile(updatedProfile);
        } else {
          _lastError = 'Failed to create spreadsheet.';
          _isSyncing = false;
          return;
        }
      }

      await Future.wait([
        _syncInvoices(spreadsheetId),
        _syncClients(spreadsheetId),
        _syncProducts(spreadsheetId),
        _syncLpos(spreadsheetId),
        _syncProformas(spreadsheetId),
        _syncQuotations(spreadsheetId),
      ]);
    } catch (e) {
      _lastError = 'Sync failed: $e';
      print(_lastError);
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncInvoices(String spreadsheetId) async {
    final invoices = _ref.read(invoiceRepositoryProvider).getAllInvoices();
    final headers = [
      'ID',
      'Invoice Number',
      'Date',
      'Due Date',
      'Client Name',
      'Subtotal',
      'Tax',
      'Discount',
      'Total',
      'Status',
    ];

    await _googleSheetsService.setupSheet(spreadsheetId, 'Invoices', headers);

    final data = invoices
        .map(
          (inv) => [
            inv.id,
            inv.invoiceNumber,
            inv.date != null ? DateFormat('yyyy-MM-dd').format(inv.date!) : '',
            inv.dueDate != null
                ? DateFormat('yyyy-MM-dd').format(inv.dueDate!)
                : '',
            inv.client.name,
            inv.subtotal,
            inv.taxAmount,
            inv.discount,
            inv.total,
            inv.status.name,
          ],
        )
        .toList();

    await _googleSheetsService.updateData(spreadsheetId, 'Invoices', data);
  }

  Future<void> _syncClients(String spreadsheetId) async {
    final clients = _ref.read(clientRepositoryProvider).getAllClients();
    final headers = [
      'ID',
      'Name',
      'Email',
      'Address',
      'Phone',
      'Contact Person',
      'Tax ID',
    ];

    await _googleSheetsService.setupSheet(spreadsheetId, 'Clients', headers);

    final data = clients
        .map(
          (c) => [
            c.id,
            c.name,
            c.email,
            c.address ?? '',
            c.phone ?? '',
            c.contactPerson ?? '',
            c.taxId ?? '',
          ],
        )
        .toList();

    await _googleSheetsService.updateData(spreadsheetId, 'Clients', data);
  }

  Future<void> _syncProducts(String spreadsheetId) async {
    final products = _ref.read(productRepositoryProvider).getAllProducts();
    final headers = [
      'ID',
      'Name',
      'SKU',
      'Unit Price',
      'Stock',
      'Unit',
      'Description',
    ];

    await _googleSheetsService.setupSheet(spreadsheetId, 'Products', headers);

    final data = products
        .map(
          (p) => [
            p.id,
            p.name,
            p.sku ?? '',
            p.unitPrice,
            p.stockQuantity,
            p.unit ?? 'NOS',
            p.description ?? '',
          ],
        )
        .toList();

    await _googleSheetsService.updateData(spreadsheetId, 'Products', data);
  }

  Future<void> _syncLpos(String spreadsheetId) async {
    final lpos = await _ref.read(lpoRepositoryProvider).getLpos();
    final headers = [
      'ID',
      'LPO Number',
      'Date',
      'Expected Delivery',
      'Vendor',
      'Total',
      'Status',
    ];

    await _googleSheetsService.setupSheet(spreadsheetId, 'LPOs', headers);

    final data = lpos
        .map(
          (l) => [
            l.id,
            l.lpoNumber,
            l.date != null ? DateFormat('yyyy-MM-dd').format(l.date!) : '',
            l.expectedDeliveryDate != null
                ? DateFormat('yyyy-MM-dd').format(l.expectedDeliveryDate!)
                : '',
            l.vendor.name,
            l.total,
            l.status.name,
          ],
        )
        .toList();

    await _googleSheetsService.updateData(spreadsheetId, 'LPOs', data);
  }

  Future<void> _syncProformas(String spreadsheetId) async {
    final proformas = await _ref
        .read(proformaRepositoryProvider)
        .getProformas();
    final headers = [
      'ID',
      'Proforma Number',
      'Date',
      'Valid Until',
      'Client',
      'Total',
      'Status',
    ];

    await _googleSheetsService.setupSheet(spreadsheetId, 'Proformas', headers);

    final data = proformas
        .map(
          (p) => [
            p.id,
            p.proformaNumber,
            p.date != null ? DateFormat('yyyy-MM-dd').format(p.date!) : '',
            p.validUntil != null
                ? DateFormat('yyyy-MM-dd').format(p.validUntil!)
                : '',
            p.client.name,
            p.total,
            p.status.name,
          ],
        )
        .toList();

    await _googleSheetsService.updateData(spreadsheetId, 'Proformas', data);
  }

  Future<void> _syncQuotations(String spreadsheetId) async {
    final quotations = _ref
        .read(quotationRepositoryProvider)
        .getAllQuotations();
    final headers = [
      'ID',
      'Quotation Number',
      'Date',
      'Valid Until',
      'Client',
      'Total',
      'Status',
    ];

    await _googleSheetsService.setupSheet(spreadsheetId, 'Quotations', headers);

    final data = quotations
        .map(
          (q) => [
            q.id,
            q.quotationNumber,
            q.date != null ? DateFormat('yyyy-MM-dd').format(q.date!) : '',
            q.validUntil != null
                ? DateFormat('yyyy-MM-dd').format(q.validUntil!)
                : '',
            q.client.name,
            q.total,
            q.status.name,
          ],
        )
        .toList();

    await _googleSheetsService.updateData(spreadsheetId, 'Quotations', data);
  }
}

extension BusinessProfileExtension on BusinessProfile {
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
