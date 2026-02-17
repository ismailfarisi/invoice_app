import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_invoice_app/features/settings/domain/models/business_profile.dart';
import 'package:flutter_invoice_app/features/settings/data/settings_repository.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_invoice_app/core/services/backup_service.dart';
import 'package:flutter_invoice_app/core/services/supabase_service.dart';
import 'package:flutter_invoice_app/features/auth/presentation/screens/auth_screen.dart';
import 'package:flutter_invoice_app/features/sync/presentation/providers/sync_provider.dart';
import 'package:flutter_invoice_app/features/auth/presentation/providers/auth_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _taxIdController;
  late TextEditingController _bankDetailsController;
  late TextEditingController _websiteController;
  late TextEditingController _mobileController;
  String? _logoPath;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(businessProfileRepositoryProvider).getProfile();
    _nameController = TextEditingController(text: profile?.companyName ?? '');
    _emailController = TextEditingController(text: profile?.email ?? '');
    _phoneController = TextEditingController(text: profile?.phone ?? '');
    _addressController = TextEditingController(text: profile?.address ?? '');
    _taxIdController = TextEditingController(text: profile?.taxId ?? '');
    _bankDetailsController = TextEditingController(
      text: profile?.bankDetails ?? '',
    );
    _websiteController = TextEditingController(text: profile?.website ?? '');
    _mobileController = TextEditingController(text: profile?.mobile ?? '');
    _logoPath = profile?.logoPath;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _logoPath = pickedFile.path;
      });
    }
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final profile = BusinessProfile(
        companyName: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        address: _addressController.text,
        taxId: _taxIdController.text,
        bankDetails: _bankDetailsController.text,
        website: _websiteController.text,
        mobile: _mobileController.text,
        logoPath: _logoPath,
      );

      ref.read(businessProfileRepositoryProvider).saveProfile(profile);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully')),
      );
    }
  }

  Future<void> _exportData() async {
    try {
      await BackupService().exportData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data exported successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  Future<void> _importData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Backup?'),
        content: const Text(
          'This will overwrite all current data with the backup data. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Import & Overwrite'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await BackupService().importData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data imported successfully.')),
          );
          // Refresh profile data in UI
          final profile = ref
              .read(businessProfileRepositoryProvider)
              .getProfile();
          setState(() {
            _nameController.text = profile?.companyName ?? '';
            _emailController.text = profile?.email ?? '';
            _phoneController.text = profile?.phone ?? '';
            _addressController.text = profile?.address ?? '';
            _taxIdController.text = profile?.taxId ?? '';
            _bankDetailsController.text = profile?.bankDetails ?? '';
            _websiteController.text = profile?.website ?? '';
            _mobileController.text = profile?.mobile ?? '';
            _logoPath = profile?.logoPath;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Import failed: $e')));
        }
      }
    }
  }

  Widget _buildAuthSection(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider);
    final user = userState.value;
    final syncState = ref.watch(syncProvider);
    final isLoading = syncState is AsyncLoading;

    if (user == null) {
      return FilledButton.icon(
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (context) => const AuthScreen()));
        },
        icon: const Icon(Icons.login),
        label: const Text('Login / Register to Sync'),
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              child: Text(user.email!.substring(0, 1).toUpperCase()),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.email ?? 'User',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Logged in',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await ref.read(supabaseServiceProvider).signOut();
              },
            ),
          ],
        ),
        const Divider(height: 32),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: isLoading
                    ? null
                    : () {
                        ref.read(syncProvider.notifier).sync().then((_) {
                          if (mounted &&
                              ref.read(syncProvider) is! AsyncError) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Sync Completed!')),
                            );
                          }
                        });
                      },
                icon: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.sync),
                label: Text(isLoading ? 'Syncing...' : 'Sync Now'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),
          ],
        ),
        if (syncState is AsyncError)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Sync Error: ${syncState.error}',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      appBar: AppBar(
        title: const Text(
          'Business Settings',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        backgroundImage: _logoPath != null
                            ? FileImage(File(_logoPath!))
                            : null,
                        child: _logoPath == null
                            ? Icon(
                                Icons.add_a_photo,
                                size: 40,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _SettingsSection(
                    title: 'Company Profile',
                    icon: Icons.business_outlined,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Company Name',
                          prefixIcon: Icon(Icons.business),
                        ),
                        validator: (val) =>
                            val == null || val.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Company Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Company Phone',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _mobileController,
                        decoration: const InputDecoration(
                          labelText: 'Company Mobile',
                          prefixIcon: Icon(Icons.smartphone),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _websiteController,
                        decoration: const InputDecoration(
                          labelText: 'Website',
                          prefixIcon: Icon(Icons.language),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Address',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _taxIdController,
                        decoration: const InputDecoration(
                          labelText: 'Tax ID / VAT Number',
                          prefixIcon: Icon(Icons.tag),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _SettingsSection(
                    title: 'Payment Information',
                    icon: Icons.payments_outlined,
                    children: [
                      TextFormField(
                        controller: _bankDetailsController,
                        decoration: const InputDecoration(
                          labelText: 'Bank Details (for PDF)',
                          hintText:
                              'Bank Name: XYZ\nAccount: 123456789\nIFSC: ABCD0123',
                          prefixIcon: Icon(Icons.account_balance_outlined),
                        ),
                        maxLines: 4,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _SettingsSection(
                    title: 'Cloud Sync & Backup',
                    icon: Icons.cloud_sync_outlined,
                    children: [_buildAuthSection(context, ref)],
                  ),
                  const SizedBox(height: 24),
                  _SettingsSection(
                    title: 'Data Management',
                    icon: Icons.storage_outlined,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _exportData,
                        icon: const Icon(Icons.download),
                        label: const Text('Export Data Backup'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _importData,
                        icon: const Icon(Icons.upload),
                        label: const Text('Import Data Backup'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          foregroundColor: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  FilledButton(
                    onPressed: _save,
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'Save Settings',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SettingsSection({
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
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color:
                Theme.of(context).cardTheme.color ??
                Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: 0.2),
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}
