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

class SyncRepository {
  final SupabaseClient _supabase;

  SyncRepository(this._supabase);

  Future<void> syncAll() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    // 1. Push Local Changes
    await _pushSettings(user.id);
    await _pushProducts(user.id);
    await _pushClients(user.id);
    await _pushInvoices(user.id);
    await _pushQuotations(user.id);
    await _pushLpos(user.id);
    await _pushProformas(user.id);

    // 2. Pull Remote Changes
    final lastSyncKey = 'last_sync_${user.id}';
    final box = await Hive.openBox('sync_meta');
    final lastSyncStr = box.get(lastSyncKey);
    final lastSync = lastSyncStr != null
        ? DateTime.parse(lastSyncStr)
        : DateTime.fromMillisecondsSinceEpoch(0);

    await _pullSettings(user.id, lastSync);
    await _pullProducts(user.id, lastSync);
    await _pullClients(user.id, lastSync);
    await _pullInvoices(user.id, lastSync);
    await _pullQuotations(user.id, lastSync);
    await _pullLpos(user.id, lastSync);
    await _pullProformas(user.id, lastSync);

    // 3. Update Last Sync Time
    await box.put(lastSyncKey, DateTime.now().toIso8601String());
  }

  // --- Settings ---
  Future<void> _pushSettings(String userId) async {
    final box = Hive.box<BusinessProfile>('settings');
    if (box.isEmpty) return;

    final profile = box.get('profile'); // Use correct key
    if (profile != null && !profile.isSynced) {
      await _supabase.from('business_profiles').upsert({
        ...profile.toJson(),
        'user_id': userId,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');

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
    }
  }

  Future<void> _pullSettings(String userId, DateTime lastSync) async {
    final response = await _supabase
        .from('business_profiles')
        .select()
        .eq('user_id', userId)
        .gt('updated_at', lastSync.toIso8601String());

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
    }
  }

  // --- Products ---
  Future<void> _pushProducts(String userId) async {
    final box = Hive.box<Product>('products');
    for (var key in box.keys) {
      final item = box.get(key);
      if (item != null && !item.isSynced) {
        await _supabase.from('products').upsert({
          ...item.toJson(),
          'user_id': userId,
          'updated_at': DateTime.now().toIso8601String(),
        });

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
      }
    }
  }

  Future<void> _pullProducts(String userId, DateTime lastSync) async {
    final response = await _supabase
        .from('products')
        .select()
        .eq('user_id', userId)
        .gt('updated_at', lastSync.toIso8601String());

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
    }
  }

  // --- Clients ---
  Future<void> _pushClients(String userId) async {
    final box = Hive.box<Client>('clients');
    for (var key in box.keys) {
      final item = box.get(key);
      if (item != null && !item.isSynced) {
        await _supabase.from('clients').upsert({
          ...item.toJson(),
          'user_id': userId,
          'updated_at': DateTime.now().toIso8601String(),
        });

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
      }
    }
  }

  Future<void> _pullClients(String userId, DateTime lastSync) async {
    final response = await _supabase
        .from('clients')
        .select()
        .eq('user_id', userId)
        .gt('updated_at', lastSync.toIso8601String());

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
    }
  }

  // --- Invoices ---
  Future<void> _pushInvoices(String userId) async {
    final box = Hive.box<Invoice>('invoices');
    for (var key in box.keys) {
      final item = box.get(key);
      if (item != null && !item.isSynced) {
        await _supabase.from('invoices').upsert({
          ...item.toJson(),
          'user_id': userId,
          'updated_at': DateTime.now().toIso8601String(),
        });

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
      }
    }
  }

  Future<void> _pullInvoices(String userId, DateTime lastSync) async {
    final response = await _supabase
        .from('invoices')
        .select(
          '*, invoice_items(*), client:clients(*)',
        ) // Join items and client
        .eq('user_id', userId)
        .gt('updated_at', lastSync.toIso8601String());

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
    }
  }

  // --- Quotations ---
  Future<void> _pushQuotations(String userId) async {
    final box = Hive.box<Quotation>('quotations');
    for (var key in box.keys) {
      final item = box.get(key);
      if (item != null && !item.isSynced) {
        await _supabase.from('quotations').upsert({
          ...item.toJson(),
          'user_id': userId,
          'updated_at': DateTime.now().toIso8601String(),
        });

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
      }
    }
  }

  Future<void> _pullQuotations(String userId, DateTime lastSync) async {
    final response = await _supabase
        .from('quotations')
        .select('*, quotation_items(*), client:clients(*)')
        .eq('user_id', userId)
        .gt('updated_at', lastSync.toIso8601String());

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
    }
  }

  // --- LPOs ---
  Future<void> _pushLpos(String userId) async {
    final box = Hive.box<Lpo>('lpos');
    for (var key in box.keys) {
      final item = box.get(key);
      if (item != null && !item.isSynced) {
        await _supabase.from('lpos').upsert({
          ...item.toJson(),
          'user_id': userId,
          'updated_at': DateTime.now().toIso8601String(),
        });

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
      }
    }
  }

  Future<void> _pullLpos(String userId, DateTime lastSync) async {
    final response = await _supabase
        .from('lpos')
        .select('*, lpo_items(*), vendor:clients(*)')
        .eq('user_id', userId)
        .gt('updated_at', lastSync.toIso8601String());

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
    }
  }

  // --- Proformas ---
  Future<void> _pushProformas(String userId) async {
    final box = Hive.box<ProformaInvoice>('proformas');
    for (var key in box.keys) {
      final item = box.get(key);
      if (item != null && !item.isSynced) {
        await _supabase.from('proformas').upsert({
          ...item.toJson(),
          'user_id': userId,
          'updated_at': DateTime.now().toIso8601String(),
        });

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
      }
    }
  }

  Future<void> _pullProformas(String userId, DateTime lastSync) async {
    final response = await _supabase
        .from('proformas')
        .select('*, proforma_items(*), client:clients(*)')
        .eq('user_id', userId)
        .gt('updated_at', lastSync.toIso8601String());

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
    }
  }
}
