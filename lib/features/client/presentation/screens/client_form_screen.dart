import 'package:flutter/material.dart';
import 'package:flutter_invoice_app/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_invoice_app/features/invoice/domain/models/invoice.dart'; // Client model is here
import 'package:flutter_invoice_app/features/client/data/client_repository.dart';
import 'package:flutter_invoice_app/core/presentation/widgets/form/form_section.dart';
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

  bool _saving = false;

  String? _orNull(TextEditingController c) {
    final v = c.text.trim();
    return v.isEmpty ? null : v;
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    final existing = widget.client;
    final client = Client(
      id: existing?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      contactPerson: _orNull(_contactPersonController),
      email: _emailController.text.trim(),
      address: _orNull(_addressController),
      phone: _orNull(_phoneController),
      taxId: _orNull(_taxIdController),
      // Carry over fields the form doesn't show.
      userId: existing?.userId,
      updatedAt: existing?.updatedAt,
    );

    setState(() => _saving = true);
    try {
      await ref.read(clientRepositoryProvider).saveClient(client);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('Failed to save company: $e');
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save the company. Try again.')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactPersonController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _taxIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.pageWash,
      appBar: AppBar(
        title: Text(
          widget.client == null ? 'New Company' : 'Edit Company',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save_outlined, size: 20),
              label: const Text('Save'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 0,
                ),
                children: [
                  FormSection(
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
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        validator: (val) => val == null || val.trim().isEmpty
                            ? 'Enter the company name'
                            : null,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _taxIdController,
                        decoration: const InputDecoration(
                          labelText: 'Tax Registration No. (TRN)',
                          prefixIcon: Icon(Icons.tag),
                          hintText: 'Optional',
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  FormSection(
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
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
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
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        validator: (val) {
                          final v = val?.trim() ?? '';
                          if (v.isEmpty) return 'Enter an email address';
                          if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                              .hasMatch(v)) {
                            return 'Enter a valid email, like name@company.com';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Address',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 3,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
