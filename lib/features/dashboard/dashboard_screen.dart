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
import 'package:flutter_invoice_app/features/invoice/presentation/screens/delivery_note_list_screen.dart';
import 'package:flutter_invoice_app/features/invoice/presentation/screens/letterhead_input_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  late List<GlobalKey<NavigatorState>> _navigatorKeys;

  @override
  void initState() {
    super.initState();
    // Initialize exactly as many keys as there are total pages (defined by _pages.length)
    _navigatorKeys = List.generate(10, (index) => GlobalKey<NavigatorState>());
  }

  List<Widget> get _pages => [
    const DashboardOverview(),
    const InvoiceListScreen(),
    const QuotationListScreen(),
    const ClientListScreen(),
    const ProductListScreen(),
    const LpoListScreen(),
    const ProformaListScreen(),
    const DeliveryNoteListScreen(),
    const LetterHeadInputScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Desktop check using shortestSide for robustness
    final isDesktop = MediaQuery.of(context).size.shortestSide >= 600;

    // Safety check for index
    final pages = _pages;
    final int safeIndex = _selectedIndex < pages.length ? _selectedIndex : 0;

    // On mobile, if index is > 2, we treat it as the "Menu" tab (index 3)
    final int effectiveMobileIndex = safeIndex > 3 ? 3 : safeIndex;
    final int displayedIndex = isDesktop ? safeIndex : effectiveMobileIndex;

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            if (isDesktop)
              _Sidebar(
                selectedIndex: safeIndex,
                onItemSelected: (index) {
                  setState(() => _selectedIndex = index);
                  // We don't necessarily want to popUntil here if we want to preserve state,
                  // but we can if the user expects a fresh tab on click.
                  // For now, let's keep it to preserve state (don't pop).
                },
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
                    ? IndexedStack(
                        index: safeIndex,
                        children: List.generate(
                          pages.length,
                          (index) => Navigator(
                            key: _navigatorKeys[index],
                            onGenerateRoute: (settings) {
                              return MaterialPageRoute(
                                builder: (_) => pages[index],
                                settings: settings,
                              );
                            },
                          ),
                        ),
                      )
                    : (safeIndex > 2 ? const MobileMenu() : pages[safeIndex]),
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
      floatingActionButton: safeIndex == 1 || safeIndex == 2
          ? FloatingActionButton.extended(
              onPressed: () {
                final page = safeIndex == 1
                    ? const InvoiceFormScreen()
                    : const QuotationFormScreen();

                if (isDesktop) {
                  _navigatorKeys[safeIndex].currentState?.push(
                    MaterialPageRoute(builder: (_) => page),
                  );
                } else {
                  Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => page));
                }
              },
              label: Text(
                safeIndex == 1 ? 'New Invoice' : 'New Quotation',
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.bolt,
                        color: Colors.white,
                        size: 28,
                      ),
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
                    _SidebarItem(
                      icon: Icons.local_shipping_outlined,
                      selectedIcon: Icons.local_shipping,
                      label: 'Delivery',
                      isSelected: selectedIndex == 7,
                      onTap: () => onItemSelected(7),
                    ),
                    _SidebarItem(
                      icon: Icons.description_outlined,
                      selectedIcon: Icons.description,
                      label: 'Letterhead',
                      isSelected: selectedIndex == 8,
                      onTap: () => onItemSelected(8),
                    ),
                    const Spacer(),
                    _SidebarItem(
                      icon: Icons.settings_outlined,
                      selectedIcon: Icons.settings,
                      label: 'Settings',
                      isSelected: selectedIndex == 9,
                      onTap: () => onItemSelected(9),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        },
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
