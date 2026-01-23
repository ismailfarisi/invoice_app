import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_invoice_app/features/invoice/domain/models/invoice.dart'; // Client model is here
import 'package:flutter_invoice_app/features/client/data/client_repository.dart';
import 'package:uuid/uuid.dart';

class ClientFormScreen extends ConsumerStatefulWidget {
  final Client? client;
  const ClientFormScreen({super.key, this.client});

  @override
  ConsumerState<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends ConsumerState<ClientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _contactPersonController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _taxIdController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.client?.name ?? '');
    _contactPersonController = TextEditingController(
      text: widget.client?.contactPerson ?? '',
    );
    _emailController = TextEditingController(text: widget.client?.email ?? '');
    _addressController = TextEditingController(
      text: widget.client?.address ?? '',
    );
    _phoneController = TextEditingController(text: widget.client?.phone ?? '');
    _taxIdController = TextEditingController(text: widget.client?.taxId ?? '');
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final client = Client(
        id: widget.client?.id ?? const Uuid().v4(),
        name: _nameController.text,
        contactPerson: _contactPersonController.text.isEmpty
            ? null
            : _contactPersonController.text,
        email: _emailController.text,
        address: _addressController.text.isEmpty
            ? null
            : _addressController.text,
        phone: _phoneController.text.isEmpty ? null : _phoneController.text,
        taxId: _taxIdController.text.isEmpty ? null : _taxIdController.text,
      );

      ref.read(clientRepositoryProvider).saveClient(client);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      appBar: AppBar(
        title: Text(
          widget.client == null ? 'New Company' : 'Edit Company',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined, size: 20),
              label: const Text('Save'),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _FormSection(
              title: 'Basic Information',
              icon: Icons.business_outlined,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Company Name',
                    prefixIcon: Icon(Icons.business),
                    hintText: 'Enter company name',
                  ),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _taxIdController,
                  decoration: const InputDecoration(
                    labelText: 'Tax ID / VAT',
                    prefixIcon: Icon(Icons.tag),
                    hintText: 'Optional',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _FormSection(
              title: 'Contact Details',
              icon: Icons.contact_mail_outlined,
              children: [
                TextFormField(
                  controller: _contactPersonController,
                  decoration: const InputDecoration(
                    labelText: 'Contact Person',
                    prefixIcon: Icon(Icons.person_outline),
                    hintText: 'John Doe',
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                    hintText: 'company@example.com',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _FormSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}
