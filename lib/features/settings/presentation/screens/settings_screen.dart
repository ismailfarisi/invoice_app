import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_invoice_app/features/settings/domain/models/business_profile.dart';
import 'package:flutter_invoice_app/features/settings/data/settings_repository.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_invoice_app/core/services/backup_service.dart';
import 'dart:convert';
import 'package:flutter_invoice_app/core/services/sync_service.dart';
import 'package:flutter_invoice_app/core/utils/file_utils.dart';
import 'package:file_picker/file_picker.dart';

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
  late TextEditingController _vatRateController;
  String? _selectedCurrency;
  String? _logoPath;
  bool _syncEnabled = false;
  String? _serviceAccountJson;
  String? _spreadsheetId;

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
    _vatRateController = TextEditingController(
      text: (profile?.defaultVatRate ?? 5.0).toString(),
    );
    _selectedCurrency = profile?.currency ?? 'AED';
    _logoPath = profile?.logoPath;
    _syncEnabled = profile?.googleSheetsSyncEnabled ?? false;
    _serviceAccountJson = profile?.googleSheetsServiceAccountJson;
    _spreadsheetId = profile?.googleSheetsSpreadsheetId;
  }

  Future<void> _pickJsonFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null && result.files.single.path != null) {
      final file = FileUtils.getFileIfExists(result.files.single.path);
      if (file != null) {
        final content = await file.readAsString();
        try {
          // Validate JSON
          jsonDecode(content);
          setState(() {
            _serviceAccountJson = content;
          });
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Invalid JSON file')));
          }
        }
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final permanentPath = await FileUtils.saveLogoImage(pickedFile.path);
      setState(() {
        _logoPath = permanentPath;
      });
    }
  }

  Future<void> _save() async {
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
        currency: _selectedCurrency ?? 'AED',
        defaultVatRate: double.tryParse(_vatRateController.text) ?? 5.0,
        googleSheetsSyncEnabled: _syncEnabled,
        googleSheetsServiceAccountJson: _serviceAccountJson,
        googleSheetsSpreadsheetId: _spreadsheetId,
      );

      await ref.read(businessProfileRepositoryProvider).saveProfile(profile);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully')),
        );
      }
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
            _vatRateController.text = (profile?.defaultVatRate ?? 5.0)
                .toString();
            _selectedCurrency = profile?.currency ?? 'AED';
            _logoPath = profile?.logoPath;
            _syncEnabled = profile?.googleSheetsSyncEnabled ?? false;
            _serviceAccountJson = profile?.googleSheetsServiceAccountJson;
            _spreadsheetId = profile?.googleSheetsSpreadsheetId;
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
                      child: Builder(
                        builder: (context) {
                          final logoFile = FileUtils.getFileIfExists(_logoPath);
                          return CircleAvatar(
                            radius: 50,
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.surface,
                            backgroundImage: logoFile != null
                                ? FileImage(logoFile)
                                : null,
                            child: logoFile == null
                                ? Icon(
                                    Icons.add_a_photo,
                                    size: 40,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  )
                                : null,
                          );
                        },
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
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _vatRateController,
                        decoration: const InputDecoration(
                          labelText: 'Default VAT Rate (%)',
                          prefixIcon: Icon(Icons.percent),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Required';
                          if (double.tryParse(val) == null) {
                            return 'Enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        value: _selectedCurrency,
                        decoration: const InputDecoration(
                          labelText: 'Currency',
                          prefixIcon: Icon(Icons.monetization_on_outlined),
                        ),
                        items: ['AED', 'USD', 'EUR', 'GBP', 'INR', 'SAR', 'QAR']
                            .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedCurrency = val;
                            });
                          }
                        },
                      ),
                    ],
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
                  const SizedBox(height: 24),
                  _SettingsSection(
                    title: 'Google Sheets Sync',
                    icon: Icons.sync,
                    children: [
                      SwitchListTile(
                        title: const Text('Enable Automated Sync'),
                        subtitle: const Text(
                          'Sync data to Google Sheets automatically',
                        ),
                        value: _syncEnabled,
                        onChanged: (val) {
                          setState(() {
                            _syncEnabled = val;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _pickJsonFile,
                        icon: const Icon(Icons.key),
                        label: Text(
                          _serviceAccountJson == null
                              ? 'Upload Service Account JSON'
                              : 'Service Account JSON Uploaded',
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                      if (_serviceAccountJson != null) ...[
                        const SizedBox(height: 12),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            'Status: Active',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      if (_spreadsheetId != null) ...[
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            'Spreadsheet ID: $_spreadsheetId',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      if (_syncEnabled && _serviceAccountJson != null)
                        FilledButton.icon(
                          onPressed: () async {
                            await ref.read(syncServiceProvider).syncAll();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Sync triggered successfully'),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.sync),
                          label: const Text('Sync Now'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
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
