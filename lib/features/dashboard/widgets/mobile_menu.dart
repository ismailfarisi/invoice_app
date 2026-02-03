import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_invoice_app/features/client/presentation/screens/client_list_screen.dart';
import 'package:flutter_invoice_app/features/lpo/presentation/screens/lpo_list_screen.dart';
import 'package:flutter_invoice_app/features/product/presentation/screens/product_list_screen.dart';
import 'package:flutter_invoice_app/features/proforma/presentation/screens/proforma_list_screen.dart';
import 'package:flutter_invoice_app/features/settings/presentation/screens/settings_screen.dart';

import 'package:flutter_invoice_app/features/invoice/presentation/screens/delivery_note_list_screen.dart';
import 'package:flutter_invoice_app/features/invoice/presentation/screens/letterhead_input_screen.dart';

class MobileMenu extends ConsumerWidget {
  const MobileMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      appBar: AppBar(
        title: const Text(
          'Menu',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _MenuTile(
              icon: Icons.people_outline,
              title: 'Clients',
              subtitle: 'Manage companies and contacts',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ClientListScreen()),
              ),
            ),
            const SizedBox(height: 16),
            _MenuTile(
              icon: Icons.inventory_2_outlined,
              title: 'Items',
              subtitle: 'Products and services inventory',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProductListScreen()),
              ),
            ),
            const SizedBox(height: 16),
            _MenuTile(
              icon: Icons.shopping_bag_outlined,
              title: 'Purchase Orders',
              subtitle: 'Manage local purchase orders (LPO)',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LpoListScreen()),
              ),
            ),
            const SizedBox(height: 16),
            _MenuTile(
              icon: Icons.assignment_outlined,
              title: 'Proforma Invoices',
              subtitle: 'Create and manage proforma invoices',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProformaListScreen()),
              ),
            ),
            const SizedBox(height: 16),
            _MenuTile(
              icon: Icons.local_shipping_outlined,
              title: 'Delivery Notes',
              subtitle: 'Generate delivery notes from invoices',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DeliveryNoteListScreen(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _MenuTile(
              icon: Icons.description_outlined,
              title: 'Letter Head',
              subtitle: 'Generate and download letterhead',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LetterHeadInputScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _MenuTile(
              icon: Icons.settings_outlined,
              title: 'Settings',
              subtitle: 'App preferences and configurations',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}
