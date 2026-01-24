import 'package:flutter/material.dart';
import 'package:flutter_invoice_app/features/invoice/presentation/screens/invoice_list_screen.dart';
import 'package:flutter_invoice_app/features/invoice/presentation/screens/invoice_form_screen.dart';
import 'package:flutter_invoice_app/features/quotation/presentation/screens/quotation_list_screen.dart';
import 'package:flutter_invoice_app/features/quotation/presentation/screens/quotation_form_screen.dart';
import 'package:flutter_invoice_app/features/client/presentation/screens/client_list_screen.dart';
import 'package:flutter_invoice_app/features/product/presentation/screens/product_list_screen.dart';
import 'package:flutter_invoice_app/features/lpo/presentation/screens/lpo_list_screen.dart';
import 'package:flutter_invoice_app/features/proforma/presentation/screens/proforma_list_screen.dart'; // Add import
import 'package:flutter_invoice_app/features/settings/presentation/screens/settings_screen.dart';
import 'package:flutter_invoice_app/features/dashboard/widgets/dashboard_overview.dart';
import 'package:flutter_invoice_app/features/dashboard/widgets/mobile_menu.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Desktop check using shortestSide for robustness
    final isDesktop = MediaQuery.of(context).size.shortestSide >= 600;

    // Pages list remains same for consistency / desktop mapping
    final List<Widget> pages = [
      const DashboardOverview(),
      const InvoiceListScreen(),
      const QuotationListScreen(),
      const ClientListScreen(),
      const ProductListScreen(),
      const LpoListScreen(),
      const ProformaListScreen(), // Add Proforma Screen
      const SettingsScreen(),
    ];

    // On mobile, if index is > 2, we treat it as the "Menu" tab (index 3)
    final int effectiveMobileIndex = _selectedIndex > 3 ? 3 : _selectedIndex;
    final int displayedIndex = isDesktop
        ? _selectedIndex
        : effectiveMobileIndex;

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            if (isDesktop)
              _Sidebar(
                selectedIndex: _selectedIndex,
                onItemSelected: (index) =>
                    setState(() => _selectedIndex = index),
              ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: isDesktop
                      ? const BorderRadius.only(
                          topLeft: Radius.circular(32),
                          bottomLeft: Radius.circular(32),
                        )
                      : null,
                ),
                clipBehavior: Clip.antiAlias,
                child: isDesktop
                    ? pages[_selectedIndex]
                    : (_selectedIndex > 2
                          ? const MobileMenu()
                          : pages[_selectedIndex]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isDesktop
          ? null
          : NavigationBar(
              selectedIndex: displayedIndex,
              onDestinationSelected: (index) =>
                  setState(() => _selectedIndex = index),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long),
                  label: 'Invoices',
                ),
                NavigationDestination(
                  icon: Icon(Icons.request_quote_outlined),
                  selectedIcon: Icon(Icons.request_quote),
                  label: 'Quotes',
                ),
                NavigationDestination(icon: Icon(Icons.menu), label: 'Menu'),
              ],
            ),
      floatingActionButton: _selectedIndex == 1 || _selectedIndex == 2
          ? FloatingActionButton.extended(
              onPressed: () {
                if (_selectedIndex == 1) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const InvoiceFormScreen(),
                    ),
                  );
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const QuotationFormScreen(),
                    ),
                  );
                }
              },
              label: Text(
                _selectedIndex == 1 ? 'New Invoice' : 'New Quotation',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              icon: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class _Sidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const _Sidebar({required this.selectedIndex, required this.onItemSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.bolt, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 48),
          _SidebarItem(
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard,
            label: 'Home',
            isSelected: selectedIndex == 0,
            onTap: () => onItemSelected(0),
          ),
          _SidebarItem(
            icon: Icons.receipt_long_outlined,
            selectedIcon: Icons.receipt_long,
            label: 'Invoices',
            isSelected: selectedIndex == 1,
            onTap: () => onItemSelected(1),
          ),
          _SidebarItem(
            icon: Icons.request_quote_outlined,
            selectedIcon: Icons.request_quote,
            label: 'Quotes',
            isSelected: selectedIndex == 2,
            onTap: () => onItemSelected(2),
          ),
          _SidebarItem(
            icon: Icons.people_outline,
            selectedIcon: Icons.people,
            label: 'Clients',
            isSelected: selectedIndex == 3,
            onTap: () => onItemSelected(3),
          ),
          _SidebarItem(
            icon: Icons.inventory_2_outlined,
            selectedIcon: Icons.inventory_2,
            label: 'Items',
            isSelected: selectedIndex == 4,
            onTap: () => onItemSelected(4),
          ),
          _SidebarItem(
            icon: Icons.shopping_bag_outlined,
            selectedIcon: Icons.shopping_bag,
            label: 'LPO',
            isSelected: selectedIndex == 5,
            onTap: () => onItemSelected(5),
          ),
          _SidebarItem(
            icon: Icons.assignment_outlined,
            selectedIcon: Icons.assignment,
            label: 'Proforma',
            isSelected: selectedIndex == 6,
            onTap: () => onItemSelected(6),
          ),
          const Spacer(),
          _SidebarItem(
            icon: Icons.settings_outlined,
            selectedIcon: Icons.settings,
            label: 'Settings',
            isSelected: selectedIndex == 7, // Update index
            onTap: () => onItemSelected(7),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Icon(
              isSelected ? selectedIcon : icon,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey.shade500,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade500,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
