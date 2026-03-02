import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_invoice_app/core/services/supabase_service.dart';
import 'package:flutter_invoice_app/features/invoice/domain/models/invoice.dart';
import 'package:flutter_invoice_app/features/quotation/domain/models/quotation.dart';
import 'package:flutter_invoice_app/features/lpo/domain/models/lpo.dart';
import 'package:flutter_invoice_app/features/proforma/domain/models/proforma.dart';
import 'package:flutter_invoice_app/features/product/domain/models/product.dart';
import 'package:flutter_invoice_app/features/settings/domain/models/business_profile.dart';

final syncRepositoryProvider = Provider((ref) {
  final supabase = ref.read(supabaseServiceProvider).client;
  return SyncRepository(supabase);
});

class SyncStats {
  int pushed = 0;
  int pulled = 0;
  String? error;

  void add(SyncStats other) {
    pushed += other.pushed;
    pulled += other.pulled;
    if (other.error != null) error = other.error;
  }
}

class SyncRepository {
  final SupabaseClient _supabase;

  SyncRepository(this._supabase);

  Future<SyncStats> syncAll() async {
    final stats = SyncStats();
    final user = _supabase.auth.currentUser;
    if (user == null) {
      stats.error = 'No user logged in';
      return stats;
    }

    final lastSyncKey = 'last_sync_${user.id}';
    final box = await Hive.openBox('sync_meta');

    try {
      // 1. Push Local Changes
      stats.add(await _pushSettings(user.id));
      stats.add(await _pushProducts(user.id));
      stats.add(await _pushClients(user.id));
      stats.add(await _pushInvoices(user.id));
      stats.add(await _pushQuotations(user.id));
      stats.add(await _pushLpos(user.id));
      stats.add(await _pushProformas(user.id));

      // 2. Pull Remote Changes
      final lastSyncStr = box.get(lastSyncKey);
      final lastSync = lastSyncStr != null
          ? DateTime.parse(lastSyncStr).subtract(const Duration(minutes: 1))
          : DateTime.fromMillisecondsSinceEpoch(0);

      stats.add(await _pullSettings(user.id, lastSync));
      stats.add(await _pullProducts(user.id, lastSync));
      stats.add(await _pullClients(user.id, lastSync));
      stats.add(await _pullInvoices(user.id, lastSync));
      stats.add(await _pullQuotations(user.id, lastSync));
      stats.add(await _pullLpos(user.id, lastSync));
      stats.add(await _pullProformas(user.id, lastSync));

      // 3. Update Last Sync Time
      await box.put(lastSyncKey, DateTime.now().toIso8601String());
    } catch (e) {
      stats.error = e.toString();
    }
    return stats;
  }

  Future<void> resetSyncStatus() async {
    final b1 = Hive.box<Invoice>('invoices');
    final b2 = Hive.box<Quotation>('quotations');
    final b3 = Hive.box<Client>('clients');
    final b4 = Hive.box<Product>('products');
    final b5 = Hive.box<Lpo>('lpos');
    final b6 = Hive.box<ProformaInvoice>('proformas');
    final b7 = Hive.box<BusinessProfile>('settings');

    for (var key in b1.keys) {
      final item = b1.get(key);
      if (item != null) {
        await b1.put(
          key,
          Invoice(
            id: item.id,
            invoiceNumber: item.invoiceNumber,
            date: item.date,
            dueDate: item.dueDate,
            client: item.client,
            items: item.items,
            subtotal: item.subtotal,
            taxAmount: item.taxAmount,
            discount: item.discount,
            total: item.total,
            status: item.status,
            notes: item.notes,
            terms: item.terms,
            termsAndConditions: item.termsAndConditions,
            salesPerson: item.salesPerson,
            isVatApplicable: item.isVatApplicable,
            currency: item.currency,
            placeOfSupply: item.placeOfSupply,
            deliveryNote: item.deliveryNote,
            paymentTerms: item.paymentTerms,
            supplierReference: item.supplierReference,
            otherReference: item.otherReference,
            buyersOrderNumber: item.buyersOrderNumber,
            buyersOrderDate: item.buyersOrderDate,
            isSynced: false,
            updatedAt: item.updatedAt,
            userId: item.userId,
          ),
        );
      }
    }
    for (var key in b2.keys) {
      final item = b2.get(key);
      if (item != null) {
        await b2.put(
          key,
          Quotation(
            id: item.id,
            quotationNumber: item.quotationNumber,
            date: item.date,
            validUntil: item.validUntil,
            client: item.client,
            items: item.items,
            subtotal: item.subtotal,
            taxAmount: item.taxAmount,
            discount: item.discount,
            total: item.total,
            status: item.status,
            notes: item.notes,
            terms: item.terms,
            enquiryRef: item.enquiryRef,
            project: item.project,
            termsAndConditions: item.termsAndConditions,
            salesPerson: item.salesPerson,
            isVatApplicable: item.isVatApplicable,
            currency: item.currency,
            isSynced: false,
            updatedAt: item.updatedAt,
            userId: item.userId,
          ),
        );
      }
    }
    for (var key in b3.keys) {
      final item = b3.get(key);
      if (item != null) {
        await b3.put(
          key,
          Client(
            id: item.id,
            name: item.name,
            email: item.email,
            address: item.address,
            phone: item.phone,
            contactPerson: item.contactPerson,
            taxId: item.taxId,
            isSynced: false,
            updatedAt: item.updatedAt,
            userId: item.userId,
          ),
        );
      }
    }
    for (var key in b4.keys) {
      final item = b4.get(key);
      if (item != null) {
        await b4.put(
          key,
          Product(
            id: item.id,
            name: item.name,
            description: item.description,
            unitPrice: item.unitPrice,
            sku: item.sku,
            stockQuantity: item.stockQuantity,
            unit: item.unit,
            isSynced: false,
            updatedAt: item.updatedAt,
            userId: item.userId,
          ),
        );
      }
    }
    for (var key in b5.keys) {
      final item = b5.get(key);
      if (item != null) {
        await b5.put(
          key,
          Lpo(
            id: item.id,
            lpoNumber: item.lpoNumber,
            date: item.date,
            expectedDeliveryDate: item.expectedDeliveryDate,
            vendor: item.vendor,
            items: item.items,
            subtotal: item.subtotal,
            taxAmount: item.taxAmount,
            discount: item.discount,
            total: item.total,
            status: item.status,
            notes: item.notes,
            terms: item.terms,
            termsAndConditions: item.termsAndConditions,
            salesPerson: item.salesPerson,
            isVatApplicable: item.isVatApplicable,
            currency: item.currency,
            placeOfSupply: item.placeOfSupply,
            paymentTerms: item.paymentTerms,
            otherReference: item.otherReference,
            isSynced: false,
            updatedAt: item.updatedAt,
            userId: item.userId,
          ),
        );
      }
    }
    for (var key in b6.keys) {
      final item = b6.get(key);
      if (item != null) {
        await b6.put(
          key,
          ProformaInvoice(
            id: item.id,
            proformaNumber: item.proformaNumber,
            date: item.date,
            validUntil: item.validUntil,
            client: item.client,
            items: item.items,
            subtotal: item.subtotal,
            taxAmount: item.taxAmount,
            discount: item.discount,
            total: item.total,
            status: item.status,
            notes: item.notes,
            terms: item.terms,
            termsAndConditions: item.termsAndConditions,
            salesPerson: item.salesPerson,
            isVatApplicable: item.isVatApplicable,
            currency: item.currency,
            project: item.project,
            isSynced: false,
            updatedAt: item.updatedAt,
            userId: item.userId,
          ),
        );
      }
    }
    final profile = b7.get('profile');
    if (profile != null) {
      await b7.put(
        'profile',
        BusinessProfile(
          companyName: profile.companyName,
          email: profile.email,
          phone: profile.phone,
          address: profile.address,
          taxId: profile.taxId,
          logoPath: profile.logoPath,
          currency: profile.currency,
          bankDetails: profile.bankDetails,
          website: profile.website,
          mobile: profile.mobile,
          isSynced: false,
          updatedAt: profile.updatedAt,
          userId: profile.userId,
        ),
      );
    }
  }

  /// Filters out complex fields that are not columns in the Supabase schema
  Map<String, dynamic> _filterSupabaseJson(Map<String, dynamic> json) {
    final filtered = Map<String, dynamic>.from(json);
    // Remove fields that are not database columns
    filtered.remove('client');
    filtered.remove('vendor');
    filtered.remove('items');
    filtered.remove('isSynced');
    return filtered;
  }

  // --- Settings ---
  Future<SyncStats> _pushSettings(String userId) async {
    final stats = SyncStats();
    final box = Hive.box<BusinessProfile>('settings');
    if (box.isEmpty) return stats;

    final profile = box.get('profile'); // Use correct key
    if (profile != null && !profile.isSynced) {
      await _supabase
          .from('business_profiles')
          .upsert(
            _filterSupabaseJson({
              ...profile.toJson(),
              'user_id': userId,
              'updatedAt': DateTime.now().toIso8601String(),
            }),
            onConflict: 'user_id',
          );

      await box.put(
        'profile', // Use correct key
        BusinessProfile(
          companyName: profile.companyName,
          email: profile.email,
          phone: profile.phone,
          address: profile.address,
          taxId: profile.taxId,
          logoPath: profile.logoPath,
          currency: profile.currency,
          bankDetails: profile.bankDetails,
          website: profile.website,
          mobile: profile.mobile,
          isSynced: true, // Marked as synced
          updatedAt: DateTime.now(),
          userId: userId,
        ),
      );
      stats.pushed++;
    }
    return stats;
  }

  Future<SyncStats> _pullSettings(String userId, DateTime lastSync) async {
    final stats = SyncStats();
    final response = await _supabase
        .from('business_profiles')
        .select()
        .eq('user_id', userId)
        .gt('updatedAt', lastSync.toIso8601String());

    if (response.isNotEmpty) {
      final data = response.first;
      final profile = BusinessProfile.fromJson(data);
      final box = Hive.box<BusinessProfile>('settings');

      await box.put(
        'profile', // Use correct key
        BusinessProfile(
          companyName: profile.companyName,
          email: profile.email,
          phone: profile.phone,
          address: profile.address,
          taxId: profile.taxId,
          logoPath: profile.logoPath,
          currency: profile.currency,
          bankDetails: profile.bankDetails,
          website: profile.website,
          mobile: profile.mobile,
          isSynced: true,
          updatedAt: profile.updatedAt,
          userId: userId,
        ),
      );
      stats.pulled++;
    }
    return stats;
  }

  // --- Products ---
  Future<SyncStats> _pushProducts(String userId) async {
    final stats = SyncStats();
    final box = Hive.box<Product>('products');
    for (var key in box.keys) {
      final item = box.get(key);
      if (item != null && !item.isSynced) {
        await _supabase
            .from('products')
            .upsert(
              _filterSupabaseJson({
                ...item.toJson(),
                'user_id': userId,
                'updatedAt': DateTime.now().toIso8601String(),
              }),
            );

        await box.put(
          item.id, // Ensure consistent key usage
          Product(
            id: item.id,
            name: item.name,
            description: item.description,
            unitPrice: item.unitPrice,
            sku: item.sku,
            stockQuantity: item.stockQuantity,
            unit: item.unit,
            isSynced: true,
            updatedAt: DateTime.now(),
            userId: userId,
          ),
        );
        stats.pushed++;
      }
    }
    return stats;
  }

  Future<SyncStats> _pullProducts(String userId, DateTime lastSync) async {
    final stats = SyncStats();
    final response = await _supabase
        .from('products')
        .select()
        .eq('user_id', userId)
        .gt('updatedAt', lastSync.toIso8601String());

    final box = Hive.box<Product>('products');
    for (var data in response) {
      final product = Product.fromJson(data);

      final syncedProduct = Product(
        id: product.id,
        name: product.name,
        description: product.description,
        unitPrice: product.unitPrice,
        sku: product.sku,
        stockQuantity: product.stockQuantity,
        unit: product.unit,
        isSynced: true,
        updatedAt: product.updatedAt,
        userId: userId,
      );

      // Use ID as key, consistent with Repository
      await box.put(product.id, syncedProduct);
      stats.pulled++;
    }
    return stats;
  }

  // --- Clients ---
  Future<SyncStats> _pushClients(String userId) async {
    final stats = SyncStats();
    final box = Hive.box<Client>('clients');
    for (var key in box.keys) {
      final item = box.get(key);
      if (item != null && !item.isSynced) {
        await _supabase
            .from('clients')
            .upsert(
              _filterSupabaseJson({
                ...item.toJson(),
                'user_id': userId,
                'updatedAt': DateTime.now().toIso8601String(),
              }),
            );

        await box.put(
          item.id,
          Client(
            id: item.id,
            name: item.name,
            email: item.email,
            address: item.address,
            phone: item.phone,
            contactPerson: item.contactPerson,
            taxId: item.taxId,
            isSynced: true,
            updatedAt: DateTime.now(),
            userId: userId,
          ),
        );
        stats.pushed++;
      }
    }
    return stats;
  }

  Future<SyncStats> _pullClients(String userId, DateTime lastSync) async {
    final stats = SyncStats();
    final response = await _supabase
        .from('clients')
        .select()
        .eq('user_id', userId)
        .gt('updatedAt', lastSync.toIso8601String());

    final box = Hive.box<Client>('clients');
    for (var data in response) {
      final client = Client.fromJson(data);

      final syncedClient = Client(
        id: client.id,
        name: client.name,
        email: client.email,
        address: client.address,
        phone: client.phone,
        contactPerson: client.contactPerson,
        taxId: client.taxId,
        isSynced: true,
        updatedAt: client.updatedAt,
        userId: userId,
      );

      await box.put(client.id, syncedClient);
      stats.pulled++;
    }
    return stats;
  }

  // --- Invoices ---
  Future<SyncStats> _pushInvoices(String userId) async {
    final stats = SyncStats();
    final box = Hive.box<Invoice>('invoices');
    for (var key in box.keys) {
      final item = box.get(key);
      if (item != null && !item.isSynced) {
        await _supabase
            .from('invoices')
            .upsert(
              _filterSupabaseJson({
                ...item.toJson(),
                'user_id': userId,
                'updatedAt': DateTime.now().toIso8601String(),
              }),
            );

        await _supabase
            .from('invoice_items')
            .delete()
            .eq('invoice_id', item.id);

        final itemsData = item.items
            .map(
              (e) => {...e.toJson(), 'invoice_id': item.id, 'user_id': userId},
            )
            .toList();

        if (itemsData.isNotEmpty) {
          await _supabase.from('invoice_items').insert(itemsData);
        }

        await box.put(
          item.id,
          Invoice(
            id: item.id,
            invoiceNumber: item.invoiceNumber,
            date: item.date,
            dueDate: item.dueDate,
            client: item.client,
            items: item.items,
            subtotal: item.subtotal,
            taxAmount: item.taxAmount,
            discount: item.discount,
            total: item.total,
            status: item.status,
            notes: item.notes,
            terms: item.terms,
            termsAndConditions: item.termsAndConditions,
            salesPerson: item.salesPerson,
            isVatApplicable: item.isVatApplicable,
            currency: item.currency,
            placeOfSupply: item.placeOfSupply,
            deliveryNote: item.deliveryNote,
            paymentTerms: item.paymentTerms,
            supplierReference: item.supplierReference,
            otherReference: item.otherReference,
            buyersOrderNumber: item.buyersOrderNumber,
            buyersOrderDate: item.buyersOrderDate,
            isSynced: true,
            updatedAt: DateTime.now(),
            userId: userId,
          ),
        );
        stats.pushed++;
      }
    }
    return stats;
  }

  Future<SyncStats> _pullInvoices(String userId, DateTime lastSync) async {
    final stats = SyncStats();
    final response = await _supabase
        .from('invoices')
        .select('*, invoice_items(*), client:clients(*)')
        .eq('user_id', userId)
        .gt('updatedAt', lastSync.toIso8601String());

    final box = Hive.box<Invoice>('invoices');
    for (var data in response) {
      final fixedData = Map<String, dynamic>.from(data);
      if (fixedData['client'] != null) {
        fixedData['client'] = Map<String, dynamic>.from(fixedData['client']);
      }
      if (fixedData['invoice_items'] != null) {
        fixedData['items'] =
            fixedData['invoice_items']; // Map invoice_items to items
      }

      final invoice = Invoice.fromJson(fixedData);

      final syncedInvoice = Invoice(
        id: invoice.id,
        invoiceNumber: invoice.invoiceNumber,
        date: invoice.date,
        dueDate: invoice.dueDate,
        client: invoice.client,
        items: invoice.items,
        subtotal: invoice.subtotal,
        taxAmount: invoice.taxAmount,
        discount: invoice.discount,
        total: invoice.total,
        status: invoice.status,
        notes: invoice.notes,
        terms: invoice.terms,
        termsAndConditions: invoice.termsAndConditions,
        salesPerson: invoice.salesPerson,
        isVatApplicable: invoice.isVatApplicable,
        currency: invoice.currency,
        placeOfSupply: invoice.placeOfSupply,
        deliveryNote: invoice.deliveryNote,
        paymentTerms: invoice.paymentTerms,
        supplierReference: invoice.supplierReference,
        otherReference: invoice.otherReference,
        buyersOrderNumber: invoice.buyersOrderNumber,
        buyersOrderDate: invoice.buyersOrderDate,
        isSynced: true,
        updatedAt: invoice.updatedAt,
        userId: userId,
      );

      await box.put(invoice.id, syncedInvoice);
      stats.pulled++;
    }
    return stats;
  }

  // --- Quotations ---
  Future<SyncStats> _pushQuotations(String userId) async {
    final stats = SyncStats();
    final box = Hive.box<Quotation>('quotations');
    for (var key in box.keys) {
      final item = box.get(key);
      if (item != null && !item.isSynced) {
        try {
          await _supabase
              .from('quotations')
              .upsert(
                _filterSupabaseJson({
                  ...item.toJson(),
                  'user_id': userId,
                  'updatedAt': DateTime.now().toIso8601String(),
                }),
              )
              .select();

          await _supabase
              .from('quotation_items')
              .delete()
              .eq('quotation_id', item.id);

          final itemsData = item.items
              .map(
                (e) => {
                  ...e.toJson(),
                  'quotation_id': item.id,
                  'user_id': userId,
                },
              )
              .toList();

          if (itemsData.isNotEmpty) {
            await _supabase.from('quotation_items').insert(itemsData);
          }

          await box.put(
            item.id,
            Quotation(
              id: item.id,
              quotationNumber: item.quotationNumber,
              date: item.date,
              validUntil: item.validUntil,
              client: item.client,
              items: item.items,
              subtotal: item.subtotal,
              taxAmount: item.taxAmount,
              discount: item.discount,
              total: item.total,
              status: item.status,
              notes: item.notes,
              terms: item.terms,
              enquiryRef: item.enquiryRef,
              project: item.project,
              termsAndConditions: item.termsAndConditions,
              salesPerson: item.salesPerson,
              isVatApplicable: item.isVatApplicable,
              currency: item.currency,
              isSynced: true,
              updatedAt: DateTime.now(),
              userId: userId,
            ),
          );
          stats.pushed++;
        } catch (e) {
          throw 'Failed to sync quotation ${item.quotationNumber}: $e';
        }
      }
    }
    return stats;
  }

  Future<SyncStats> _pullQuotations(String userId, DateTime lastSync) async {
    final stats = SyncStats();
    final response = await _supabase
        .from('quotations')
        .select('*, quotation_items(*), client:clients(*)')
        .eq('user_id', userId)
        .gt('updatedAt', lastSync.toIso8601String());

    final box = Hive.box<Quotation>('quotations');
    for (var data in response) {
      final fixedData = Map<String, dynamic>.from(data);
      if (fixedData['client'] != null) {
        fixedData['client'] = Map<String, dynamic>.from(fixedData['client']);
      }
      if (fixedData['quotation_items'] != null) {
        fixedData['items'] = fixedData['quotation_items'];
      }
      final quotation = Quotation.fromJson(fixedData);

      final syncedQuotation = Quotation(
        id: quotation.id,
        quotationNumber: quotation.quotationNumber,
        date: quotation.date,
        validUntil: quotation.validUntil,
        client: quotation.client,
        items: quotation.items,
        subtotal: quotation.subtotal,
        taxAmount: quotation.taxAmount,
        discount: quotation.discount,
        total: quotation.total,
        status: quotation.status,
        notes: quotation.notes,
        terms: quotation.terms,
        enquiryRef: quotation.enquiryRef,
        project: quotation.project,
        termsAndConditions: quotation.termsAndConditions,
        salesPerson: quotation.salesPerson,
        isVatApplicable: quotation.isVatApplicable,
        currency: quotation.currency,
        isSynced: true,
        updatedAt: quotation.updatedAt,
        userId: userId,
      );

      await box.put(quotation.id, syncedQuotation);
      stats.pulled++;
    }
    return stats;
  }

  // --- LPOs ---
  Future<SyncStats> _pushLpos(String userId) async {
    final stats = SyncStats();
    final box = Hive.box<Lpo>('lpos');
    for (var key in box.keys) {
      final item = box.get(key);
      if (item != null && !item.isSynced) {
        await _supabase
            .from('lpos')
            .upsert(
              _filterSupabaseJson({
                ...item.toJson(),
                'user_id': userId,
                'updatedAt': DateTime.now().toIso8601String(),
              }),
            )
            .select();

        await _supabase.from('lpo_items').delete().eq('lpo_id', item.id);
        final itemsData = item.items
            .map((e) => {...e.toJson(), 'lpo_id': item.id, 'user_id': userId})
            .toList();

        if (itemsData.isNotEmpty) {
          await _supabase.from('lpo_items').insert(itemsData);
        }

        await box.put(
          item.id,
          Lpo(
            id: item.id,
            lpoNumber: item.lpoNumber,
            date: item.date,
            expectedDeliveryDate: item.expectedDeliveryDate,
            vendor: item.vendor,
            items: item.items,
            subtotal: item.subtotal,
            taxAmount: item.taxAmount,
            discount: item.discount,
            total: item.total,
            status: item.status,
            notes: item.notes,
            terms: item.terms,
            termsAndConditions: item.termsAndConditions,
            salesPerson: item.salesPerson,
            isVatApplicable: item.isVatApplicable,
            currency: item.currency,
            placeOfSupply: item.placeOfSupply,
            paymentTerms: item.paymentTerms,
            otherReference: item.otherReference,
            isSynced: true,
            updatedAt: DateTime.now(),
            userId: userId,
          ),
        );
        stats.pushed++;
      }
    }
    return stats;
  }

  Future<SyncStats> _pullLpos(String userId, DateTime lastSync) async {
    final stats = SyncStats();
    final response = await _supabase
        .from('lpos')
        .select('*, lpo_items(*), vendor:clients(*)')
        .eq('user_id', userId)
        .gt('updatedAt', lastSync.toIso8601String());
    final box = Hive.box<Lpo>('lpos');
    for (var data in response) {
      final fixedData = Map<String, dynamic>.from(data);
      if (fixedData['vendor'] != null) {
        fixedData['vendor'] = Map<String, dynamic>.from(fixedData['vendor']);
      }
      if (fixedData['lpo_items'] != null) {
        fixedData['items'] = fixedData['lpo_items'];
      }
      final lpo = Lpo.fromJson(fixedData);

      final syncedLpo = Lpo(
        id: lpo.id,
        lpoNumber: lpo.lpoNumber,
        date: lpo.date,
        expectedDeliveryDate: lpo.expectedDeliveryDate,
        vendor: lpo.vendor,
        items: lpo.items,
        subtotal: lpo.subtotal,
        taxAmount: lpo.taxAmount,
        discount: lpo.discount,
        total: lpo.total,
        status: lpo.status,
        notes: lpo.notes,
        terms: lpo.terms,
        termsAndConditions: lpo.termsAndConditions,
        salesPerson: lpo.salesPerson,
        isVatApplicable: lpo.isVatApplicable,
        currency: lpo.currency,
        placeOfSupply: lpo.placeOfSupply,
        paymentTerms: lpo.paymentTerms,
        otherReference: lpo.otherReference,
        isSynced: true,
        updatedAt: lpo.updatedAt,
        userId: userId,
      );

      await box.put(lpo.id, syncedLpo);
      stats.pulled++;
    }
    return stats;
  }

  // --- Proformas ---
  Future<SyncStats> _pushProformas(String userId) async {
    final stats = SyncStats();
    final box = Hive.box<ProformaInvoice>('proformas');
    for (var key in box.keys) {
      final item = box.get(key);
      if (item != null && !item.isSynced) {
        await _supabase
            .from('proformas')
            .upsert(
              _filterSupabaseJson({
                ...item.toJson(),
                'user_id': userId,
                'updatedAt': DateTime.now().toIso8601String(),
              }),
            );

        await _supabase
            .from('proforma_items')
            .delete()
            .eq('proforma_id', item.id);
        final itemsData = item.items
            .map(
              (e) => {...e.toJson(), 'proforma_id': item.id, 'user_id': userId},
            )
            .toList();

        if (itemsData.isNotEmpty) {
          await _supabase.from('proforma_items').insert(itemsData);
        }

        await box.put(
          item.id,
          ProformaInvoice(
            id: item.id,
            proformaNumber: item.proformaNumber,
            date: item.date,
            validUntil: item.validUntil,
            client: item.client,
            items: item.items,
            subtotal: item.subtotal,
            taxAmount: item.taxAmount,
            discount: item.discount,
            total: item.total,
            status: item.status,
            notes: item.notes,
            terms: item.terms,
            termsAndConditions: item.termsAndConditions,
            salesPerson: item.salesPerson,
            isVatApplicable: item.isVatApplicable,
            currency: item.currency,
            project: item.project,
            isSynced: true,
            updatedAt: DateTime.now(),
            userId: userId,
          ),
        );
        stats.pushed++;
      }
    }
    return stats;
  }

  Future<SyncStats> _pullProformas(String userId, DateTime lastSync) async {
    final stats = SyncStats();
    final response = await _supabase
        .from('proformas')
        .select('*, proforma_items(*), client:clients(*)')
        .eq('user_id', userId)
        .gt('updatedAt', lastSync.toIso8601String());

    final box = Hive.box<ProformaInvoice>('proformas');
    for (var data in response) {
      final fixedData = Map<String, dynamic>.from(data);
      if (fixedData['client'] != null) {
        fixedData['client'] = Map<String, dynamic>.from(fixedData['client']);
      }
      if (fixedData['proforma_items'] != null) {
        fixedData['items'] = fixedData['proforma_items'];
      }
      final proforma = ProformaInvoice.fromJson(fixedData);

      final syncedProforma = ProformaInvoice(
        id: proforma.id,
        proformaNumber: proforma.proformaNumber,
        date: proforma.date,
        validUntil: proforma.validUntil,
        client: proforma.client,
        items: proforma.items,
        subtotal: proforma.subtotal,
        taxAmount: proforma.taxAmount,
        discount: proforma.discount,
        total: proforma.total,
        status: proforma.status,
        notes: proforma.notes,
        terms: proforma.terms,
        termsAndConditions: proforma.termsAndConditions,
        salesPerson: proforma.salesPerson,
        isVatApplicable: proforma.isVatApplicable,
        currency: proforma.currency,
        project: proforma.project,
        isSynced: true,
        updatedAt: proforma.updatedAt,
        userId: userId,
      );

      await box.put(proforma.id, syncedProforma);
      stats.pulled++;
    }
    return stats;
  }
}
