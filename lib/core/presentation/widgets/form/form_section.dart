import 'package:flutter/material.dart';

class FormSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const FormSection({
    super.key,
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          width: double.infinity,
          decoration: BoxDecoration(
            color:
                Theme.of(context).cardTheme.color ??
                Theme.of(context).colorScheme.surface,
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: 0.2),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 600;
              if (isDesktop) {
                return Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  children: children.map((child) {
                    return SizedBox(
                      width: (constraints.maxWidth - 20) / 2,
                      child: child,
                    );
                  }).toList(),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children.map((child) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: child,
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }
}
