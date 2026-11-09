import 'package:flutter/material.dart';
import 'package:flutter_invoice_app/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_invoice_app/features/settings/domain/models/business_profile.dart';
import 'package:flutter_invoice_app/features/settings/data/settings_repository.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_invoice_app/core/services/backup_service.dart';
import 'dart:convert';
import 'package:flutter_invoice_app/core/services/sync_service.dart';
import 'package:flutter_invoice_app/core/utils/file_utils.dart';
import 'package:file_picker/file_picker.dart';
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

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickJsonFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = FileUtils.getFileIfExists(result.files.single.path);
        if (file != null) {
          final content = await file.readAsString();
          // Validate JSON
          jsonDecode(content);
          if (!mounted) return;
          setState(() {
            _serviceAccountJson = content;
          });
        }
      }
    } catch (_) {
      _snack(
        'That file could not be used. Choose the .json key file you '
        'downloaded from Google Cloud.',
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final permanentPath = await FileUtils.saveLogoImage(pickedFile.path);
        if (!mounted) return;
        setState(() {
          _logoPath = permanentPath;
        });
      }
    } catch (_) {
      _snack('Could not load that picture. Try a different image.');
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      _snack('Please fix the highlighted fields.');
      return;
    }
    try {
      final repo = ref.read(businessProfileRepositoryProvider);
      final existing = repo.getProfile();
      final profile = BusinessProfile(
        companyName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        taxId: _taxIdController.text.trim(),
        bankDetails: _bankDetailsController.text.trim(),
        website: _websiteController.text.trim(),
        mobile: _mobileController.text.trim(),
        logoPath: _logoPath,
        currency: _selectedCurrency ?? 'AED',
        defaultVatRate: double.tryParse(_vatRateController.text.trim()) ?? 5.0,
        googleSheetsSyncEnabled: _syncEnabled,
        googleSheetsServiceAccountJson: _serviceAccountJson,
        googleSheetsSpreadsheetId: _spreadsheetId,
        // Fields the form does not show: keep what is stored.
        userId: existing?.userId,
        updatedAt: DateTime.now(),
      );

      await repo.saveProfile(profile);
      _snack('Settings saved');
    } catch (_) {
      _snack('Could not save your settings. Please try again.');
    }
  }

  Future<void> _exportData() async {
    try {
      await BackupService().exportData();
      _snack('Backup file created');
    } catch (_) {
      _snack(
        'Could not create the backup. Check free storage space and try again.',
      );
    }
  }

  Future<void> _importData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Backup?'),
        content: const Text(
          'This replaces everything on this phone (invoices, clients, products and settings) with the backup. This cannot be undone. Export a backup first if you are unsure.',
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
          _snack(
            'Could not import that backup. Choose a backup file made by this '
            'app and try again.',
          );
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
        label: const Text('Sign in to back up and sync'),
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
              child: Text(
                (user.email != null && user.email!.isNotEmpty)
                    ? user.email!.substring(0, 1).toUpperCase()
                    : '?',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.email ?? 'User',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Signed in',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Sign out',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Sign out?'),
                    content: const Text(
                      'Your invoices stay on this phone. Syncing stops until you sign in again.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Sign out'),
                      ),
                    ],
                  ),
                );
                if (confirm != true) return;
                try {
                  await ref.read(supabaseServiceProvider).signOut();
                } catch (_) {
                  _snack('Could not sign out. Check your connection and try again.');
                }
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
                    : () async {
                        try {
                          await ref.read(syncProvider.notifier).sync();
                        } catch (_) {
                          _snack('Sync failed. Check your connection and try again.');
                          return;
                        }
                        if (!mounted) return;
                        final current = ref.read(syncProvider);
                        final stats = current.value;
                        if (current is AsyncError) {
                          _snack('Sync failed. Check your connection and try again.');
                        } else if (stats != null) {
                          _snack(
                            'Sync done. Sent ${stats.pushed}, received ${stats.pulled}.',
                          );
                        } else {
                          _snack('Sync done.');
                        }
                      },
                icon: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
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
              'Last sync did not finish. Check your connection and tap Sync Now to try again.',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        if (syncState.hasValue && syncState.value != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Last sync: sent ${syncState.value!.pushed}, received ${syncState.value!.pulled}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Reset Sync Status?'),
                content: const Text(
                  'This will mark all items as not synced, forcing a re-upload on next sync. Use this if you have missing data in cloud.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Reset'),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              try {
                await ref.read(syncProvider.notifier).resetSync();
                _snack('Sync status reset. Tap Sync Now to upload everything again.');
              } catch (_) {
                _snack('Could not reset the sync status. Please try again.');
              }
            }
          },
          icon: const Icon(Icons.refresh),
          label: const Text('Re-upload everything (troubleshooting)'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            foregroundColor: Theme.of(context).colorScheme.secondary,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.pageWash,
      appBar: AppBar(
        title: const Text(
          'Business Settings',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Center(
                    child: Builder(
                      builder: (context) {
                        final logoFile = FileUtils.getFileIfExists(_logoPath);
                        return Semantics(
                          button: true,
                          label: logoFile == null
                              ? 'Add company logo'
                              : 'Change company logo',
                          child: Material(
                            color: Theme.of(context).colorScheme.surface,
                            shape: const CircleBorder(),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: _pickImage,
                              child: SizedBox(
                                width: 100,
                                height: 100,
                                child: logoFile != null
                                    ? Image.file(
                                        logoFile,
                                        fit: BoxFit.cover,
                                        excludeFromSemantics: true,
                                        errorBuilder: (_, _, _) => Icon(
                                          Icons.add_a_photo,
                                          size: 40,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                      )
                                    : Icon(
                                        Icons.add_a_photo,
                                        size: 40,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Company logo (shown on your documents)',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        validator: (val) => val == null || val.trim().isEmpty
                            ? 'Enter your company name'
                            : null,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Company Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Company Phone',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _mobileController,
                        decoration: const InputDecoration(
                          labelText: 'Company Mobile',
                          prefixIcon: Icon(Icons.smartphone),
                        ),
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _websiteController,
                        decoration: const InputDecoration(
                          labelText: 'Website',
                          prefixIcon: Icon(Icons.language),
                        ),
                        keyboardType: TextInputType.url,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Address',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                        maxLines: 2,
                        keyboardType: TextInputType.streetAddress,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _taxIdController,
                        decoration: const InputDecoration(
                          labelText: 'Tax Registration Number (TRN)',
                          prefixIcon: Icon(Icons.tag),
                        ),
                        textInputAction: TextInputAction.next,
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
                          labelText: 'Bank Details (printed on invoices)',
                          hintText:
                              'Bank Name: XYZ\nAccount: 123456789\nIBAN: AE00 0000 0000 0000 0000 000',
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
                          final v = val?.trim() ?? '';
                          if (v.isEmpty) return 'Enter a VAT rate, like 5';
                          final n = double.tryParse(v);
                          if (n == null || n < 0 || n > 100) {
                            return 'Enter a number from 0 to 100';
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
                        items:
                            [
                                  'AED',
                                  'USD',
                                  'EUR',
                                  'GBP',
                                  'INR',
                                  'SAR',
                                  'QAR',
                                  if (_selectedCurrency != null &&
                                      !const [
                                        'AED',
                                        'USD',
                                        'EUR',
                                        'GBP',
                                        'INR',
                                        'SAR',
                                        'QAR',
                                      ].contains(_selectedCurrency))
                                    _selectedCurrency!,
                                ]
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
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            'Key file added. Tap Save Settings to keep it.',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
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
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      if (_syncEnabled && _serviceAccountJson != null)
                        FilledButton.icon(
                          onPressed: () async {
                            try {
                              await ref.read(syncServiceProvider).syncAll();
                              _snack('Sent to Google Sheets');
                            } catch (_) {
                              _snack(
                                'Could not reach Google Sheets. Check your connection and the key file, then try again.',
                              );
                            }
                          },
                          icon: const Icon(Icons.sync),
                          label: const Text('Send to Google Sheets now'),
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
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
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
