import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_invoice_app/features/invoice/domain/models/invoice.dart';

final clientRepositoryProvider = Provider((ref) => ClientRepository());

class ClientRepository {
  final Box<Client> _box = Hive.box<Client>('clients');

  List<Client> getAllClients() {
    return _box.values.toList();
  }

  Client? getClient(String id) {
    return _box.get(id);
  }

  Future<void> saveClient(Client client) async {
    await _box.put(client.id, client);
  }

  Future<void> deleteClient(String id) async {
    await _box.delete(id);
  }
}
