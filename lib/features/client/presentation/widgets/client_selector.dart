import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_invoice_app/features/invoice/domain/models/invoice.dart'; // Client model

class ClientSelector extends StatelessWidget {
  final Client? selectedClient;
  final ValueChanged<Client?> onChanged;

  const ClientSelector({
    super.key,
    required this.selectedClient,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Client>('clients').listenable(),
      builder: (context, Box<Client> box, _) {
        final clients = box.values.toList();
        if (clients.isEmpty) {
          return ListTile(
            title: const Text('No companies available'),
            trailing: TextButton(
              onPressed: () {
                // Implementation for adding company
              },
              child: const Text('Add Company First'),
            ),
          );
        }

        return DropdownButtonFormField<Client>(
          initialValue:
              selectedClient != null &&
                  clients.any((c) => c.id == selectedClient!.id)
              ? clients.firstWhere((c) => c.id == selectedClient!.id)
              : null,
          decoration: const InputDecoration(labelText: 'Select Company'),
          items: clients.map((client) {
            return DropdownMenuItem(value: client, child: Text(client.name));
          }).toList(),
          onChanged: onChanged,
          validator: (val) => val == null ? 'Please select a company' : null,
        );
      },
    );
  }
}
